/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the LICENSE file included with this code for details.
    
*/

#import "FNHelpers.h"

@implementation FNHelpers

+(NSURL *)findNodeInstallation {
    NSURL *nodeURL = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *applicationsURL = [[fileManager URLsForDirectory:NSAllApplicationsDirectory inDomains:NSUserDomainMask] firstObject];
    
    // existing or user-defined location
    NSURL *customInstallationURL = [NSURL URLWithString:[[[NSUserDefaults standardUserDefaults] objectForKey:FNNodeInstallationDirectoryKey] stringByStandardizingPath]];
    
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
    // no installation found, tell the user to pick a location
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" 
                                            defaultButton:@"OK" 
                                            alternateButton:nil 
                                            otherButton:nil 
                                informativeTextWithFormat:@"A Freenet installation could not be found."];
            [alert runModal];  
        });
    });  
}

@end
