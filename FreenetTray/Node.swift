/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation

class Node: NSObject, FNFCPWrapperDelegate, FNFCPWrapperDataSource, NSUserNotificationCenterDelegate {

    var state: FNNodeState = .Unknown
    
    var wrapperConfig: NSDictionary!
    
    var freenetConfig: NSDictionary!
    
    var fcpLocation: NSURL!
    
    var fproxyLocation: NSURL!
    
    var downloadsFolder: NSURL!
    
    private var fcpWrapper: FNFCPWrapper!
    
    private var configWatcher: MHWDirectoryWatcher!

    override init() {
        super.init()
        self.fcpWrapper = FNFCPWrapper()
        self.fcpWrapper.delegate = self
        self.fcpWrapper.dataSource = self
        self.fcpWrapper.nodeStateLoop()
        // spawn a thread to monitor node installation. The method called here cannot be run again while this thread is running
        NSThread.detachNewThreadSelector(#selector(checkNodeInstallation), toTarget:self, withObject:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(installFinished), name:FNInstallFinishedNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(installFailed), name:FNInstallFailedNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(installStartNode), name:FNInstallStartNodeNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(uninstallFreenet), name:FNNodeUninstall, object:nil)
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self

    }

    // MARK: - Uninstaller

    func uninstallFreenet(notification:NSNotification!) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { 

            if !FNHelpers.validateNodeInstallationAtURL(self.location) {
                // warn user that the configured node path is not valid and refuse to delete anything
                dispatch_async(dispatch_get_main_queue(), {         
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Uninstalling Freenet failed", comment: "Title of window")
                    alert.informativeText = NSLocalizedString("No Freenet installation was found, please delete the files manually if needed", comment: "String informing the user that no Freenet installation was found and that they must delete the files manually if needed")
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: "Button title"))
                    let button = alert.runModal()
                    if button == NSAlertFirstButtonReturn {
                        NSWorkspace.sharedWorkspace().openURL(NSBundle.mainBundle().bundleURL)
                        NSApp.terminate(self)
                    }
                })
                return
            }

            while self.state == .Running {
                self.stopFreenet()
                NSThread.sleepForTimeInterval(1)
            }
            
            
            let fileManager = NSFileManager.defaultManager()

