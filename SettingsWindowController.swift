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
            return FNHelpers.validateNodeInstallationAtURL(self.node.location)
        }
    }

    var loginItem: Bool {
        set(state) {
            FNHelpers.enableLoginItem(state)
            NSUserDefaults.standardUserDefaults().setBool(state, forKey: FNStartAtLaunchKey)
        }
        get {
            return FNHelpers.isLoginItem()
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.showSettingsWindow), name: FNNodeShowSettingsWindow, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.nodeStateUnknown), name: FNNodeStateUnknownNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.nodeStateRunning), name: FNNodeStateRunningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.nodeStateNotRunning), name: FNNodeStateNotRunningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.didReceiveNodeHello), name: FNNodeHelloReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.didReceiveNodeStats), name: FNNodeStatsReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.didDisconnect), name: FNNodeFCPDisconnectedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsWindowController.showNodeFinderPanel), name: FNNodeShowNodeFinderInSettingsWindow, object: nil)
        
    }
    
    
    // MARK: - Notification handlers
    
    
    func showNodeFinderPanel(notification: NSNotification) {
        self.selectNodeLocation(self)
    }
    
    func showSettingsWindow(notification: NSNotification) {
        self.showWindow(nil)
    }
    
    // MARK: - Interface actions
    
    
    func selectNodeLocation(sender: AnyObject) {
        let openpanel: NSOpenPanel = NSOpenPanel()
        openpanel.delegate = self
        openpanel.canChooseFiles = false
        openpanel.allowsMultipleSelection = false
        openpanel.canChooseDirectories = true
        let panelTitle: String = NSLocalizedString("Find your Freenet installation", comment: "Title of window")
        openpanel.title = panelTitle
        let promptString: String = NSLocalizedString("Select Freenet installation", comment: "Button title")
        openpanel.prompt = promptString
        openpanel.beginWithCompletionHandler({(result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.node.location = openpanel.URL
                self.nodePathDisplay.URL = openpanel.URL
                self.showWindow(nil)
            }
        })
    }
    
    func uninstallFreenet(sender: AnyObject) {
        FNHelpers.displayUninstallAlert()
    }
    
    
    // MARK: - NSOpenPanelDelegate
    
    
    func panel(sender: AnyObject, validateURL url: NSURL) throws {
        if !FNHelpers.validateNodeInstallationAtURL(url) {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Not a valid Freenet installation", comment: "String informing the user that the selected location is not a Freenet installation")]
            throw NSError(domain: "org.freenetproject", code: 0x1000, userInfo: errorInfo)
        }
    }
    
    // MARK: - FNNodeStateProtocol methods
    
    
    func nodeStateUnknown(notification: NSNotification) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")
        self.willChangeValueForKey("validNodeFound")
        self.didChangeValueForKey("validNodeFound")
        self.nodeRunningStatusView.image = NSImage(named: NSImageNameStatusPartiallyAvailable)
    }
    
    func nodeStateRunning(notification: NSNotification) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")
        self.willChangeValueForKey("validNodeFound")
        self.didChangeValueForKey("validNodeFound")
        self.nodeRunningStatusView.image = NSImage(named: NSImageNameStatusAvailable)
    }
    
    func nodeStateNotRunning(notification: NSNotification) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")
        self.willChangeValueForKey("validNodeFound")
        self.didChangeValueForKey("validNodeFound")
        self.nodeRunningStatusView.image = NSImage(named: NSImageNameStatusUnavailable)
    }
    
    // MARK: - FNNodeStatsProtocol methods
    
    
    func didReceiveNodeHello(notification: NSNotification) {
        guard let nodeHello = notification.object as? [String : AnyObject] else {
            return
        }
        if let build = nodeHello["Build"] as? String {
            self.nodeBuildField.stringValue = build
        }
        self.fcpStatusView.image = NSImage(named: NSImageNameStatusPartiallyAvailable)
    }
    
    func didReceiveNodeStats(notification: NSNotification) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")
        self.fcpStatusView.image = NSImage(named: NSImageNameStatusAvailable)
    }
    
    // MARK: - FNFCPWrapperDelegate methods
    
    
    func didDisconnect() {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")
        self.fcpStatusView.image = NSImage(named: NSImageNameStatusUnavailable)
        self.nodeBuildField.stringValue = ""
    }
}
