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
    // no installation found, tell the user to pick a location
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *errorInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"A Freenet installation could not be found.", @"String informing the user that no Freenet installation could be found") };
    
            NSError *error = [NSError errorWithDomain:@"org.freenetproject" code:0x1000 userInfo:errorInfo];
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeShowNodeFinderInSettingsWindow object:nil];
        });
    });  
}

@end
