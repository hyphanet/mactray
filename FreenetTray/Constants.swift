/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation

   // MARK: - General constants

let FNWebDomain: String = "freenetproject.org"
let FNNodeInstallationPathname: String = "Freenet"
let FNNodeRunscriptPathname: String = "run.sh"
let FNNodeAnchorFilePathname: String = "Freenet.anchor"
let FNNodePIDFilePathname: String = "Freenet.pid"
let FNNodeWrapperConfigFilePathname: String = "wrapper.conf"
let FNNodeFreenetConfigFilePathname: String = "freenet.ini"

let FNNodeCheckTimeInterval: NSTimeInterval = 1

let FNGithubAPI: String = "api.github.com"

    // MARK: - Deprecated functionality keys

let FNNodeLaunchAgentPathname: String = "com.freenet.startup.plist"

    // MARK: - Node configuration keys

let FNNodeFreenetConfigFCPBindAddressesKey: String = "fcp.bindTo"
let FNNodeFreenetConfigFCPPortKey: String = "fcp.port"
let FNNodeFreenetConfigFProxyBindAddressesKey: String = "fproxy.bindTo"
let FNNodeFreenetConfigFProxyPortKey: String = "fproxy.port"

let FNNodeFreenetConfigDownloadsDirKey: String = "node.downloadsDir"

    // MARK: - NSUserDefaults keys

let FNStartAtLaunchKey: String = "startatlaunch"

let FNNodeFProxyURLKey: String = "nodeurl"
let FNNodeFCPURLKey: String = "nodefcpurl"
let FNNodeInstallationDirectoryKey: String = "nodepath"
let FNNodeFirstLaunchKey: String = "firstlaunch"

let FNBrowserPreferenceKey: String = "FNBrowserPreferenceKey"

let FNEnableNotificationsKey: String = "FNEnableNotificationsKey"

    // MARK: - Custom NSNotifications

let FNNodeStateUnknownNotification: String = "FNNodeStateUnknownNotification"
let FNNodeStateRunningNotification: String = "FNNodeStateRunningNotification"
let FNNodeStateNotRunningNotification: String = "FNNodeStateNotRunningNotification"

let FNNodeHelloReceivedNotification: String = "FNNodeHelloReceivedNotification"

let FNNodeStatsReceivedNotification: String = "FNNodeStatsReceivedNotification"

let FNNodeFCPDisconnectedNotification: String = "FNNodeFCPDisconnectedNotification"

let FNNodeConfiguredNotification: String = "FNNodeConfiguredNotification"

let FNInstallFinishedNotification: String = "FNInstallFinishedNotification"
let FNInstallFailedNotification: String = "FNInstallFailedNotification"
let FNInstallStartNodeNotification: String = "FNInstallStartNodeNotification"

    // MARK: - Global Actions

let FNNodeShowSettingsWindow: String = "FNNodeShowSettingsWindow"
let FNNodeShowNodeFinderInSettingsWindow: String = "FNNodeShowNodeFinderInSettingsWindow"
let FNNodeShowInstallerWindow: String = "FNNodeShowInstallerWindow"
let FNNodeUninstall: String = "FNNodeUninstall"

    // MARK: - Installer

let FNInstallDefaultLocation: String = "~/Library/Application Support/Freenet"
let FNInstallDefaultFProxyPort: Int = 8888
let FNInstallDefaultFCPPort: Int = 9481

    // MARK: - Node state

enum FNNodeState: Int {
    case Unknown = -1
    case NotRunning = 0
    case Running = 1
}

    // MARK: - Installer page

enum FNInstallerPage: Int {
    case Unknown = -1
    case Destination = 0
    case Progress = 1
}

enum FNInstallerProgress: Int {
    case Unknown
    case JavaInstalling
    case JavaFound
    case CopyingFiles    
    case CopiedFiles
    case SetupPorts
    case StartingNode
    case StartedNode
    case Finished
}

// MARK: - Blocks

typealias FNGistSuccessBlock = (NSURL!) -> Void
typealias FNGistFailureBlock = (NSError!) -> Void