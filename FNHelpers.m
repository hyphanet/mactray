/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNHelpers.h"
#import "FNBrowser.h"

@implementation FNHelpers

+(NSURL *)findNodeInstallation {
    NSURL *nodeURL = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *applicationsURL = [[fileManager URLsForDirectory:NSAllApplicationsDirectory inDomains:NSSystemDomainMask] firstObject];
    
    // existing or user-defined location
    NSString *customPath = [[[NSUserDefaults standardUserDefaults] objectForKey:FNNodeInstallationDirectoryKey] stringByStandardizingPath];
    NSURL *customInstallationURL;
    if (customPath != nil) {
        customInstallationURL = [NSURL fileURLWithPath:customPath];
    }
    // new default ~/Library/Application Support/Freenet
    NSURL *defaultInstallationURL = [applicationSupportURL URLByAppendingPathComponent:FNNodeInstallationPathname isDirectory:YES]; 
    
    // old default /Applications/Freenet
    NSURL *deprecatedInstallationURL = [applicationsURL URLByAppendingPathComponent:FNNodeInstallationPathname isDirectory:YES]; 
        
    if ([self validateNodeInstallationAtURL:customInstallationURL]) {
        nodeURL = customInstallationURL;
    }
    else if ([self validateNodeInstallationAtURL:defaultInstallationURL]) {
        nodeURL = defaultInstallationURL;
    }
    else if ([self validateNodeInstallationAtURL:deprecatedInstallationURL]) {
        nodeURL = deprecatedInstallationURL;
    }
    return nodeURL;
}

+(BOOL)validateNodeInstallationAtURL:(NSURL *)nodeURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *fileURL = [nodeURL URLByAppendingPathComponent:FNNodeRunscriptPathname];
    if ([fileManager fileExistsAtPath:fileURL.path isDirectory:nil]) {
        return YES;
    }
    return NO;
}

+(void)displayNodeMissingAlert {
    // no installation found, tell the user to pick a location or start the installer
    dispatch_async(dispatch_get_main_queue(), ^{        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"A Freenet installation could not be found.", @"String informing the user that no Freenet installation could be found");
        alert.informativeText = NSLocalizedString(@"Would you like to install Freenet now, or locate an existing Freenet installation?", @"String asking the user whether they would like to install freenet or locate an existing installation");
        [alert addButtonWithTitle:NSLocalizedString(@"Install Freenet", @"Install Freenet")];

        [alert addButtonWithTitle:NSLocalizedString(@"Find Installation", @"Find installation")];
        [alert addButtonWithTitle:NSLocalizedString(@"Quit", @"Quit")];
        
        NSInteger button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
            // display installer
            [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeShowInstallerWindow object:nil];
        }
        else if (button == NSAlertSecondButtonReturn) {
            // display node finder panel
            [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeShowNodeFinderInSettingsWindow object:nil];
        }
        else if (button == NSAlertThirdButtonReturn) {
            // display node finder panel
            [NSApp terminate:self];
        }
    }); 
}

+(void)displayUninstallAlert {
    // ask the user if they really do want to uninstall Freenet
    dispatch_async(dispatch_get_main_queue(), ^{        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"Uninstall Freenet", @"String title of Uninstall alert window");
        alert.informativeText = NSLocalizedString(@"Uninstalling Freenet is immediate and irreversible, are you sure you want to uninstall Freenet now?", @"String asking the user whether they would like to uninstall freenet");
        [alert addButtonWithTitle:NSLocalizedString(@"Uninstall Freenet", @"Uninstall Freenet button")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
        
        NSInteger button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
            // start uninstallation
            [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeUninstall object:nil];
        }
        else if (button == NSAlertSecondButtonReturn) {
            // user canceled, don't do anything
        }
    }); 
}

+(NSArray<FNBrowser *> *)installedWebBrowsers {
    NSURL *url = [NSURL URLWithString:@"https://"];
    LSRolesMask roles = kLSRolesViewer;
    CFArrayRef urls = LSCopyApplicationURLsForURL((__bridge CFURLRef)url, roles);
    NSArray *appUrls = CFBridgingRelease(urls);

    // Extract the app names and sort them for prettiness.
    NSMutableArray *appNames = [NSMutableArray arrayWithCapacity: appUrls.count];

    for (NSURL *url in appUrls) {
        FNBrowser *browser = [FNBrowser browserWithFileURL:url];
        [appNames addObject: browser];
    }
    //[appNames sortUsingSelector: @selector(compare:)];
    return appNames.copy;
}

@end
