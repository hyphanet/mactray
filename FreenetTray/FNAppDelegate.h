/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/


@import Cocoa;
@class FNNodeController;
@class FNDropdownMenuController;
@class FNSettingsWindowController;
@class FNInstallerWindowController;

@interface FNAppDelegate : NSObject <NSApplicationDelegate> {
    FNNodeController *nodeController;
    FNDropdownMenuController *dropdownMenuController;
    FNSettingsWindowController *settingsWindowController;
    FNInstallerWindowController *installerWindowController;
}
@end

