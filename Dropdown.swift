/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/
import Cocoa

class Dropdown: NSObject, FNNodeStateProtocol, FNNodeStatsProtocol {
    private var node: Node!
    private var statusItem: NSStatusItem!
    private var aboutWindow: DCOAboutWindowController!
    private var dropdownMenu: NSMenu!
    
    @IBOutlet var toggleNodeStateMenuItem: NSMenuItem!
    @IBOutlet var openWebInterfaceMenuItem: NSMenuItem!
    @IBOutlet var openDownloadsMenuItem: NSMenuItem!
    
    private var menuBarImage: NSImage? {
        set(image)  {
            self.statusItem.image = image
        }
        get {
            return self.statusItem.image
        }
    }

    convenience init(node: Node, aboutWindow: DCOAboutWindowController) {
        self.init()
        self.node = node
        self.aboutWindow = aboutWindow
    }
    
    override init() {
        super.init()
        NSBundle.mainBundle().loadNibNamed("Dropdown", owner: self, topLevelObjects: nil)
    }
    
    
    override func awakeFromNib() {
        self.statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        self.statusItem.alternateImage = TrayIcon.imageOfHighlightedIcon()
        self.statusItem.menu = self.dropdownMenu
        self.statusItem.toolTip = NSLocalizedString("Freenet", comment: "Application Name")
        
        self.menuBarImage = TrayIcon.imageOfNotRunningIcon()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Dropdown.nodeStateRunning), name: FNNodeStateRunningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Dropdown.nodeStateNotRunning), name: FNNodeStateNotRunningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Dropdown.didReceiveNodeStats), name: FNNodeStatsReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Dropdown.didReceiveNodeHello), name: FNNodeHelloReceivedNotification, object: nil)
    }
    
    private func enableMenuItems(state: Bool) {
        self.toggleNodeStateMenuItem.enabled = state
        self.openDownloadsMenuItem.enabled = state
        self.openWebInterfaceMenuItem.enabled = state
    }
    
    
    @IBAction func toggleNodeState(sender: AnyObject) {
        switch self.node.state {
        case .Running:
            self.node.stopFreenet()
            
        case .NotRunning:
            self.node.startFreenet()
            
        case .Unknown:
            self.node.startFreenet()
        }
    }
    
    
    func openWebInterface(sender: AnyObject) {
        if let fproxyLocation = self.node.fproxyLocation {
            // Open the fproxy page in users default browser
            NSWorkspace.sharedWorkspace().openURL(fproxyLocation)
        }
    }

    
    func showAboutPanel(sender: AnyObject) {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        self.aboutWindow.showWindow(nil)
    }
    
    func showSettingsWindow(sender: AnyObject) {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        NSNotificationCenter.defaultCenter().postNotificationName(FNNodeShowSettingsWindow, object: nil)
    }
    
    func showDownlodsFolder(sender: AnyObject) {
        guard let path = self.node.downloadsFolder?.path else {
            return
        }
        NSWorkspace.sharedWorkspace().selectFile(nil, inFileViewerRootedAtPath: path)
    }
    
    func uninstallFreenet(sender: AnyObject) {
        Helpers.displayUninstallAlert()
    }
    
    
    // MARK: - FNNodeStateProtocol methods
    
    
    func nodeStateUnknown(notification: NSNotification) {
        self.enableMenuItems(false)
    }
    
    func nodeStateRunning(notification: NSNotification) {
        self.toggleNodeStateMenuItem.title = NSLocalizedString("Stop Freenet", comment: "Button title")
        self.menuBarImage = TrayIcon.imageOfRunningIcon()
        self.enableMenuItems(true)
    }
    
    func nodeStateNotRunning(notification: NSNotification) {
        self.toggleNodeStateMenuItem.title = NSLocalizedString("Start Freenet", comment: "Button title")
        self.menuBarImage = TrayIcon.imageOfNotRunningIcon()
        self.enableMenuItems(true)
    }
    
    // MARK: - FNNodeStatsProtocol methods
    
    
    func didReceiveNodeHello(notification: NSNotification) {
    
    }
    
    func didReceiveNodeStats(notification: NSNotification) {
        //NSDictionary *nodeStats = notification.object;
        //NSDictionary *nodeStats = notification.object;
    }
}
