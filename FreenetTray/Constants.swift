/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation

   // MARK: - General constants

let FNWebDomain = "freenetproject.org"
let FNNodeInstallationPathname = "Freenet"
let FNNodeRunscriptPathname = "run.sh"
let FNNodeAnchorFilePathname = "Freenet.anchor"
let FNNodePIDFilePathname = "Freenet.pid"
let FNNodeWrapperConfigFilePathname = "wrapper.conf"
let FNNodeFreenetConfigFilePathname = "freenet.ini"

let FNNodeCheckTimeInterval: TimeInterval = 1

let FNGithubAPI = "api.github.com"

    // MARK: - Deprecated functionality keys

let FNNodeLaunchAgentPathname = "com.freenet.startup.plist"

    // MARK: - Node configuration keys

let FNNodeFreenetConfigFCPBindAddressesKey = "fcp.bindTo"
let FNNodeFreenetConfigFCPPortKey = "fcp.port"
let FNNodeFreenetConfigFProxyBindAddressesKey = "fproxy.bindTo"
let FNNodeFreenetConfigFProxyPortKey = "fproxy.port"

let FNNodeFreenetConfigDownloadsDirKey = "node.downloadsDir"

    // MARK: - NSUserDefaults keys

let FNStartAtLaunchKey = "startatlaunch"

let FNNodeFProxyURLKey = "nodeurl"
let FNNodeFCPURLKey = "nodefcpurl"
let FNNodeInstallationDirectoryKey = "nodepath"
let FNNodeFirstLaunchKey = "firstlaunch"

let FNBrowserPreferenceKey = "FNBrowserPreferenceKey"

let FNEnableNotificationsKey = "FNEnableNotificationsKey"

    // MARK: - Custom NSNotifications

extension Notification.Name {
    
    static let FNNodeStateUnknownNotification = Notification.Name("FNNodeStateUnknownNotification")
    static let FNNodeStateRunningNotification = Notification.Name("FNNodeStateRunningNotification")
    static let FNNodeStateNotRunningNotification = Notification.Name("FNNodeStateNotRunningNotification")
    
    static let FNNodeHelloReceivedNotification = Notification.Name("FNNodeHelloReceivedNotification")
    
    static let FNNodeStatsReceivedNotification = Notification.Name("FNNodeStatsReceivedNotification")
    
    static let FNNodeFCPDisconnectedNotification = Notification.Name("FNNodeFCPDisconnectedNotification")
    
    static let FNNodeConfiguredNotification = Notification.Name("FNNodeConfiguredNotification")
    
    static let FNInstallFinishedNotification = Notification.Name("FNInstallFinishedNotification")
    static let FNInstallFailedNotification = Notification.Name("FNInstallFailedNotification")
    static let FNInstallStartNodeNotification = Notification.Name("FNInstallStartNodeNotification")
    
    // MARK: - Global Actions
    
    static let FNNodeShowSettingsWindow = Notification.Name("FNNodeShowSettingsWindow")
    static let FNNodeShowNodeFinderInSettingsWindow = Notification.Name("FNNodeShowNodeFinderInSettingsWindow")
    static let FNNodeShowInstallerWindow = Notification.Name("FNNodeShowInstallerWindow")
    static let FNNodeUninstall = Notification.Name("FNNodeUninstall")
}
    // MARK: - Installer

let FNInstallDefaultLocation = "~/Library/Application Support/Freenet"
let FNInstallDefaultFProxyPort: Int = 8888
let FNInstallDefaultFCPPort: Int = 9481

    // MARK: - Node state

enum FNNodeState: Int {
    case unknown = -1
    case notRunning = 0
    case running = 1
}

    // MARK: - Installer page

enum FNInstallerPage: Int {
    case unknown = -1
    case destination = 0
    case progress = 1
}

enum FNInstallerProgress: Int {
    case unknown
    case javaInstalling
    case javaFound
    case copyingFiles    
    case copiedFiles
    case setupPorts
    case startingNode
    case startedNode
    case finished
}

// MARK: - Blocks

typealias FNGistSuccessBlock = (URL) -> Void
typealias FNGistFailureBlock = (Error) -> Void
