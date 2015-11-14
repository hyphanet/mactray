/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>
    Copyright (C) 2013 Richard King <richy@wiredupandfiredup.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the LICENSE file included with this code for details.
    
*/

#import "FNDropdownMenuController.h"

#import "FNNodeController.h"

#import "TrayIcon.h"

@interface FNDropdownMenuController ()
-(void)setMenuBarImage:(NSImage *)image;
@end

@implementation FNDropdownMenuController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"FNDropdownMenu" owner:self topLevelObjects:nil];
    }
    return self;
}

-(void)awakeFromNib {

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    [self.statusItem setAlternateImage:[TrayIcon imageOfHighlightedIcon]];
        
    // menu loaded from FNDropdownMenu.xib
    self.statusItem.menu = self.dropdownMenu;

    self.statusItem.toolTip = NSLocalizedString(@"Freenet", @"Freenet Application Name");

    [self setMenuBarImage:[TrayIcon imageOfNotRunningIcon]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeStateRunning:) name:FNNodeStateRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeStateNotRunning:) name:FNNodeStateNotRunningNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNodeStats:) name:FNNodeStatsReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNodeHello:) name:FNNodeHelloReceivedNotification object:nil];
    
}




#pragma mark - Internal methods

-(void)setMenuBarImage:(NSImage *)image {
    [self.statusItem setImage:image];
}

#pragma mark - IBActions

-(IBAction)toggleNodeState:(id)sender {
    switch (self.nodeController.currentNodeState) {
        case FNNodeStateRunning: {
            [self.nodeController stopFreenet];
            break;
        }
        case FNNodeStateNotRunning: {
            [self.nodeController startFreenet];
            break;
        }
        case FNNodeStateUnknown: {
            
            break;
        }
        default: {
        
            break;
        }
    }
}

-(IBAction)openWebInterface:(id)sender {
    NSURL *fproxyLocation = self.nodeController.fproxyLocation;
    if (fproxyLocation) {
        // Open the fproxy page in users default browser
        [[NSWorkspace sharedWorkspace] openURL:fproxyLocation];
    }
}

-(IBAction)showAboutPanel:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

-(IBAction)showSettingsWindow:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:FNNodeShowSettingsWindow object:nil];

}

-(IBAction)showDownlodsFolder:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:self.nodeController.downloadsFolder.path];
}

#pragma mark - FNNodeStateProtocol methods

-(void)nodeStateRunning:(NSNotification*)notification {
    self.toggleNodeStateMenuItem.title = NSLocalizedString(@"Stop Freenet", @"Menu title for stopping freenet");
    [self setMenuBarImage:[TrayIcon imageOfRunningIcon]];

}

-(void)nodeStateNotRunning:(NSNotification*)notification {
    self.toggleNodeStateMenuItem.title = NSLocalizedString(@"Start Freenet", @"Menu title for starting freenet");
    [self setMenuBarImage:[TrayIcon imageOfNotRunningIcon]];

}

#pragma mark - FNNodeStatsProtocol methods

-(void)didReceiveNodeHello:(NSNotification*)notification {

}

-(void)didReceiveNodeStats:(NSNotification*)notification {
    //NSDictionary *nodeStats = notification.object;
}


@end
