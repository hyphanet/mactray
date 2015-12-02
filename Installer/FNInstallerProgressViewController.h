/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

@import Cocoa;

@class NIKFontAwesomeImageView;

@interface FNInstallerProgressViewController : NSViewController

@property IBOutlet NSTextField *javaInstallationTitle;
@property IBOutlet NIKFontAwesomeImageView *javaInstallationStatus;

@property IBOutlet NSTextField *fileCopyTitle;
@property IBOutlet NIKFontAwesomeImageView *fileCopyStatus;

@property IBOutlet NSTextField *portsTitle;
@property IBOutlet NIKFontAwesomeImageView *portsStatus;

@property IBOutlet NSTextField *finishedTitle;
@property IBOutlet NIKFontAwesomeImageView *finishedStatus;

@property NSMutableAttributedString *installLog;
@property id<FNInstallerDelegate> stateDelegate;
-(void)installNodeAtFileURL:(NSURL *)installLocation;
@end
