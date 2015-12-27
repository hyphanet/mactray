/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

typedef void (^FNGistSuccessBlock)(NSURL *url);
typedef void (^FNGistFailureBlock)(NSError *error);

@import Foundation;
@class FNBrowser;


@interface FNHelpers : NSObject

+(NSURL *)findNodeInstallation;
+(BOOL)validateNodeInstallationAtURL:(NSURL *)nodeURL;
+(void)displayNodeMissingAlert;
+(void)displayUninstallAlert;
+(NSArray<FNBrowser *> *)installedWebBrowsers;

+(BOOL)migrateLaunchAgent:(NSError **)error;

+(void)createGist:(NSString *)string withTitle:(NSString *)title success:(FNGistSuccessBlock)success failure:(FNGistFailureBlock)failure;

@end
