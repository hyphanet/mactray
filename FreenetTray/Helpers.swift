/*
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation
import ServiceManagement

public extension Dictionary {
    func merge(_ dict: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var c = self
        for (key, value) in dict {
            c[key] = value
        }        
        return c
    }    
}

class Helpers : NSObject {

    class func findNodeInstallation() -> URL? {
    
        let fileManager = FileManager.default
        
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        let applicationsURL = fileManager.urls(for: .allApplicationsDirectory, in:.systemDomainMask).first!

        // existing or user-defined location
        var customInstallationURL: URL? = nil
        if let customPath = UserDefaults.standard.object(forKey: FNNodeInstallationDirectoryKey) as? String {
            customInstallationURL = URL(fileURLWithPath: customPath).standardizedFileURL
        }
        
        // new default ~/Library/Application Support/Freenet
        let defaultInstallationURL = applicationSupportURL.appendingPathComponent(FNNodeInstallationPathname, isDirectory:true)

        // old default /Applications/Freenet
        let deprecatedInstallationURL = applicationsURL.appendingPathComponent(FNNodeInstallationPathname, isDirectory:true)

        if self.validateNodeInstallationAtURL(customInstallationURL) {
            return customInstallationURL
        }
        else if self.validateNodeInstallationAtURL(defaultInstallationURL) {
            return defaultInstallationURL
        }
        else if self.validateNodeInstallationAtURL(deprecatedInstallationURL) {
            return deprecatedInstallationURL
        }
        return nil
    }

    class func validateNodeInstallationAtURL(_ nodeURL: URL?) -> Bool {
        guard let nodeURL = nodeURL else {
            return false
        }
        
        
        let fileURL = nodeURL.appendingPathComponent(FNNodeRunscriptPathname)
        
        let path = fileURL.path
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: path, isDirectory:nil) {
            return true
        }
        return false
    }

    class func displayNodeMissingAlert() {
        // no installation found, tell the user to pick a location or start the installer
        DispatchQueue.main.async(execute: {         
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("A Freenet installation could not be found.", comment: "String informing the user that no Freenet installation could be found")
            alert.informativeText = NSLocalizedString("Would you like to install Freenet now, or locate an existing Freenet installation?", comment: "String asking the user whether they would like to install freenet or locate an existing installation")
            alert.addButton(withTitle: NSLocalizedString("Install Freenet", comment: "Button title"))

            alert.addButton(withTitle: NSLocalizedString("Find Installation", comment: "Button title"))
            alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))

            let button = alert.runModal()
            
            if button == NSAlertFirstButtonReturn {
                // display installer
                NotificationCenter.default.post(name: Notification.Name.FNNodeShowInstallerWindow, object:nil)
            }
            else if button == NSAlertSecondButtonReturn {
                // display node finder panel
                NotificationCenter.default.post(name: Notification.Name.FNNodeShowNodeFinderInSettingsWindow, object:nil)
            }
            else if button == NSAlertThirdButtonReturn {
                // display node finder panel
                NSApp.terminate(self)
            }
        }) 
    }

    class func displayUninstallAlert() {
        // ask the user if they really do want to uninstall Freenet
        DispatchQueue.main.async(execute: {         
            let alert:NSAlert! = NSAlert()
            alert.messageText = NSLocalizedString("Uninstall Freenet now?", comment: "Title of window")
            alert.informativeText = NSLocalizedString("Uninstalling Freenet is immediate and irreversible, are you sure you want to uninstall Freenet now?", comment: "String asking the user whether they would like to uninstall freenet")
            alert.addButton(withTitle: NSLocalizedString("Uninstall Freenet", comment: "Button title"))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Button title"))

            let button:Int = alert.runModal()
            if button == NSAlertFirstButtonReturn {
                // start uninstallation
                NotificationCenter.default.post(name: Notification.Name.FNNodeUninstall, object:nil)
            }
            else if button == NSAlertSecondButtonReturn {
                // user canceled, don't do anything
            }
        }) 
    }

    class func installedWebBrowsers() -> [Browser]? {
        let url = URL(string: "https://")!
        
        let roles = LSRolesMask.viewer
        
        if let appUrls = LSCopyApplicationURLsForURL(url as CFURL, roles)?.takeRetainedValue() {
            // Extract the app names and sort them for prettiness.
            var appNames = [Browser]()
            guard let appUrls = appUrls as NSArray as? [URL] else {
                return nil
            }

            for url in appUrls {
                appNames.append(Browser.browserWithFileURL(url))
            }

            return appNames
        }
        return nil
    }

    // MARK: -
    // MARK: - Migrations

    class func migrateLaunchAgent() throws {
        let fileManager = FileManager.default
    
        let libraryDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        
        if let launchAgentsDirectory = libraryDirectory?.appendingPathComponent("LaunchAgents", isDirectory:true) {
            let launchAgent = launchAgentsDirectory.appendingPathComponent(FNNodeLaunchAgentPathname)
            if fileManager.fileExists(atPath: launchAgent.path, isDirectory:nil) {
                try fileManager.removeItem(at: launchAgent)
            }
        }
    }
    
    class func migrateLaunchAtStart() {
        let startAtLaunch = UserDefaults.standard.bool(forKey: FNStartAtLaunchKey)
        let _ = Helpers.enableLoginItem(startAtLaunch)
    }

    class func createGist(_ string: String, withTitle title: String, success: @escaping FNGistSuccessBlock, failure: @escaping FNGistFailureBlock) {
        let fileName = "FreenetTray - \(title).txt"
        let params: [String : Any] = [
            "description": title,
            "public": true,
            "files": [
                fileName: [
                    "content": string
                ]
            ]
        ]
        
        let headers: [String: String] = [
            "Content-Type": "application/vnd.github.v3+json",
            "Accept": "application/json",
            "User-Agent": "FreenetTray for OS X"
        ]
        
        let request = NSMutableURLRequest(url: URL(string: "https://\(FNGithubAPI)/gists")!)
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        if let body = try? JSONSerialization.data(withJSONObject: params) {
            request.httpBody = body
        }
        request.allHTTPHeaderFields = headers
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!)
                
                let response = json as! [String: AnyObject]
                let html_url = response["html_url"] as! String
                let gist = URL(fileURLWithPath: html_url)
                success(gist)
            
            } catch let error {
                failure(error)
            }
        })
        
        task.resume()
    }
    
    class func enableLoginItem(_ state: Bool) -> Bool {

        let helper = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LoginItems/FreenetTray Helper.app", isDirectory: true)

        if LSRegisterURL(helper as CFURL, state) != noErr {
            print("Failed to LSRegisterURL \(helper)")
        }

        if (SMLoginItemSetEnabled(("org.freenetproject.FreenetTray-Helper" as CFString), true)) {
            return true
        }
        else {
            print("Failed to SMLoginItemSetEnabled \(helper)")
            return false
        }
    }
}
