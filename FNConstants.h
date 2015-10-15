/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the LICENSE file included with this code for details.
    
*/


@import Foundation;

#pragma mark - General constants

FOUNDATION_EXPORT NSString *const FNWebDomain;
FOUNDATION_EXPORT NSString *const FNNodeInstallationPathname;
FOUNDATION_EXPORT NSString *const FNNodeRunscriptPathname;
FOUNDATION_EXPORT NSString *const FNNodeAnchorFilePathname;
FOUNDATION_EXPORT NSString *const FNNodeWrapperConfigFilePathname;
FOUNDATION_EXPORT NSString *const FNNodeFreenetConfigFilePathname;

FOUNDATION_EXPORT NSTimeInterval const FNNodeCheckTimeInterval;

#pragma mark - Node configuration keys

FOUNDATION_EXPORT NSString *const FNNodeFreenetConfigFCPBindAddressesKey;
FOUNDATION_EXPORT NSString *const FNNodeFreenetConfigFCPPortKey;
FOUNDATION_EXPORT NSString *const FNNodeFreenetConfigFProxyBindAddressesKey;
FOUNDATION_EXPORT NSString *const FNNodeFreenetConfigFProxyPortKey;

FOUNDATION_EXPORT NSString *const FNNodeFreenetConfigDownloadsDirKey;

#pragma mark - NSUserDefaults keys

FOUNDATION_EXPORT NSString *const FNStartAtLaunchKey;

FOUNDATION_EXPORT NSString *const FNNodeFProxyURLKey;
FOUNDATION_EXPORT NSString *const FNNodeFCPURLKey;
FOUNDATION_EXPORT NSString *const FNNodeInstallationDirectoryKey;
FOUNDATION_EXPORT NSString *const FNNodeFirstLaunchKey;

#pragma mark - Custom NSNotifications

FOUNDATION_EXPORT NSString *const FNNodeStateUnknownNotification;
FOUNDATION_EXPORT NSString *const FNNodeStateRunningNotification;
FOUNDATION_EXPORT NSString *const FNNodeStateNotRunningNotification;

FOUNDATION_EXPORT NSString *const FNNodeHelloReceivedNotification;

FOUNDATION_EXPORT NSString *const FNNodeStatsReceivedNotification;

FOUNDATION_EXPORT NSString *const FNNodeFCPDisconnectedNotification;

#pragma mark - Global Actions

FOUNDATION_EXPORT NSString *const FNNodeShowSettingsWindow;
FOUNDATION_EXPORT NSString *const FNNodeShowNodeFinderInSettingsWindow;


#pragma mark - Node state

typedef NS_ENUM(NSInteger, FNNodeState) {
    FNNodeStateUnknown    = -1,
    FNNodeStateNotRunning =  0,
    FNNodeStateRunning    =  1
};