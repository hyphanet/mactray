/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

@import Cocoa;

@interface FNInstallerDestinationViewController : NSViewController <NSOpenSavePanelDelegate>
@property IBOutlet NSTextView *textView;
@property id<FNInstallerDelegate> stateDelegate;
@property IBOutlet NSPathControl *installPathIndicator;

-(IBAction)selectInstallLocation:(id)sender;

@end
