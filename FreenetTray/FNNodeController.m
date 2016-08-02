/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>
    Copyright (C) 2013 Richard King <richy@wiredupandfiredup.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNNodeController.h"

#import "FNFCPWrapper.h"

#import "FNHelpers.h"

#import "FNConfigParser.h"

#import "MHWDirectoryWatcher.h"

@interface FNNodeController()
@property FNFCPWrapper *fcpWrapper;
@property MHWDirectoryWatcher *configWatcher;
@end

@implementation FNNodeController
@dynamic nodeLocation;
 
- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentNodeState = FNNodeStateUnknown;
        self.fcpWrapper = [[FNFCPWrapper alloc] init];
        self.fcpWrapper.delegate = self;
        self.fcpWrapper.dataSource = self;
        [self.fcpWrapper nodeStateLoop];
        // spawn a thread to monitor node installation. The method called here cannot be run again while this thread is running
        [NSThread detachNewThreadSelector:@selector(checkNodeInstallation) toTarget:self withObject:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installFinished:) name:FNInstallFinishedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installFailed:) name:FNInstallFailedNotification object:nil];        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installStartNode:) name:FNInstallStartNodeNotification object:nil];
                
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uninstallFreenet:) name:FNNodeUninstall object:nil]; 
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    }
    return self;
}

#pragma mark - Uninstaller

-(void)uninstallFreenet:(NSNotification *)notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (![FNHelpers validateNodeInstallationAtURL:self.nodeLocation]) {
            // warn user that the configured node path is not valid and refuse to delete anything
            dispatch_async(dispatch_get_main_queue(), ^{        
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = NSLocalizedString(@"Uninstalling Freenet failed", @"Title of window");
                alert.informativeText = NSLocalizedString(@"No Freenet installation was found, please delete the files manually if needed", @"String informing the user that no Freenet installation was found and that they must delete the files manually if needed");
                [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
                NSInteger button = [alert runModal];
                if (button == NSAlertFirstButtonReturn) {
                    [[NSWorkspace sharedWorkspace] openURL:[[NSBundle mainBundle] bundleURL]];
                    [NSApp terminate:self];
                }
            });
            return;
        }
        
        while (self.currentNodeState == FNNodeStateRunning) {
            [self stopFreenet];
            [NSThread sleepForTimeInterval:1];
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *nodeRemovalError;
        if (![fileManager removeItemAtURL:self.nodeLocation error:&nodeRemovalError]) {
            NSLog(@"Uninstall error: %@", nodeRemovalError);
            // warn user that uninstall did not go smoothly
            dispatch_async(dispatch_get_main_queue(), ^{        
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = NSLocalizedString(@"Uninstalling Freenet failed", @"Title of window");
                alert.informativeText = nodeRemovalError.localizedDescription;
                [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
                
                NSInteger button = [alert runModal];
                if (button == NSAlertFirstButtonReturn) {
                    [[NSWorkspace sharedWorkspace] openURL:self.nodeLocation];
                    [NSApp terminate:self];
                }
            });
            return;
        }
        NSError *appRemovalError;
        if (![fileManager removeItemAtURL:[[NSBundle mainBundle] bundleURL] error:&appRemovalError]) {
            NSLog(@"App uninstall error: %@", appRemovalError);
            // warn user that uninstall did not go smoothly
            dispatch_async(dispatch_get_main_queue(), ^{        
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = NSLocalizedString(@"Uninstalling Freenet failed", @"Title of window");
                alert.informativeText = appRemovalError.localizedDescription;
                [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
                NSInteger button = [alert runModal];
                if (button == NSAlertFirstButtonReturn) {
                    [[NSWorkspace sharedWorkspace] openURL:[[NSBundle mainBundle] bundleURL]];
                    [NSApp terminate:self];
                }
            });
            return;
        }
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];

        dispatch_async(dispatch_get_main_queue(), ^{        
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = NSLocalizedString(@"Freenet Uninstalled", @"Title of window");
            alert.informativeText = NSLocalizedString(@"Freenet has been completely uninstalled", @"String informing the user that Freenet uninstallation succeeded");
            [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
            NSInteger button = [alert runModal];
            if (button == NSAlertFirstButtonReturn) {
                [NSApp terminate:self];
            }
        });    
    });
}

#pragma mark - Install delegate

-(void)installFinished:(NSNotification *)notification {

}

-(void)installFailed:(NSNotification *)notification {
    self.nodeLocation = nil;
}

-(void)installStartNode:(NSNotification *)notification {
    NSURL *newInstallation = notification.object;
    self.nodeLocation = newInstallation;
    [self startFreenet];
}

#pragma mark - Dynamic properties

-(NSURL *)nodeLocation {
    NSString *storedNodePath = [[[NSUserDefaults standardUserDefaults] objectForKey:FNNodeInstallationDirectoryKey] stringByStandardizingPath];
    NSURL *storedInstallationURL = nil;
    if (storedNodePath != nil) {
        storedInstallationURL = [NSURL fileURLWithPath:storedNodePath];
    }
    return storedInstallationURL;
}

-(void)setNodeLocation:(NSURL *)nodeLocation {
    [self.configWatcher stopWatching];
    
    NSString *nodePath = [nodeLocation.path stringByStandardizingPath];
    if (nodePath != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:nodePath forKey:FNNodeInstallationDirectoryKey];
        self.configWatcher = [MHWDirectoryWatcher directoryWatcherAtPath:nodePath callback:^{
            [self readFreenetConfig];
        }];
        [self.configWatcher startWatching];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:FNNodeInstallationDirectoryKey];
    }
    [self readFreenetConfig];
}

