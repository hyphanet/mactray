/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Cocoa

class InstallerWindowController: NSWindowController, NSWindowDelegate, NSPageControllerDelegate, FNInstallerDelegate, FNInstallerDataSource {
    private var backButton: NSButton!
    private var nextButton: NSButton!
    
    private var pageController: NSPageController!

    private var installationProgressIndicator: NSProgressIndicator!
    
    private var selectedInstallLocation: NSURL?

    private var installationInProgress: Bool = false
    private var installationFinished: Bool = false
    
    private var node: Node!

    
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
        
        self.pageController.selectedIndex = FNInstallerPage.Destination.rawValue
        
        self.selectedInstallLocation = NSURL.fileURLWithPath(FNInstallDefaultLocation).URLByStandardizingPath
        
        self.configureMainWindow()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showInstallerWindow), name: FNNodeShowInstallerWindow, object: nil)
    }

    // MARK: FNInstallerNotification
    
    func showInstallerWindow(notification: NSNotification) {
        self.showWindow(nil)
    }
    
    // MARK: IBActions
    func next(sender: AnyObject) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT MAIN THREAD")
        if self.installationFinished {
            if let fproxyLocation = self.node.fproxyLocation {
                NSWorkspace.sharedWorkspace().openURL(fproxyLocation)
                self.window!.close()
            }
        }
        self.pageController.navigateForward(sender)
        self.configureMainWindow()
    }
    
    @IBAction func previous(sender: AnyObject) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT MAIN THREAD")
        self.pageController.navigateBack(sender)
        self.configureMainWindow()
    }
    
    func configureMainWindow() {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT MAIN THREAD")
        if self.pageController.selectedIndex == FNInstallerPage.Progress.rawValue {
            if self.installationInProgress {
                self.nextButton.enabled = false
                self.backButton.enabled = false
            } else if self.installationFinished {
                self.nextButton.enabled = true
                self.backButton.enabled = false
                self.installationProgressIndicator.doubleValue = self.installationProgressIndicator.maxValue
                return
            }
        } else {
            self.nextButton.enabled = self.pageController.selectedIndex < self.pageController.arrangedObjects.count - 1 ? true : false
            self.backButton.enabled = self.pageController.selectedIndex > 0 ? true : false
        }
        self.installationProgressIndicator.minValue = 0
        self.installationProgressIndicator.maxValue = Double(self.pageController.arrangedObjects.count)
        self.installationProgressIndicator.doubleValue = Double(self.pageController.selectedIndex)
    }
    
    // MARK: FNInstallerDelegate
    
    func userDidSelectInstallLocation(installURL: NSURL) {
        self.selectedInstallLocation = installURL
        self.configureMainWindow()
    }
    
    func installerDidCopyFiles() {
        self.installationFinished = false
        self.installationInProgress = false
        self.configureMainWindow()
        NSNotificationCenter.defaultCenter().postNotificationName(FNInstallStartNodeNotification, object: self.selectedInstallLocation)
    }
    
    func installerDidFinish() {
        self.installationFinished = true
        self.installationInProgress = false
        self.configureMainWindow()
    }
    
    func installerDidFailWithLog(log: String) {
        self.installationFinished = false
        self.installationInProgress = false
        self.configureMainWindow()
        
        NSNotificationCenter.defaultCenter().postNotificationName(FNInstallFailedNotification, object: nil)
        
        let installFailedAlert = NSAlert()
        
        installFailedAlert.messageText = NSLocalizedString("Installation failed", comment: "String informing the user that the installation failed")
        
        installFailedAlert.informativeText = NSLocalizedString("The installation log can be automatically uploaded to GitHub. Please report this failure to the Freenet developers and provide the GitHub link to them.", comment: "String asking the user to provide the Gist link to the Freenet developers")
        
        installFailedAlert.addButtonWithTitle(NSLocalizedString("Upload", comment: "Button title"))
        
        installFailedAlert.addButtonWithTitle(NSLocalizedString("Quit", comment: ""))
        
        let button = installFailedAlert.runModal()
        
        
        if button == NSAlertFirstButtonReturn {
            Helpers.createGist(log, withTitle: "Installation Log", success: { (url) in
                let pasteBoard = NSPasteboard.generalPasteboard()
                pasteBoard.declareTypes([NSPasteboardTypeString], owner: nil)
                pasteBoard.setString(url.path!, forType: NSStringPboardType)
                NSWorkspace.sharedWorkspace().openURL(url)
                NSApp.terminate(self)
            }, failure: { (error) in
                let desktop = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0]
                let url = NSURL(fileURLWithPath: desktop).URLByAppendingPathComponent("FreenetTray - Installation Log.txt")
                
                if let logBuffer = log.dataUsingEncoding(NSUTF8StringEncoding) {
                    do {
                        try logBuffer.writeToURL(url, options: .AtomicWrite)
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

    func pageController(pageController: NSPageController, identifierForObject object: AnyObject) -> String {
        return object as! String
    }

    func pageController(pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
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

    func pageController(pageController: NSPageController, prepareViewController viewController: NSViewController, withObject object: AnyObject) {
        viewController.representedObject = object
    }

    func pageController(pageController: NSPageController, didTransitionToObject object: AnyObject) {
        self.configureMainWindow()
    }

    func pageControllerDidEndLiveTransition(pageController: NSPageController) {
        self.pageController.completeTransition()
        if self.pageController.selectedIndex == FNInstallerPage.Progress.rawValue {
            if let vc: InstallerProgressViewController = self.pageController.selectedViewController as? InstallerProgressViewController {
                vc.installNodeAtFileURL(self.selectedInstallLocation)
            }
            self.installationInProgress = true
            self.configureMainWindow()
        }
    }
    
    // MARK: - NSWindowDelegate

    func windowShouldClose(sender: AnyObject) -> Bool {
        if self.installationInProgress {
            let installInProgressAlert:NSAlert! = NSAlert()
            
            installInProgressAlert.messageText = NSLocalizedString("Installation in progress", comment: "String informing the user that an installation is in progress")
            
            installInProgressAlert.informativeText = NSLocalizedString("Are you sure you want to cancel?", comment: "String asking the user if they want to cancel the installation")
            
            installInProgressAlert.addButtonWithTitle(NSLocalizedString("Yes", comment: "Button title"))
            
            installInProgressAlert.addButtonWithTitle(NSLocalizedString("No", comment: "Button title"))
            
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

