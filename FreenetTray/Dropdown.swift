/*
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/
import Cocoa

class Dropdown: NSObject, FNNodeStateProtocol, FNNodeStatsProtocol {
    fileprivate var node: Node!
    fileprivate var statusItem: NSStatusItem!
    fileprivate var aboutWindow: DCOAboutWindowController!
    fileprivate var dropdownMenu: NSMenu!
    
    @IBOutlet var toggleNodeStateMenuItem: NSMenuItem!
    @IBOutlet var openWebInterfaceMenuItem: NSMenuItem!
    @IBOutlet var openDownloadsMenuItem: NSMenuItem!
    
    fileprivate var menuBarImage: NSImage? {
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
        Bundle.main.loadNibNamed("Dropdown", owner: self, topLevelObjects: nil)
    }
    
    
    override func awakeFromNib() {
        self.statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        self.statusItem.alternateImage = TrayIcon.imageOfHighlightedIcon
        self.statusItem.menu = self.dropdownMenu
        self.statusItem.toolTip = NSLocalizedString("Freenet", comment: "Application Name")
        
        self.menuBarImage = TrayIcon.imageOfNotRunningIcon
        
        NotificationCenter.default.addObserver(self, selector: #selector(Dropdown.nodeStateRunning), name: NSNotification.Name.FNNodeStateRunningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Dropdown.nodeStateNotRunning), name: NSNotification.Name.FNNodeStateNotRunningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Dropdown.didReceiveNodeStats), name: NSNotification.Name.FNNodeStatsReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Dropdown.didReceiveNodeHello), name: NSNotification.Name.FNNodeHelloReceivedNotification, object: nil)
    }
    
    fileprivate func enableMenuItems(_ state: Bool) {
        self.toggleNodeStateMenuItem.isEnabled = state
        self.openDownloadsMenuItem.isEnabled = state
        self.openWebInterfaceMenuItem.isEnabled = state
    }
    
    
    @IBAction func toggleNodeState(_ sender: AnyObject) {
        switch self.node.state {
        case .running:
            self.node.stopFreenet()
            
        case .notRunning:
            self.node.startFreenet()
            
        case .unknown:
            self.node.startFreenet()
        }
    }
    
    
    func openWebInterface(_ sender: AnyObject) {
        if let fproxyLocation = self.node.fproxyLocation {
            // Open the fproxy page in users default browser
            NSWorkspace.shared().open(fproxyLocation)
        }
    }

    
    func showAboutPanel(_ sender: AnyObject) {
        NSApplication.shared().activate(ignoringOtherApps: true)
        self.aboutWindow.showWindow(nil)
    }
    
    func showSettingsWindow(_ sender: AnyObject) {
        NSApplication.shared().activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: Notification.Name.FNNodeShowSettingsWindow, object: nil)
    }
    
    func showDownlodsFolder(_ sender: AnyObject) {
        guard let path = self.node.downloadsFolder?.path else {
            return
        }
        NSWorkspace.shared().selectFile(nil, inFileViewerRootedAtPath: path)
    }
    
    func uninstallFreenet(_ sender: AnyObject) {
        Helpers.displayUninstallAlert()
    }
    
    
    // MARK: - FNNodeStateProtocol methods
    
    
    func nodeStateUnknown(_ notification: Notification) {
        self.enableMenuItems(false)
    }
    
    func nodeStateRunning(_ notification: Notification) {
        self.toggleNodeStateMenuItem.title = NSLocalizedString("Stop Freenet", comment: "Button title")
        self.menuBarImage = TrayIcon.imageOfRunningIcon
        self.enableMenuItems(true)
    }
    
    func nodeStateNotRunning(_ notification: Notification) {
        self.toggleNodeStateMenuItem.title = NSLocalizedString("Start Freenet", comment: "Button title")
        self.menuBarImage = TrayIcon.imageOfNotRunningIcon
        self.enableMenuItems(true)
    }
    
    // MARK: - FNNodeStatsProtocol methods
    
    
    func didReceiveNodeHello(_ notification: Notification) {
    
    }
    
    func didReceiveNodeStats(_ notification: Notification) {
        //NSDictionary *nodeStats = notification.object;
        //NSDictionary *nodeStats = notification.object;
    }
}
