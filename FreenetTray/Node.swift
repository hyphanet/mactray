/*
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
}


class Node: NSObject, FCPDelegate, FCPDataSource, NSUserNotificationCenterDelegate {

    var state: FNNodeState = .unknown
    
    var wrapperConfig: [String: String]?
    
    var freenetConfig: [String: String]?
    
    var fcpLocation: URL?
    
    var fproxyLocation: URL?
    
    var downloadsFolder: URL?
    
    fileprivate var fcp = FCP()
    
    fileprivate var configWatcher: MHWDirectoryWatcher!

    override init() {
        super.init()
        self.fcp.delegate = self
        self.fcp.dataSource = self
        self.fcp.nodeStateLoop()
        // spawn a thread to monitor node installation. The method called here cannot be run again while this thread is running
        Thread.detachNewThreadSelector(#selector(checkNodeInstallation), toTarget:self, with:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(installFinished), name: Notification.Name.FNInstallFinishedNotification, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(installFailed), name: Notification.Name.FNInstallFailedNotification, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(installStartNode), name: Notification.Name.FNInstallStartNodeNotification, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(uninstallFreenet), name: Notification.Name.FNNodeUninstall, object:nil)
        
        NSUserNotificationCenter.default.delegate = self

    }

    // MARK: - Uninstaller

    func uninstallFreenet(_ notification:Notification!) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { 

            if !Helpers.validateNodeInstallationAtURL(self.location) {
                // warn user that the configured node path is not valid and refuse to delete anything
                DispatchQueue.main.async(execute: {         
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Uninstalling Freenet failed", comment: "Title of window")
                    alert.informativeText = NSLocalizedString("No Freenet installation was found, please delete the files manually if needed", comment: "String informing the user that no Freenet installation was found and that they must delete the files manually if needed")
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))
                    let button = alert.runModal()
                    if button == NSAlertFirstButtonReturn {
                        NSWorkspace.shared().open(Bundle.main.bundleURL)
                        NSApp.terminate(self)
                    }
                })
                return
            }

            while self.state == .running {
                self.stopFreenet()
                Thread.sleep(forTimeInterval: 1)
            }
            
            
            let fileManager = FileManager.default

            do {
                if let nodeLocation = self.location {
                    try fileManager.removeItem(at: nodeLocation)
                }
                else {
                    throw NSError(domain: "org.freenetproject", code: 0x01, userInfo: nil)
                }
            }
            catch let nodeRemovalError as NSError {
                NSLog("Uninstall error: \(nodeRemovalError)")
                // warn user that uninstall did not go smoothly
                DispatchQueue.main.async(execute: {         
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Uninstalling Freenet failed", comment: "Title of window")
                    alert.informativeText = nodeRemovalError.localizedDescription
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))

                    let button = alert.runModal()
                    if button == NSAlertFirstButtonReturn {
                        if let nodeLocation = self.location {
                            NSWorkspace.shared().open(nodeLocation)
                        }
                        NSApp.terminate(self)
                    }
                })
                return
            }

            do {
                try fileManager.removeItem(at: Bundle.main.bundleURL)
            }
            catch let appRemovalError as NSError {
                NSLog("App uninstall error: \(appRemovalError)")
                // warn user that uninstall did not go smoothly
                DispatchQueue.main.async(execute: {         
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Uninstalling Freenet failed", comment: "Title of window")
                    alert.informativeText = appRemovalError.localizedDescription
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))
                    let button = alert.runModal()
                    if button == NSAlertFirstButtonReturn {
                        NSWorkspace.shared().open(Bundle.main.bundleURL)
                        NSApp.terminate(self)
                    }
                })
                return
            }
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()

            DispatchQueue.main.async(execute: {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Freenet Uninstalled", comment: "Title of window")
                alert.informativeText = NSLocalizedString("Freenet has been completely uninstalled", comment: "String informing the user that Freenet uninstallation succeeded")
                alert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))
                let button = alert.runModal()
                if button == NSAlertFirstButtonReturn {
                    NSApp.terminate(self)
                }
            })    
        })
    }

    // MARK: - Install delegate

    func installFinished(_ notification:Notification!) {

    }

    func installFailed(_ notification:Notification!) {
        self.location = nil
    }

    func installStartNode(_ notification:Notification!) {
        if let newInstallation = notification.object as? URL {
            self.location = newInstallation
            self.startFreenet()
        }
    }

    // MARK: - Dynamic properties

    var location: URL? {
        get {
            if let storedNodePath = UserDefaults.standard.object(forKey: FNNodeInstallationDirectoryKey) as? String {
                return URL(fileURLWithPath: storedNodePath).standardizedFileURL
            }
            return nil
        }
        set(newNodeLocation) {
            if let configWatcher = self.configWatcher {
                configWatcher.stopWatching()
            }
            
            if let nodePath = newNodeLocation?.standardizedFileURL.path {
                UserDefaults.standard.set(nodePath, forKey:FNNodeInstallationDirectoryKey)
                self.configWatcher = MHWDirectoryWatcher(atPath: nodePath, callback: {
                    self.readFreenetConfig()
                })
                self.configWatcher.startWatching()
            }
            else {
                UserDefaults.standard.removeObject(forKey: FNNodeInstallationDirectoryKey)
            }
            self.readFreenetConfig()
        }
    }
    
    // MARK: - Node handling
    func checkNodeInstallation() {
        // start a continuous loop to monitor installation directory
        while true {
            autoreleasepool { 
                if !Helpers.validateNodeInstallationAtURL(self.location) {
                    DispatchQueue.main.async(execute: { 
                        self.state = .unknown
                        NotificationCenter.default.post(name: Notification.Name.FNNodeStateUnknownNotification, object: nil)
                    })
                }
            }
            Thread.sleep(forTimeInterval: FNNodeCheckTimeInterval) 
        }
    }

    func startFreenet() {
        let nodeLocation = self.location
        if Helpers.validateNodeInstallationAtURL(nodeLocation) {
            let runScript = nodeLocation!.appendingPathComponent(FNNodeRunscriptPathname)
            Process.launchedProcess(launchPath: runScript.path, arguments:["start"])
        }
        else {
            Helpers.displayNodeMissingAlert()
        }
    }

    func stopFreenet() {
        let nodeLocation = self.location
        if Helpers.validateNodeInstallationAtURL(nodeLocation) {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { 
                let runScript:URL! = nodeLocation!.appendingPathComponent(FNNodeRunscriptPathname)
                let task:Process! = Process.launchedProcess(launchPath: runScript.path, arguments: ["stop"])
                task.waitUntilExit()
                // once run.sh returns, we ensure the wrapper state is cleaned up
                // this fixes issues where Freenet.anchor is still around but the wrapper crashed, so the node
                // isn't actually running but the tray app thinks it is, preventing users from using start/stop
                // in the dropdown menu until things go back to a sane state
                self.cleanupAfterShutdown(nodeLocation)
            })
        }
        else {
            Helpers.displayNodeMissingAlert()
        }
    }

    // MARK: - Shutdown cleanup

    func cleanupAfterShutdown(_ nodeLocation:URL!) {
        // these are best effort cleanup attempts, we don't care if they fail or why
        let anchorFile = nodeLocation.appendingPathComponent(FNNodeAnchorFilePathname)
        do {
            try FileManager.default.removeItem(at: anchorFile)
        }
        catch {
        
        }

        let pidFile = nodeLocation.appendingPathComponent(FNNodePIDFilePathname)
        do {
            try FileManager.default.removeItem(at: pidFile)
        }
        catch {
        
        }
    }

    // MARK: - Configuration handlers

    func readFreenetConfig() {
        guard let nodeLocation = self.location else {
            return
        }
        if Helpers.validateNodeInstallationAtURL(self.location) {
            let wrapperConfigFile = nodeLocation.appendingPathComponent(FNNodeWrapperConfigFilePathname)
            let freenetConfigFile = nodeLocation.appendingPathComponent(FNNodeFreenetConfigFilePathname)

            self.wrapperConfig = NodeConfig.fromFile(wrapperConfigFile)

            guard let freenetConfig = NodeConfig.fromFile(freenetConfigFile),
                      let fcpBindings = freenetConfig[FNNodeFreenetConfigFCPBindAddressesKey]?.components(separatedBy: ","),
                      let fproxyBindings = freenetConfig[FNNodeFreenetConfigFProxyBindAddressesKey]?.components(separatedBy: ","),
                      let downloadsPath = freenetConfig[FNNodeFreenetConfigDownloadsDirKey] else {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Freenet configuration invalid", comment: "Title of window")
                alert.informativeText = NSLocalizedString("Your Freenet installation does not have a freenet.ini file", comment: "String informing the user that Freenet configuration is invalid")
                alert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))
                let button = alert.runModal()
                if button == NSAlertFirstButtonReturn {
                    NSApp.terminate(self)
                }
                return
            }
            
            self.freenetConfig = freenetConfig
            
            if fcpBindings.count > 0 {
                 // first one should be ipv4
                let fcpBindTo = fcpBindings[0]
                
                if let fcpPort = freenetConfig[FNNodeFreenetConfigFCPPortKey] {
                    self.fcpLocation = URL(string: "tcp://\(fcpBindTo):\(fcpPort)")

                }
            }
            
            if fproxyBindings.count > 0 {
                let fproxyBindTo = fproxyBindings[0] // first one should be ipv4
                if let fproxyPort = freenetConfig[FNNodeFreenetConfigFProxyPortKey] {
                    self.fproxyLocation = URL(string: "http://\(fproxyBindTo):\(fproxyPort)")
                    NotificationCenter.default.post(name: Notification.Name.FNNodeConfiguredNotification, object:nil)
                }
            }
 
            var isDirectory = ObjCBool(false)
            
            if FileManager.default.fileExists(atPath: downloadsPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                self.downloadsFolder = URL(fileURLWithPath: downloadsPath, isDirectory: true)
            }
            else {
                // node.downloadsDir isn't a full path, so probably relative to the node files
                self.downloadsFolder = nodeLocation.appendingPathComponent(downloadsPath, isDirectory:true)
            }
        }
    }

    // MARK: - FNFCPWrapperDelegate methods

    func didDisconnect() {
        DispatchQueue.main.async(execute: { 
            self.state = .notRunning
            NotificationCenter.default.post(name: Notification.Name.FNNodeStateNotRunningNotification, object: nil)
            NotificationCenter.default.post(name: Notification.Name.FNNodeFCPDisconnectedNotification, object: nil)
        })

    }

    func didReceiveNodeHello(_ nodeHello: [AnyHashable: Any]) {
        DispatchQueue.main.async(execute: { 
            NotificationCenter.default.post(name: Notification.Name.FNNodeHelloReceivedNotification, object:nodeHello)
        })
    }

    func didReceiveNodeStats(_ nodeStats: [AnyHashable: Any]) {
        DispatchQueue.main.async(execute: { 
            self.state = .running
            NotificationCenter.default.post(name: Notification.Name.FNNodeStateRunningNotification, object:nil)
            NotificationCenter.default.post(name: Notification.Name.FNNodeStatsReceivedNotification, object:nodeStats)
        })
    }

    func didReceiveUserAlert(_ nodeUserAlert: [AnyHashable: Any]) {
        if !UserDefaults.standard.bool(forKey: FNEnableNotificationsKey) {
            return
        }
        let notification = NSUserNotification()

        guard let command = nodeUserAlert["Command"] as? String else {
            // invalid alert values
            return
        }
        
        // N2N messages are handled differently, we want to grab the substring of the response that contains the
        // actual message since display space is limited in the notification popups
        
        if (command == "TextFeed") {
            notification.title = nodeUserAlert["ShortText"] as? String
            let textLength = nodeUserAlert["TextLength"] as! Int
            let messageLength = nodeUserAlert["MessageTextLength"] as! Int
            let messageData: String = nodeUserAlert["Data"] as! String
            let message = messageData.substring(with: (textLength - messageLength - 1)..<(messageLength + 1))    // play

            
            notification.informativeText = message
        }
        else {
            notification.title = nodeUserAlert["Header"] as? String
            notification.informativeText = nodeUserAlert["Data"] as? String
        }
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }

    // MARK: - FNFCPWrapperDataSource methods

    func nodeFCPURL() -> URL? {
        return self.fcpLocation
    }

    // MARK: - NSUserNotificationCenterDelegate methods

    func userNotificationCenter(_ center:NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    func userNotificationCenter(_ center:NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if let fproxyLocation = self.fproxyLocation {
            // Open the alerts page in users default browser
            let alertsPage = fproxyLocation.appendingPathComponent("alerts")
            NSWorkspace.shared().open(alertsPage)
        }
        center.removeAllDeliveredNotifications()
    }
}