#pragma mark - Node handling
- (void)checkNodeInstallation {
    // start a continuous loop to monitor installation directory
    while (1) {
        @autoreleasepool {
            if (![FNHelpers validateNodeInstallationAtURL:self.nodeLocation]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.currentNodeState = FNNodeStateUnknown;
                    [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeStateUnknownNotification object:nil];
                });
            }
        }
        [NSThread sleepForTimeInterval:FNNodeCheckTimeInterval]; 
    }
}

- (void)startFreenet {
    NSURL *nodeLocation = self.nodeLocation;
    if ([FNHelpers validateNodeInstallationAtURL:nodeLocation]) {
        NSURL *runScript = [nodeLocation URLByAppendingPathComponent:FNNodeRunscriptPathname];
        [NSTask launchedTaskWithLaunchPath:runScript.path arguments:@[@"start"]];       
    }
    else {
        [FNHelpers displayNodeMissingAlert];
    }
}

- (void)stopFreenet {
    NSURL *nodeLocation = self.nodeLocation;
    if ([FNHelpers validateNodeInstallationAtURL:nodeLocation]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *runScript = [nodeLocation URLByAppendingPathComponent:FNNodeRunscriptPathname];
            NSTask *task = [NSTask launchedTaskWithLaunchPath:runScript.path arguments:@[@"stop"]];
            [task waitUntilExit];
            // once run.sh returns, we ensure the wrapper state is cleaned up
            // this fixes issues where Freenet.anchor is still around but the wrapper crashed, so the node
            // isn't actually running but the tray app thinks it is, preventing users from using start/stop
            // in the dropdown menu until things go back to a sane state
            [self cleanupAfterShutdown:nodeLocation];
        });
    }
    else {
        [FNHelpers displayNodeMissingAlert];
    }
}

#pragma mark - Shutdown cleanup

-(void)cleanupAfterShutdown:(NSURL *)nodeLocation {
    NSURL *anchorFile = [nodeLocation URLByAppendingPathComponent:FNNodeAnchorFilePathname];
    [[NSFileManager defaultManager] removeItemAtURL:anchorFile error:nil];
     
    NSURL *pidFile = [nodeLocation URLByAppendingPathComponent:FNNodePIDFilePathname];
    [[NSFileManager defaultManager] removeItemAtURL:pidFile error:nil];
}

#pragma mark - Configuration handlers

