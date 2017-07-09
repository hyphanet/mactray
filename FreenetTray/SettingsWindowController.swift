/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Cocoa

class SettingsWindowController: NSWindowController,  NSOpenSavePanelDelegate, NSPathControlDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    var node: Node!
    
    var validNodeFound: Bool {
        get {
            return Helpers.validateNodeInstallationAtURL(self.node.location)
        }
    }

    var loginItem: Bool {
        set(state) {
            Helpers.enableLoginItem(state)
            UserDefaults.standard.set(state, forKey: FNStartAtLaunchKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: FNStartAtLaunchKey)
        }
    }


    @IBOutlet var nodeRunningStatusView: NSImageView!
    @IBOutlet var webInterfaceStatusView: NSImageView!
    @IBOutlet var fcpStatusView: NSImageView!
    @IBOutlet var nodeBuildField: NSTextField!
    @IBOutlet var nodePathDisplay: NSPathControl!
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init (node: Node) {
        self.init(windowNibName: "SettingsWindow")
        self.node = node
    }
    
    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.showSettingsWindow), name: Notification.Name.FNNodeShowSettingsWindow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.nodeStateUnknown), name: Notification.Name.FNNodeStateUnknownNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.nodeStateRunning), name: Notification.Name.FNNodeStateRunningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.nodeStateNotRunning), name: Notification.Name.FNNodeStateNotRunningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.didReceiveNodeHello), name: Notification.Name.FNNodeHelloReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.didReceiveNodeStats), name: Notification.Name.FNNodeStatsReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.didDisconnect), name: Notification.Name.FNNodeFCPDisconnectedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsWindowController.showNodeFinderPanel), name: Notification.Name.FNNodeShowNodeFinderInSettingsWindow, object: nil)
        
    }
    
    
    // MARK: - Notification handlers
    
    
    func showNodeFinderPanel(_ notification: Notification) {
        self.selectNodeLocation(self)
    }
    
    func showSettingsWindow(_ notification: Notification) {
        self.showWindow(nil)
    }
    
    // MARK: - Interface actions
    
    
    func selectNodeLocation(_ sender: AnyObject) {
        let openpanel: NSOpenPanel = NSOpenPanel()
        openpanel.delegate = self
        openpanel.canChooseFiles = false
        openpanel.allowsMultipleSelection = false
        openpanel.canChooseDirectories = true
        let panelTitle: String = NSLocalizedString("Find your Freenet installation", comment: "Title of window")
        openpanel.title = panelTitle
        let promptString: String = NSLocalizedString("Select Freenet installation", comment: "Button title")
        openpanel.prompt = promptString
        openpanel.begin(completionHandler: {(result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.node.location = openpanel.url
                self.nodePathDisplay.url = openpanel.url
                self.showWindow(nil)
            }
        })
    }
    
    func uninstallFreenet(_ sender: AnyObject) {
        Helpers.displayUninstallAlert()
    }
    
    
    // MARK: - NSOpenPanelDelegate
    
    
    func panel(_ sender: Any, validate url: URL) throws {
        if !Helpers.validateNodeInstallationAtURL(url) {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Not a valid Freenet installation", comment: "String informing the user that the selected location is not a Freenet installation")]
            throw NSError(domain: "org.freenetproject", code: 0x1000, userInfo: errorInfo)
        }
    }
    
    // MARK: - FNNodeStateProtocol methods
    
    
    func nodeStateUnknown(_ notification: Notification) {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")
        self.willChangeValue(forKey: "validNodeFound")
        self.didChangeValue(forKey: "validNodeFound")
        self.nodeRunningStatusView.image = NSImage(named: NSImageNameStatusPartiallyAvailable)
    }
    
    func nodeStateRunning(_ notification: Notification) {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")
        self.willChangeValue(forKey: "validNodeFound")
        self.didChangeValue(forKey: "validNodeFound")
        self.nodeRunningStatusView.image = NSImage(named: NSImageNameStatusAvailable)
    }
    
    func nodeStateNotRunning(_ notification: Notification) {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")
        self.willChangeValue(forKey: "validNodeFound")
        self.didChangeValue(forKey: "validNodeFound")
        self.nodeRunningStatusView.image = NSImage(named: NSImageNameStatusUnavailable)
    }
    
    // MARK: - FNNodeStatsProtocol methods
    
    
    func didReceiveNodeHello(_ notification: Notification) {
        guard let nodeHello = notification.object as? [String : AnyObject] else {
            return
        }
        if let build = nodeHello["Build"] as? String {
            self.nodeBuildField.stringValue = build
        }
        self.fcpStatusView.image = NSImage(named: NSImageNameStatusPartiallyAvailable)
    }
    
    func didReceiveNodeStats(_ notification: Notification) {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")
        self.fcpStatusView.image = NSImage(named: NSImageNameStatusAvailable)
    }
    
    // MARK: - FNFCPWrapperDelegate methods
    
    
    func didDisconnect() {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")
        self.fcpStatusView.image = NSImage(named: NSImageNameStatusUnavailable)
        self.nodeBuildField.stringValue = ""
    }
}
