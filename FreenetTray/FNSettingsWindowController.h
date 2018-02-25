/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

@import Cocoa;

@class FNNodeController;

@interface FNSettingsWindowController : NSWindowController <NSOpenSavePanelDelegate, NSPathControlDelegate>

@property FNNodeController *nodeController;

@property (readonly) BOOL validNodeFound;
@property (getter=isLoginItem) BOOL loginItem;

@property IBOutlet NSImageView *nodeRunningStatusView;
@property IBOutlet NSImageView *webInterfaceStatusView;
@property IBOutlet NSImageView *fcpStatusView;

@property IBOutlet NSTextField *nodeBuildField;


@property IBOutlet NSPathControl *nodePathDisplay;

-(IBAction)uninstallFreenet:(id)sender;

-(IBAction)changeTrayIconColor:(id)sender;

@end
