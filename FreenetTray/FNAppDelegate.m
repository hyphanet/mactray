/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/


#import "FNAppDelegate.h"

#import "FNNodeController.h"
#import "FNDropdownMenuController.h"
#import "FNSettingsWindowController.h"

#import "NSBundle+LoginItem.h"

#import "FNHelpers.h"

#import "FNInstallerWindowController.h"

#import "PFMoveApplication.h"
#import <DCOAboutWindow/DCOAboutWindowController.h>
#import <TSMarkdownParser/TSMarkdownParser.h>

@interface FNAppDelegate ()
    
@end

@implementation FNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    PFMoveToApplicationsFolderIfNecessary();
    
    // migrations should go here if at all possible
    NSError *migrationError;
    if (![FNHelpers migrateLaunchAgent:&migrationError]) {
        NSLog(@"Error during migration: %@", migrationError.localizedDescription);
    }
    
    // load factory defaults for node location variables, sourced from defaults.plist
    NSString *defaultsPlist = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
    NSDictionary *defaultsPlistDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlist];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    [defaults registerDefaults:defaultsPlistDict];
    
     /* 
        Check for first launch key, if it isn't there this is first launch and 
        we need to setup autostart/loginitem
    */
    if([defaults boolForKey:FNNodeFirstLaunchKey]) {
        [defaults setBool:NO forKey:FNNodeFirstLaunchKey];
        [defaults synchronize];
        /* 
            Since this is the first launch, we add a login item for the user. If 
            they delete that login item it wont be added again.
        */
        [[NSBundle mainBundle] addToLoginItems];
    }
    
    DCOAboutWindowController *aboutWindow = [[DCOAboutWindowController alloc] init];


    NSURL *markdownURL = [[NSBundle mainBundle] URLForResource:@"Changelog.md" withExtension:nil];
    
    NSError *mdError = nil;
    
    NSString *markdown = [NSString stringWithContentsOfURL:markdownURL encoding:NSUTF8StringEncoding error:&mdError];
    
    if (!mdError) {
        aboutWindow.appCredits = [[TSMarkdownParser standardParser] attributedStringFromMarkdown:markdown];
    }
    
    
    aboutWindow.useTextViewForAcknowledgments = YES;
    NSString *websiteURLPath = [NSString stringWithFormat:@"https://%@", FNWebDomain];
    aboutWindow.appWebsiteURL = [NSURL URLWithString:websiteURLPath];
    [aboutWindow window];
    NSButton *visitWebsiteButton = [aboutWindow valueForKeyPath:@"self.visitWebsiteButton"];
    visitWebsiteButton.title = NSLocalizedString(@"Visit the Freenet Website", @"Button title");
    
    
    nodeController = [[FNNodeController alloc] init];

    dropdownMenuController = [[FNDropdownMenuController alloc] init];
    dropdownMenuController.nodeController = nodeController;
    dropdownMenuController.aboutWindow = aboutWindow;
    
    settingsWindowController = [[FNSettingsWindowController alloc] initWithWindowNibName:@"FNSettingsWindow"];
    settingsWindowController.nodeController = nodeController;
    [settingsWindowController window];
    
    installerWindowController = [[FNInstallerWindowController alloc] initWithWindowNibName:@"FNInstallerWindow"];
    installerWindowController.nodeController = nodeController;
    [installerWindowController window];
    
    NSURL *nodeURL = [FNHelpers findNodeInstallation];
    if (nodeURL) {
        NSString *nodePath = [nodeURL.path stringByStandardizingPath];
        [defaults setObject:nodePath forKey:FNNodeInstallationDirectoryKey];
        nodeController.nodeLocation = nodeURL;
        if ([defaults boolForKey:FNStartAtLaunchKey]) {
            [nodeController startFreenet];
        }
    }
    else {
        // no freenet installation found, ask the user what to do
        [FNHelpers displayNodeMissingAlert];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

@end
