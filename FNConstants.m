/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/


#import "FNConstants.h"

#pragma mark - General constants

NSString *const FNWebDomain = @"freenetproject.org";
NSString *const FNNodeInstallationPathname = @"Freenet";
NSString *const FNNodeRunscriptPathname = @"run.sh";
NSString *const FNNodeAnchorFilePathname = @"Freenet.anchor";
NSString *const FNNodeWrapperConfigFilePathname = @"wrapper.conf";
NSString *const FNNodeFreenetConfigFilePathname = @"freenet.ini";

NSTimeInterval const FNNodeCheckTimeInterval = 1;

NSString *const FNPastebinDomain = @"pastebin.com";

#pragma mark - Node configuration keys

NSString *const FNNodeFreenetConfigFCPBindAddressesKey = @"fcp.bindTo";
NSString *const FNNodeFreenetConfigFCPPortKey = @"fcp.port";
NSString *const FNNodeFreenetConfigFProxyBindAddressesKey = @"fproxy.bindTo";
NSString *const FNNodeFreenetConfigFProxyPortKey = @"fproxy.port";

NSString *const FNNodeFreenetConfigDownloadsDirKey = @"node.downloadsDir";

#pragma mark - NSUserDefaults keys

NSString *const FNStartAtLaunchKey = @"startatlaunch";

NSString *const FNNodeFProxyURLKey = @"nodeurl";
NSString *const FNNodeFCPURLKey = @"nodefcpurl";
NSString *const FNNodeInstallationDirectoryKey = @"nodepath";
NSString *const FNNodeFirstLaunchKey = @"firstlaunch";

#pragma mark - Custom NSNotifications

NSString *const FNNodeStateUnknownNotification = @"FNNodeStateUnknownNotification";
NSString *const FNNodeStateRunningNotification    = @"FNNodeStateRunningNotification";
NSString *const FNNodeStateNotRunningNotification = @"FNNodeStateNotRunningNotification";

NSString *const FNNodeHelloReceivedNotification = @"FNNodeHelloReceivedNotification";

NSString *const FNNodeStatsReceivedNotification = @"FNNodeStatsReceivedNotification";

NSString *const FNNodeFCPDisconnectedNotification = @"FNNodeFCPDisconnectedNotification";

NSString *const FNNodeConfiguredNotification = @"FNNodeConfiguredNotification";

NSString *const FNInstallFinishedNotification = @"FNInstallFinishedNotification";
NSString *const FNInstallFailedNotification = @"FNInstallFailedNotification";
NSString *const FNInstallStartNodeNotification = @"FNInstallStartNodeNotification";

#pragma mark - Global Actions

NSString *const FNNodeShowSettingsWindow = @"FNNodeShowSettingsWindow";
NSString *const FNNodeShowNodeFinderInSettingsWindow = @"FNNodeShowNodeFinderInSettingsWindow";
NSString *const FNNodeShowInstallerWindow = @"FNNodeShowInstallerWindow";
NSString *const FNNodeUninstall = @"FNNodeUninstall";

#pragma mark - Installer

NSString *const FNInstallDefaultLocation = @"~/Library/Application Support/Freenet";
NSInteger const FNInstallDefaultFProxyPort = 8888;
NSInteger const FNInstallDefaultFCPPort = 9481;



