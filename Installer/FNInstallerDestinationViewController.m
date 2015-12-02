/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the LICENSE file included with this code for details.
    
*/

#import "FNInstallerDestinationViewController.h"
#import "FNHelpers.h"

@interface NSFileManager (EmptyDirectoryAtURL)
- (BOOL)isEmptyDirectoryAtURL:(NSURL*)url;
@end

@implementation NSFileManager (EmptyDirectoryAtURL)

- (BOOL)isEmptyDirectoryAtURL:(NSURL*)url {
  return ([[self contentsOfDirectoryAtURL:url includingPropertiesForKeys:nil options:0 error:NULL] count] <= 1);
}

@end

@interface FNInstallerDestinationViewController ()

@end

@implementation FNInstallerDestinationViewController

- (void)awakeFromNib {
    self.installPathIndicator.URL = [NSURL fileURLWithPath:[FNInstallDefaultLocation stringByStandardizingPath]];
}

#pragma mark - Interface actions

-(IBAction)selectInstallLocation:(id)sender {

    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setDelegate:self];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    NSString *panelTitle = NSLocalizedString(@"Select a location to install Freenet", @"Title for the install destination window");
    [panel setTitle:panelTitle];
 
    NSString *promptString = NSLocalizedString(@"Install here", @"Button title");
    [panel setPrompt:promptString];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            self.installPathIndicator.URL = panel.URL;
            [self.stateDelegate userDidSelectInstallLocation:panel.URL];
        }
    }];
}

#pragma mark - NSOpenPanelDelegate

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    BOOL existingInstallation = [FNHelpers validateNodeInstallationAtURL:url];
    if (existingInstallation) {
        NSDictionary *errorInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Freenet is already installed here", @"String informing the user that the selected location is an existing Freenet installation") };
    
        if (outError != NULL) *outError = [NSError errorWithDomain:@"org.freenetproject" code:0x1000 userInfo:errorInfo];
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // check if the candidate installation path is actually writable
    if (![fileManager isWritableFileAtPath:url.path]) {
        NSDictionary *errorInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot install to this directory, write permission denied", @"String informing the user that they do not have permission to write to the selected directory") };
    
        if (outError != NULL) *outError = [NSError errorWithDomain:@"org.freenetproject" code:0x1001 userInfo:errorInfo];
        return NO;
    }  
    
    // make sure the directory is empty, protects against users accidentally picking their home folder etc
    if (![fileManager isEmptyDirectoryAtURL:url]) {
        NSDictionary *errorInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Directory is not empty", @"String informing the user that the selected directory is not empty") };
    
        if (outError != NULL) *outError = [NSError errorWithDomain:@"org.freenetproject" code:0x1002 userInfo:errorInfo];
        return NO;
    }
    return YES;
}

@end
