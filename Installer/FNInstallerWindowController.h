/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the LICENSE file included with this code for details.
    
*/


@import Cocoa;
@class FNNodeController;

@interface FNInstallerWindowController : NSWindowController <NSWindowDelegate, NSPageControllerDelegate, FNInstallerDelegate, FNInstallerDataSource>
@property IBOutlet NSButton *backButton;
@property IBOutlet NSButton *nextButton;

@property FNNodeController *nodeController;
@end
