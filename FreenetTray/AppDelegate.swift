/*
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    fileprivate var node: Node!
    fileprivate var dropdownMenuController: Dropdown!
    fileprivate var settingsWindowController: SettingsWindowController!
    fileprivate var installerWindowController: InstallerWindowController!

    
    var CFBundleVersion = (Bundle.main.infoDictionary?["CFBundleVersion"]) as! String
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("FreenetTray build \(CFBundleVersion)")
        PFMoveToApplicationsFolderIfNecessary()
        // migrations should go here if at all possible
        

        do {
            try Helpers.migrateLaunchAgent()
            Helpers.migrateLaunchAtStart()
        }
        catch let error as NSError {
            print("Error during migration: \(error)")

        }
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["NSApplicationCrashOnExceptions": true, FNEnableNotificationsKey: true, FNBrowserPreferenceKey: "Safari", FNStartAtLaunchKey: true, FNNodeFirstLaunchKey: true])
        
        /*
         Check for first launch key, if it isn't there this is first launch and
         we need to setup autostart/loginitem
         */
        if defaults.bool(forKey: FNNodeFirstLaunchKey) {
            defaults.set(false, forKey: FNNodeFirstLaunchKey)
            defaults.synchronize()
            /*
             Since this is the first launch, we add a login item for the user. If
             they delete that login item it wont be added again.
             */
            let _ = Helpers.enableLoginItem(true)
        }
        
        let aboutWindow = DCOAboutWindowController()
        
        let markdownURL = Bundle.main.url(forResource: "Changelog.md", withExtension: nil)
        
        let data = FileManager.default.contents(atPath: markdownURL!.path)
        
        let markdown = String(data: data!, encoding: String.Encoding.utf8)!
        
        aboutWindow.appCredits = TSMarkdownParser.standard().attributedString(fromMarkdown: markdown)
        
        aboutWindow.useTextViewForAcknowledgments = true
        let websiteURLPath = "https://\(FNWebDomain)"
        aboutWindow.appWebsiteURL = URL(string: websiteURLPath)!
        
        let _ = aboutWindow.window!
        
        if let visitWebsiteButton = aboutWindow.value(forKeyPath: "self.visitWebsiteButton") as? NSButton {
            visitWebsiteButton.title = NSLocalizedString("Visit the Freenet Website", comment: "Button title")
        }
        
        node = Node()
        
        dropdownMenuController = Dropdown(node: node, aboutWindow: aboutWindow)
        
        settingsWindowController = SettingsWindowController(node: node)
        let _ = settingsWindowController.window!
        
        installerWindowController = InstallerWindowController(node: node)
        let _ = installerWindowController.window!
        
        
        if let nodeURL = Helpers.findNodeInstallation() {
            let standardized = nodeURL.standardizedFileURL
            
            let nodePath = standardized.path
            
            defaults.setValue(nodePath, forKey: FNNodeInstallationDirectoryKey)
            node.location = nodeURL
            if defaults.bool(forKey: FNStartAtLaunchKey) {
                node.startFreenet()
            }
        }
        else {
            // no freenet installation found, ask the user what to do
            Helpers.displayNodeMissingAlert()
        }
        
        
    }
}
