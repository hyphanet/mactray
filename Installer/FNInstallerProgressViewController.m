/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNInstallerProgressViewController.h"

#import "FNHelpers.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#import <FontAwesomeIconFactory/FontAwesomeIconFactory.h>

@interface FNInstallerProgressViewController ()
@property (readonly) BOOL javaInstalled;
@property BOOL javaPromptShown;
@end

@implementation FNInstallerProgressViewController

- (void)awakeFromNib {
    [self updateProgress:FNInstallerProgressUnknown];
    self.installLog = [NSMutableAttributedString new];
    self.javaPromptShown = NO;
}

#pragma mark -
#pragma mark - Step 1: Entry point

-(void)installNodeAtFileURL:(NSURL *)installLocation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // wait until java is properly installed before continuing, but
        // don't repeatedly prompt the user to install it
        while (!self.javaInstalled) {
            if (!self.javaPromptShown) {
                self.javaPromptShown = YES;
                [self promptForJavaInstallation];
                [self updateProgress:FNInstallerProgressJavaInstalling];
            }
            [NSThread sleepForTimeInterval:1];
            continue;
        }
        // Java is now installed, continue installation
        [self updateProgress:FNInstallerProgressJavaFound]; 
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self copyNodeToFileURL:installLocation];
            [self setupNodeAtFileURL:installLocation];
        });
    });
}



#pragma mark -
#pragma mark - Step 2: Copy files

-(void)copyNodeToFileURL:(NSURL *)installLocation {
    [self appendToInstallLog:@"Starting installation"];
    NSURL *bundledNode = [[NSBundle mainBundle] URLForResource:@"Bundled Node" withExtension:nil];
    NSFileManager *fileManager = [[NSFileManager alloc] init];  
    if ([fileManager fileExistsAtPath:installLocation.path isDirectory:nil]) {
        [self appendToInstallLog:@"Removing existing files at: %@", installLocation.path];
        NSError *removeError;
        if (![fileManager removeItemAtURL:installLocation error:&removeError]) {
            [self appendToInstallLog:@"Error removing existing files %ld: %@", removeError.code, removeError.localizedDescription];
            [self.stateDelegate installerDidFailWithLog:self.installLog.string];
            return;
        }
    }
    [self appendToInstallLog:@"Copying files to %@", installLocation.path];
    NSError *copyError;
    if (![fileManager copyItemAtURL:bundledNode toURL:installLocation error:&copyError]) {
        [self appendToInstallLog:@"File copy error %ld: %@", copyError.code, copyError.localizedDescription];
        [self.stateDelegate installerDidFailWithLog:self.installLog.string];
        return;
    }
    [self appendToInstallLog:@"Copy finished"];
    [self updateProgress:FNInstallerProgressCopyFiles];
}

#pragma mark -
#pragma mark - Step 3: Set up node and find available ports

-(void)setupNodeAtFileURL:(NSURL *)installLocation {
    [self appendToInstallLog:@"Running setup script"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateProgress:FNInstallerProgressSetupPorts];
        
        NSPipe *pipe = [[NSPipe alloc] init];
        NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
        stdOutHandle.readabilityHandler = ^(NSFileHandle *fileHandle) {
            NSData *data = [fileHandle readDataToEndOfFile];
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self appendToInstallLog:str];
        };
        
        NSTask *scriptTask = [[NSTask alloc] init];
        scriptTask.currentDirectoryPath = installLocation.path;
        scriptTask.launchPath = [installLocation.path stringByAppendingPathComponent:@"bin/setup.sh"];
        scriptTask.standardOutput = pipe;
        
        NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:NSProcessInfo.processInfo.environment];        
        env[@"INSTALL_PATH"] = installLocation.path;
        env[@"LANG_SHORTCODE"] = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        [self appendToInstallLog:@"Checking for available ports"];
        [env addEntriesFromDictionary:self.availablePorts];
        scriptTask.environment = env;
        
        [scriptTask launch];
        [scriptTask waitUntilExit];
        
        NSInteger exitStatus = scriptTask.terminationStatus;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (exitStatus != 0) {
                [self.stateDelegate installerDidFailWithLog:self.installLog.string];
                return;
            }
            [self updateProgress:FNInstallerProgressFinished];
            [self appendToInstallLog:@"Installation finished"];
            [self.stateDelegate installerDidFinishAtLocation:installLocation];
            [self appendToInstallLog:@"Installer environment: %@", env.description];
            NSLog(@"Install log: %@", self.installLog.string);
        });
    });

}

