/*
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Cocoa

class InstallerWindowController: NSWindowController, NSWindowDelegate, NSPageControllerDelegate, FNInstallerDelegate, FNInstallerDataSource {
    fileprivate var backButton: NSButton!
    fileprivate var nextButton: NSButton!
    
    fileprivate var pageController: NSPageController!

    fileprivate var installationProgressIndicator: NSProgressIndicator!
    
    fileprivate var selectedInstallLocation: URL?

    fileprivate var installationInProgress: Bool = false
    fileprivate var installationFinished: Bool = false
    
    fileprivate var node: Node!

    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init (node: Node) {
        self.init(windowNibName: "InstallerWindow")
        self.node = node
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.delegate = self
        self.pageController.delegate = self
        
        let pageIdentifiers = ["InstallerDestinationViewController", "InstallerProgressViewController"]
        
        self.pageController.arrangedObjects = pageIdentifiers
        
        self.pageController.selectedIndex = FNInstallerPage.destination.rawValue
        
        self.selectedInstallLocation = URL(fileURLWithPath: FNInstallDefaultLocation).standardizedFileURL
        
        self.configureMainWindow()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showInstallerWindow), name: NSNotification.Name.FNNodeShowInstallerWindow, object: nil)
    }

    // MARK: FNInstallerNotification
    
    func showInstallerWindow(_ notification: Notification) {
        self.showWindow(nil)
    }
    
    // MARK: IBActions
    func next(_ sender: AnyObject) {
        assert(Thread.current == Thread.main, "NOT MAIN THREAD")
        if self.installationFinished {
            if let fproxyLocation = self.node.fproxyLocation {
                NSWorkspace.shared().open(fproxyLocation)
                self.window!.close()
            }
        }
        self.pageController.navigateForward(sender)
        self.configureMainWindow()
    }
    
    @IBAction func previous(_ sender: AnyObject) {
        assert(Thread.current == Thread.main, "NOT MAIN THREAD")
        self.pageController.navigateBack(sender)
        self.configureMainWindow()
    }
    
    func configureMainWindow() {
        assert(Thread.current == Thread.main, "NOT MAIN THREAD")
        if self.pageController.selectedIndex == FNInstallerPage.progress.rawValue {
            if self.installationInProgress {
                self.nextButton.isEnabled = false
                self.backButton.isEnabled = false
            } else if self.installationFinished {
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = false
                self.installationProgressIndicator.doubleValue = self.installationProgressIndicator.maxValue
                return
            }
        } else {
            self.nextButton.isEnabled = self.pageController.selectedIndex < self.pageController.arrangedObjects.count - 1 ? true : false
            self.backButton.isEnabled = self.pageController.selectedIndex > 0 ? true : false
        }
        self.installationProgressIndicator.minValue = 0
        self.installationProgressIndicator.maxValue = Double(self.pageController.arrangedObjects.count)
        self.installationProgressIndicator.doubleValue = Double(self.pageController.selectedIndex)
    }
    
    // MARK: FNInstallerDelegate
    
    func userDidSelectInstallLocation(_ installURL: URL) {
        self.selectedInstallLocation = installURL
        self.configureMainWindow()
    }
    
    func installerDidCopyFiles() {
        self.installationFinished = false
        self.installationInProgress = false
        self.configureMainWindow()
        NotificationCenter.default.post(name: Notification.Name.FNInstallStartNodeNotification, object: self.selectedInstallLocation)
    }
    
    func installerDidFinish() {
        self.installationFinished = true
        self.installationInProgress = false
        self.configureMainWindow()
    }
    
    func installerDidFailWithLog(_ log: String) {
        self.installationFinished = false
        self.installationInProgress = false
        self.configureMainWindow()
        
        NotificationCenter.default.post(name: Notification.Name.FNInstallFailedNotification, object: nil)
        
        let installFailedAlert = NSAlert()
        
        installFailedAlert.messageText = NSLocalizedString("Installation failed", comment: "String informing the user that the installation failed")
        
        installFailedAlert.informativeText = NSLocalizedString("The installation log can be automatically uploaded to GitHub. Please report this failure to the Freenet developers and provide the GitHub link to them.", comment: "String asking the user to provide the Gist link to the Freenet developers")
        
        installFailedAlert.addButton(withTitle: NSLocalizedString("Upload", comment: "Button title"))
        
        installFailedAlert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
        
        let button = installFailedAlert.runModal()
        
        
        if button == NSAlertFirstButtonReturn {
            Helpers.createGist(log, withTitle: "Installation Log", success: { (url) in
                let pasteBoard = NSPasteboard.general()
                pasteBoard.declareTypes([NSPasteboardTypeString], owner: nil)
                pasteBoard.setString(url.path, forType: NSStringPboardType)
                NSWorkspace.shared().open(url)
                NSApp.terminate(self)
            }, failure: { (error) in
                let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
                let url = URL(fileURLWithPath: desktop).appendingPathComponent("FreenetTray - Installation Log.txt")
                
                if let logBuffer = log.data(using: String.Encoding.utf8) {
                    do {
                        try logBuffer.write(to: url, options: .atomicWrite)
                    }
                    catch {
                        // best effort, if we can't write to the log file there's nothing else we can do
                    }
                }
                
                let uploadFailedAlert = NSAlert()
                
                uploadFailedAlert.messageText = NSLocalizedString("Upload failed", comment: "String informing the user that the upload failed")
                uploadFailedAlert.informativeText = NSLocalizedString("The installation log could not be uploaded to GitHub, it has been placed on your desktop instead. Please report this failure to the Freenet developers and provide the file to them.", comment: "String informing the user that the log upload failed")
                
                let _ = uploadFailedAlert.runModal()
            })
        } else if button == NSAlertSecondButtonReturn {
            NSApp.terminate(self)
        }
    }
    
    // MARK: - NSPageControllerDelegate

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return object as! String
    }

    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        if (identifier == "InstallerDestinationViewController") {
            let vc: InstallerDestinationViewController! = InstallerDestinationViewController(nibName: "InstallerDestinationView", bundle: nil)
            vc.stateDelegate = self
            return vc
        }
        else if (identifier == "InstallerProgressViewController") {
            let vc: InstallerProgressViewController! = InstallerProgressViewController(nibName: "InstallerProgressView", bundle: nil)
            vc.stateDelegate = self
            return vc
        }
        return NSViewController() // should never reach this point, silencing compiler 
    }

    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        viewController.representedObject = object
    }

    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        self.configureMainWindow()
    }

    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        self.pageController.completeTransition()
        if self.pageController.selectedIndex == FNInstallerPage.progress.rawValue {
            if let vc: InstallerProgressViewController = self.pageController.selectedViewController as? InstallerProgressViewController {
                vc.installNodeAtFileURL(self.selectedInstallLocation)
            }
            self.installationInProgress = true
            self.configureMainWindow()
        }
    }
    
    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: Any) -> Bool {
        if self.installationInProgress {
            let installInProgressAlert:NSAlert! = NSAlert()
            
            installInProgressAlert.messageText = NSLocalizedString("Installation in progress", comment: "String informing the user that an installation is in progress")
            
            installInProgressAlert.informativeText = NSLocalizedString("Are you sure you want to cancel?", comment: "String asking the user if they want to cancel the installation")
            
            installInProgressAlert.addButton(withTitle: NSLocalizedString("Yes", comment: "Button title"))
            
            installInProgressAlert.addButton(withTitle: NSLocalizedString("No", comment: "Button title"))
            
            let button:Int = installInProgressAlert.runModal()
            
            if button == NSAlertFirstButtonReturn {
                NSApp.terminate(self)
            }
            else if button == NSAlertSecondButtonReturn {
                // user cancelled
            }
        }
        return self.installationInProgress ? false : true 
    }
    
}