            do {
                if let nodeLocation = self.location {
                    try fileManager.removeItemAtURL(nodeLocation)
                }
                else {
                    throw NSError(domain: "org.freenetproject", code: 0x01, userInfo: nil)
                }
            }
            catch let nodeRemovalError as NSError {
                NSLog("Uninstall error: \(nodeRemovalError)")
                // warn user that uninstall did not go smoothly
                dispatch_async(dispatch_get_main_queue(), {         
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Uninstalling Freenet failed", comment: "Title of window")
                    alert.informativeText = nodeRemovalError.localizedDescription
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: "Button title"))

                    let button = alert.runModal()
                    if button == NSAlertFirstButtonReturn {
                        if let nodeLocation = self.location {
                            NSWorkspace.sharedWorkspace().openURL(nodeLocation)
                        }
                        NSApp.terminate(self)
                    }
                })
                return
            }

            do {
                try fileManager.removeItemAtURL(NSBundle.mainBundle().bundleURL)
            }
            catch let appRemovalError as NSError {
                NSLog("App uninstall error: \(appRemovalError)")
                // warn user that uninstall did not go smoothly
                dispatch_async(dispatch_get_main_queue(), {         
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Uninstalling Freenet failed", comment: "Title of window")
                    alert.informativeText = appRemovalError.localizedDescription
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: "Button title"))
                    let button = alert.runModal()
                    if button == NSAlertFirstButtonReturn {
                        NSWorkspace.sharedWorkspace().openURL(NSBundle.mainBundle().bundleURL)
                        NSApp.terminate(self)
                    }
                })
                return
            }
            NSUserDefaults.standardUserDefaults().removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
            NSUserDefaults.standardUserDefaults().synchronize()

            dispatch_async(dispatch_get_main_queue(), {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Freenet Uninstalled", comment: "Title of window")
                alert.informativeText = NSLocalizedString("Freenet has been completely uninstalled", comment: "String informing the user that Freenet uninstallation succeeded")
                alert.addButtonWithTitle(NSLocalizedString("OK", comment: "Button title"))
                let button = alert.runModal()
                if button == NSAlertFirstButtonReturn {
                    NSApp.terminate(self)
                }
            })    
        })
    }

    // MARK: - Install delegate

    func installFinished(notification:NSNotification!) {

    }

    func installFailed(notification:NSNotification!) {
        self.location = nil
    }

    func installStartNode(notification:NSNotification!) {
        if let newInstallation = notification.object as? NSURL {
            self.location = newInstallation
            self.startFreenet()
        }
    }

    // MARK: - Dynamic properties

    var location: NSURL? {
        get {
            if let storedNodePath = NSUserDefaults.standardUserDefaults().objectForKey(FNNodeInstallationDirectoryKey) as? String {
                return NSURL(fileURLWithPath: storedNodePath).URLByStandardizingPath
            }
            return nil
        }
        set(newNodeLocation) {
            if let configWatcher = self.configWatcher {
                configWatcher.stopWatching()
            }
            
            if let nodePath = newNodeLocation?.URLByStandardizingPath?.path {
                NSUserDefaults.standardUserDefaults().setObject(nodePath, forKey:FNNodeInstallationDirectoryKey)
                self.configWatcher = MHWDirectoryWatcher(atPath: nodePath, callback: {
                    self.readFreenetConfig()
                })
                self.configWatcher.startWatching()
            }
            else {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(FNNodeInstallationDirectoryKey)
            }
            self.readFreenetConfig()
        }
    }
    
    // MARK: - Node handling
    func checkNodeInstallation() {
        // start a continuous loop to monitor installation directory
        while true {
            autoreleasepool { 
                if !FNHelpers.validateNodeInstallationAtURL(self.location) {
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.state = .Unknown
                        NSNotificationCenter.defaultCenter().postNotificationName(FNNodeStateUnknownNotification, object: nil)
                    })
                }
            }
            NSThread.sleepForTimeInterval(FNNodeCheckTimeInterval) 
        }
    }

    func startFreenet() {
        let nodeLocation = self.location
        if FNHelpers.validateNodeInstallationAtURL(nodeLocation) {
            let runScript = nodeLocation!.URLByAppendingPathComponent(FNNodeRunscriptPathname)
            NSTask.launchedTaskWithLaunchPath(runScript.path!, arguments:["start"])
        }
        else {
            FNHelpers.displayNodeMissingAlert()
        }
    }

    func stopFreenet() {
        let nodeLocation = self.location
        if FNHelpers.validateNodeInstallationAtURL(nodeLocation) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { 
                let runScript:NSURL! = nodeLocation!.URLByAppendingPathComponent(FNNodeRunscriptPathname)
                let task:NSTask! = NSTask.launchedTaskWithLaunchPath(runScript.path!, arguments: ["stop"])
                task.waitUntilExit()
                // once run.sh returns, we ensure the wrapper state is cleaned up
                // this fixes issues where Freenet.anchor is still around but the wrapper crashed, so the node
                // isn't actually running but the tray app thinks it is, preventing users from using start/stop
                // in the dropdown menu until things go back to a sane state
                self.cleanupAfterShutdown(nodeLocation)
            })
        }
        else {
            FNHelpers.displayNodeMissingAlert()
        }
    }

    // MARK: - Shutdown cleanup

    func cleanupAfterShutdown(nodeLocation:NSURL!) {
        // these are best effort cleanup attempts, we don't care if they fail or why
        let anchorFile = nodeLocation.URLByAppendingPathComponent(FNNodeAnchorFilePathname)
        do {
            try NSFileManager.defaultManager().removeItemAtURL(anchorFile)
        }
        catch {
        
        }

        let pidFile = nodeLocation.URLByAppendingPathComponent(FNNodePIDFilePathname)
        do {
            try NSFileManager.defaultManager().removeItemAtURL(pidFile)
        }
        catch {
        
        }
    }

    // MARK: - Configuration handlers

    func readFreenetConfig() {
        guard let nodeLocation = self.location else {
            return
        }
        if FNHelpers.validateNodeInstallationAtURL(self.location) {
            let wrapperConfigFile = nodeLocation.URLByAppendingPathComponent(FNNodeWrapperConfigFilePathname)
            let freenetConfigFile = nodeLocation.URLByAppendingPathComponent(FNNodeFreenetConfigFilePathname)

            self.wrapperConfig = NodeConfig.fromFile(wrapperConfigFile)

            guard let freenetConfig = NodeConfig.fromFile(freenetConfigFile),
                      fcpBindings = freenetConfig[FNNodeFreenetConfigFCPBindAddressesKey]?.componentsSeparatedByString(","),
                      fproxyBindings = freenetConfig[FNNodeFreenetConfigFProxyBindAddressesKey]?.componentsSeparatedByString(","),
                      downloadsPath = freenetConfig[FNNodeFreenetConfigDownloadsDirKey] as? String else {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Freenet configuration invalid", comment: "Title of window")
                alert.informativeText = NSLocalizedString("Your Freenet installation does not have a freenet.ini file", comment: "String informing the user that Freenet configuration is invalid")
                alert.addButtonWithTitle(NSLocalizedString("OK", comment: "Button title"))
                let button = alert.runModal()
                if button == NSAlertFirstButtonReturn {
                    NSApp.terminate(self)
                }
                return
            }
            
            self.freenetConfig = freenetConfig
            
            if fcpBindings.count > 0 {
                let fcpBindTo = fcpBindings[0] // first one should be ipv4
                let fcpPort = freenetConfig[FNNodeFreenetConfigFCPPortKey] as! String
                self.fcpLocation = NSURL(string: String(format:"tcp://%@:%@", fcpBindTo, fcpPort))
            }
            
            if fproxyBindings.count > 0 {
                let fproxyBindTo = fproxyBindings[0] // first one should be ipv4
                let fproxyPort = freenetConfig[FNNodeFreenetConfigFProxyPortKey] as! String
                self.fproxyLocation = NSURL(string: String(format:"http://%@:%@", fproxyBindTo, fproxyPort))
                NSNotificationCenter.defaultCenter().postNotificationName(FNNodeConfiguredNotification, object:nil)
            }
 
            var isDirectory = ObjCBool(false)
            
            if NSFileManager.defaultManager().fileExistsAtPath(downloadsPath, isDirectory: &isDirectory) && isDirectory {
                self.downloadsFolder = NSURL(fileURLWithPath: downloadsPath, isDirectory: true)
            }
            else {
                // node.downloadsDir isn't a full path, so probably relative to the node files
                self.downloadsFolder = nodeLocation.URLByAppendingPathComponent(downloadsPath, isDirectory:true)
            }
        }
    }

    // MARK: - FNFCPWrapperDelegate methods

    func didDisconnect() {
        dispatch_async(dispatch_get_main_queue(), { 
            self.state = .NotRunning
            NSNotificationCenter.defaultCenter().postNotificationName(FNNodeStateNotRunningNotification, object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName(FNNodeFCPDisconnectedNotification, object: nil)
        })

    }

    func didReceiveNodeHello(nodeHello: [NSObject: AnyObject]) {
        dispatch_async(dispatch_get_main_queue(), { 
            NSNotificationCenter.defaultCenter().postNotificationName(FNNodeHelloReceivedNotification, object:nodeHello)
        })
    }

    func didReceiveNodeStats(nodeStats: [NSObject: AnyObject]) {
        dispatch_async(dispatch_get_main_queue(), { 
            self.state = .Running
            NSNotificationCenter.defaultCenter().postNotificationName(FNNodeStateRunningNotification, object:nil)
            NSNotificationCenter.defaultCenter().postNotificationName(FNNodeStatsReceivedNotification, object:nodeStats)
        })
    }

    func didReceiveUserAlert(nodeUserAlert: [NSObject: AnyObject]) {
        if !NSUserDefaults.standardUserDefaults().boolForKey(FNEnableNotificationsKey) {
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
            let textLength = nodeUserAlert["TextLength"]!.integerValue
            let messageLength = nodeUserAlert["MessageTextLength"]!.integerValue
            let message:String! = nodeUserAlert["Data"]!.substringWithRange(NSMakeRange(textLength - messageLength - 1, messageLength + 1))
            notification.informativeText = message
        }
        else {
            notification.title = nodeUserAlert["Header"] as? String
            notification.informativeText = nodeUserAlert["Data"] as? String
        }
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }

    // MARK: - FNFCPWrapperDataSource methods

    func nodeFCPURL() -> NSURL! {
        return self.fcpLocation
    }

    // MARK: - NSUserNotificationCenterDelegate methods

    func userNotificationCenter(center:NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }

    func userNotificationCenter(center:NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if let fproxyLocation = self.fproxyLocation {
            // Open the alerts page in users default browser
            let alertsPage = fproxyLocation.URLByAppendingPathComponent("alerts")
            NSWorkspace.sharedWorkspace().openURL(alertsPage)
        }
        center.removeAllDeliveredNotifications()
    }
}