#pragma mark -
#pragma mark - Java helpers

-(BOOL)javaInstalled {
    NSPipe *oraclePipe = [[NSPipe alloc] init];
    NSTask *oracleJRETask = [[NSTask alloc] init];
    
    oracleJRETask.launchPath = @"/usr/sbin/pkgutil";
    oracleJRETask.arguments = @[@"--pkgs=com.oracle.jre"];
    [oracleJRETask setStandardOutput:oraclePipe];
    
    [oracleJRETask launch];
    [oracleJRETask waitUntilExit];
    
    if (oracleJRETask.terminationStatus == 0) {
        return YES;
    }
    return NO;
}

-(void)promptForJavaInstallation {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *installJavaAlert = [[NSAlert alloc] init];
        
        installJavaAlert.messageText = NSLocalizedString(@"Java not found", @"String informing the user that Java was not found");
        installJavaAlert.informativeText = NSLocalizedString(@"Freenet requires Java, would you like to install it now?", @"String asking the user if they would like to install Java");
        
        [installJavaAlert addButtonWithTitle:NSLocalizedString(@"Install Java", @"Install Java button title")];
        [installJavaAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"Quit button title")];
        
        NSInteger button = [installJavaAlert runModal];
        
        if (button == NSAlertFirstButtonReturn) {
            [self installOracleJRE];
        }
        else if (button == NSAlertSecondButtonReturn) {
            [NSApp terminate:self];
        }
    });
}

-(void)installOracleJRE {
    NSString *oracleJREPath = [[NSBundle mainBundle] pathForResource:@"jre-8u66-macosx-x64" ofType:@"dmg"];
    [[NSWorkspace sharedWorkspace] openFile:oracleJREPath];
}

#pragma mark -
#pragma mark - Port test helpers

-(NSDictionary *)availablePorts {
    NSMutableDictionary *availablePorts = [NSMutableDictionary new];
    // fproxy ports
    for (NSInteger port = FNInstallDefaultFProxyPort; port < (port + 256); port++) {
        if ([self testListenPort:port]) {
            availablePorts[@"FPROXY_PORT"] = @(port);
            break;
        }
    }
    // fcp ports
    for (NSInteger port = FNInstallDefaultFCPPort; port < (port + 256); port++) {
        if ([self testListenPort:port]) {
            availablePorts[@"FCP_PORT"] = @(port);
            break;
        }
    }
    return availablePorts;
}

-(BOOL)testListenPort:(NSInteger)port {
    GCDAsyncSocket *listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];

    NSError *error;
    if (![listenSocket acceptOnInterface:@"localhost" port:port error:&error]) {
        [self appendToInstallLog:@"Port %ld unavailable: %@", (long)port, error.localizedDescription];
        [listenSocket disconnect];
        return NO;
    }
    [self appendToInstallLog:@"Port %ld available", port];
    [listenSocket disconnect];
    return YES;
}

#pragma mark -
#pragma mark - Logging

-(void)appendToInstallLog:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *st = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSMutableAttributedString* attr = [[NSMutableAttributedString alloc] initWithString:st];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [self.installLog appendAttributedString:attr];
}

#pragma mark -
#pragma mark - Internal state

-(void)updateProgress:(enum FNInstallerProgress)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (progress) {
            case FNInstallerProgressUnknown:
                break;
            case FNInstallerProgressJavaInstalling:
                self.javaInstallationStatus.icon = NIKFontAwesomeIconClockO;
                self.javaInstallationStatus.hidden = NO;
                self.javaInstallationTitle.hidden = NO;
                break;
            case FNInstallerProgressJavaFound:
                self.javaInstallationStatus.icon = NIKFontAwesomeIconCheckCircle;
                self.javaInstallationStatus.hidden = NO;
                self.javaInstallationTitle.hidden = NO;
                break;
            case FNInstallerProgressCopyFiles:
                self.fileCopyStatus.icon = NIKFontAwesomeIconCheckCircle;
                self.fileCopyStatus.hidden = NO;
                self.fileCopyTitle.hidden = NO;
                break;
            case FNInstallerProgressSetupPorts:
                self.portsStatus.icon = NIKFontAwesomeIconCheckCircle;
                self.portsStatus.hidden = NO;
                self.portsTitle.hidden = NO;
                break;
            case FNInstallerProgressFinished:
                self.finishedStatus.icon = NIKFontAwesomeIconCheckCircle;
                self.finishedStatus.hidden = NO;
                self.finishedTitle.hidden = NO;
                break;
            default:
                break;
        }
    });
}

@end
