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
    
    private var node: Node!
    private var dropdownMenuController: Dropdown!
    private var settingsWindowController: SettingsWindowController!
    private var installerWindowController: InstallerWindowController!

    
    var CFBundleVersion = (NSBundle.mainBundle().infoDictionary?["CFBundleVersion"]) as! String
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSUserDefaults.standardUserDefaults().registerDefaults(["NSApplicationCrashOnExceptions": true])
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
        
        // load factory defaults for node location variables, sourced from defaults.plist
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults(["NSApplicationCrashOnExceptions": true])
        
        /*
         Check for first launch key, if it isn't there this is first launch and
         we need to setup autostart/loginitem
         */
        if defaults.boolForKey(FNNodeFirstLaunchKey) {
            defaults.setBool(false, forKey: FNNodeFirstLaunchKey)
            defaults.synchronize()
            /*
             Since this is the first launch, we add a login item for the user. If
             they delete that login item it wont be added again.
             */
            Helpers.enableLoginItem(true)
        }
        
        let aboutWindow: DCOAboutWindowController = DCOAboutWindowController()
        aboutWindow.useTextViewForAcknowledgments = true
        let websiteURLPath: String = "https://\(FNWebDomain)"
        aboutWindow.appWebsiteURL = NSURL(string: websiteURLPath)!
        
        let _ = aboutWindow.window!
        
        if let visitWebsiteButton = aboutWindow.valueForKeyPath("self.visitWebsiteButton") as? NSButton {
            visitWebsiteButton.title = NSLocalizedString("Visit the Freenet Website", comment: "Button title")
        }
        
        node = Node()
        
        dropdownMenuController = Dropdown(node: node, aboutWindow: aboutWindow)
        
        settingsWindowController = SettingsWindowController(node: node)
        let _ = settingsWindowController.window!
        
        installerWindowController = InstallerWindowController(node: node)
        let _ = installerWindowController.window!
        
        
        if let nodeURL = Helpers.findNodeInstallation(),
               standardized = nodeURL.URLByStandardizingPath,
               nodePath = standardized.path {
            defaults.setValue(nodePath, forKey: FNNodeInstallationDirectoryKey)
            node.location = nodeURL
            if defaults.boolForKey(FNStartAtLaunchKey) {
                node.startFreenet()
            }
        }
        else {
            // no freenet installation found, ask the user what to do
            Helpers.displayNodeMissingAlert()
        }
        
        
    }
}