-(void)readFreenetConfig {
    if ([FNHelpers validateNodeInstallationAtURL:self.nodeLocation]) {
        NSURL *wrapperConfigFile = [self.nodeLocation URLByAppendingPathComponent:FNNodeWrapperConfigFilePathname];
        self.wrapperConfig = [FNConfigParser dictionaryFromConfigFile:wrapperConfigFile];
        
        NSURL *freenetConfigFile = [self.nodeLocation URLByAppendingPathComponent:FNNodeFreenetConfigFilePathname];    
        self.freenetConfig = [FNConfigParser dictionaryFromConfigFile:freenetConfigFile];
        
        NSArray *fcpBindings = [self.freenetConfig[FNNodeFreenetConfigFCPBindAddressesKey] componentsSeparatedByString:@","];
        if (fcpBindings.count > 0) {
            NSString *fcpBindTo = fcpBindings[0]; // first one should be ipv4
            NSString *fcpPort = self.freenetConfig[FNNodeFreenetConfigFCPPortKey];
            self.fcpLocation = [NSURL URLWithString:[NSString stringWithFormat:@"tcp://%@:%@", fcpBindTo, fcpPort]];
        }
        
        NSArray *fproxyBindings = [self.freenetConfig[FNNodeFreenetConfigFProxyBindAddressesKey] componentsSeparatedByString:@","];
        if (fproxyBindings.count > 0) {
            NSString *fproxyBindTo = fproxyBindings[0]; // first one should be ipv4
            NSString *fproxyPort = self.freenetConfig[FNNodeFreenetConfigFProxyPortKey];
            self.fproxyLocation = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@", fproxyBindTo, fproxyPort]];
            [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeConfiguredNotification object:nil];
        }
        
        BOOL isDirectory;
        NSString *downloadsPath = self.freenetConfig[FNNodeFreenetConfigDownloadsDirKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadsPath isDirectory:&isDirectory] && isDirectory) {
            self.downloadsFolder = [NSURL fileURLWithPath:downloadsPath isDirectory:YES];
        }
        else if (downloadsPath != nil) {
            // node.downloadsDir isn't a full path, so probably relative to the node files
            self.downloadsFolder = [self.nodeLocation URLByAppendingPathComponent:downloadsPath isDirectory:YES];
        }
        else {
            // last resort, freenet.ini doesn't have a node.downloadsDir key, use a sane temporary default
            self.downloadsFolder = [self.nodeLocation URLByAppendingPathComponent:@"downloads" isDirectory:YES];
        }
    }
}

#pragma mark - FNFCPWrapperDelegate methods

-(void)didDisconnect {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentNodeState = FNNodeStateNotRunning;
        [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeStateNotRunningNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeFCPDisconnectedNotification object:nil];
    });

}

-(void)didReceiveNodeHello:(NSDictionary *)nodeHello {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeHelloReceivedNotification object:nodeHello];
    });
}

-(void)didReceiveNodeStats:(NSDictionary *)nodeStats {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentNodeState = FNNodeStateRunning;
        [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeStateRunningNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeStatsReceivedNotification object:nodeStats];
    });
}

-(void)didReceiveUserAlert:(NSDictionary *)nodeUserAlert {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:FNEnableNotificationsKey]) {
        return;
    }
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    
    NSString *command = nodeUserAlert[@"Command"];
    // N2N messages are handled differently, we want to grab the substring of the response that contains the
    // actual message since display space is limited in the notification popups
    if ([command isEqualToString:@"TextFeed"]) {
        notification.title = nodeUserAlert[@"ShortText"];
        NSInteger textLength = [nodeUserAlert[@"TextLength"] integerValue];
        NSInteger messageLength = [nodeUserAlert[@"MessageTextLength"] integerValue];
        NSString *message = [nodeUserAlert[@"Data"] substringWithRange:NSMakeRange(textLength - messageLength - 1, messageLength +1)];
        notification.informativeText = message;
    }
    else {
        notification.title = nodeUserAlert[@"Header"];
        notification.informativeText = nodeUserAlert[@"Data"];
    }
    notification.soundName = NSUserNotificationDefaultSoundName;

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

#pragma mark - FNFCPWrapperDataSource methods

-(NSURL *)nodeFCPURL {
    return self.fcpLocation;
}

#pragma mark - NSUserNotificationCenterDelegate methods

-(BOOL) userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSURL *fproxyLocation = self.fproxyLocation;
    if (fproxyLocation) {
        // Open the alerts page in users default browser
        NSURL *alertsPage = [fproxyLocation URLByAppendingPathComponent:@"alerts"];
        [[NSWorkspace sharedWorkspace] openURL:alertsPage];
    }
    [center removeAllDeliveredNotifications];
}

@end
