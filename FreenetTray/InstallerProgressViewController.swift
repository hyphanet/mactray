/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Cocoa
import FontAwesomeIconFactory
import CocoaAsyncSocket

class InstallerProgressViewController: NSViewController {

    fileprivate var javaInstallationTitle: NSTextField!

    fileprivate var javaInstallationStatus: NIKFontAwesomeImageView!

    fileprivate var fileCopyTitle: NSTextField!

    fileprivate var fileCopyStatus: NIKFontAwesomeImageView!

    fileprivate var portsTitle: NSTextField!

    fileprivate var portsStatus: NIKFontAwesomeImageView!

    fileprivate var startNodeTitle: NSTextField!

    fileprivate var startNodeStatus: NIKFontAwesomeImageView!

    fileprivate var finishedTitle: NSTextField!

    fileprivate var finishedStatus: NIKFontAwesomeImageView!

    fileprivate var installLog: NSMutableAttributedString!
    
    var stateDelegate:FNInstallerDelegate!
    
    fileprivate var javaPromptShown: Bool = false
 
    
    
    
    
    override func awakeFromNib() {
        self.updateProgress(FNInstallerProgress.unknown)
        self.installLog = NSMutableAttributedString()
        self.javaPromptShown = false
    }
    
    // MARK: - Step 1: Entry point

    func installNodeAtFileURL(_ installLocation:URL!) {
        NotificationCenter.default.addObserver(self, selector: #selector(nodeConfigured), name: Notification.Name.FNNodeConfiguredNotification, object:nil)

        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { 
            // wait until java is properly installed before continuing, but
            // don't repeatedly prompt the user to install it
            while !self.javaInstalled {
                if !self.javaPromptShown {
                    self.javaPromptShown = true
                    self.promptForJavaInstallation()
                    self.updateProgress(FNInstallerProgress.javaInstalling)
                }
                Thread.sleep(forTimeInterval: 1)
                continue
            }
            // Java is now installed, continue installation
            self.updateProgress(FNInstallerProgress.javaFound)
            let t = DispatchTime.now() + Double((1 * Int64(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: t, execute: {
                self.copyNodeToFileURL(installLocation)
                self.setupNodeAtFileURL(installLocation)
            })
        })
    }

    // MARK: - Step 2: Copy files

    func copyNodeToFileURL(_ installLocation:URL!) {
        self.updateProgress(FNInstallerProgress.copyingFiles)
        self.appendToInstallLog("Starting installation")
        let bundledNode:URL! = Bundle.main.url(forResource: "Bundled Node", withExtension:nil)
        let fileManager:FileManager! = FileManager()  
        if fileManager.fileExists(atPath: installLocation.path, isDirectory:nil) {
            self.appendToInstallLog("Removing existing files at: \(installLocation.path)")
            do {
                try fileManager.removeItem(at: installLocation)
            }
            catch let removeError as NSError {
                self.appendToInstallLog("Error removing existing files \(removeError.code): \(removeError.localizedDescription)")
                self.stateDelegate.installerDidFailWithLog(self.installLog.string)
                return
            }
        }
        self.appendToInstallLog("Copying files to \(installLocation.path)")

        do {
            try fileManager.copyItem(at: bundledNode, to:installLocation)
        }
        catch let copyError as NSError {
            self.appendToInstallLog("File copy error \(copyError.code): \(copyError.localizedDescription)")
            self.stateDelegate.installerDidFailWithLog(self.installLog.string)
            return
        }
        self.appendToInstallLog("Copy finished")
        self.updateProgress(FNInstallerProgress.copiedFiles)
    }

    // MARK: - Step 3: Set up node and find available ports

    func setupNodeAtFileURL(_ installLocation:URL!) {
        self.updateProgress(FNInstallerProgress.setupPorts)
        self.appendToInstallLog("Running setup script")
        let t = DispatchTime.now() + Double((1 * Int64(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).asyncAfter(deadline: t, execute: {

            let pipe:Pipe! = Pipe()
            let stdOutHandle:FileHandle! = pipe.fileHandleForReading
            stdOutHandle.readabilityHandler = { (fileHandle:FileHandle!) in 
                let data:Data! = fileHandle.readDataToEndOfFile()
                let str:String! = String(data:data, encoding:String.Encoding.utf8)
                self.appendToInstallLog(str)
            }

            let scriptTask:Process! = Process()
            scriptTask.currentDirectoryPath = installLocation.path
            scriptTask.launchPath = installLocation.appendingPathComponent("bin/setup.sh").path
            scriptTask.standardOutput = pipe

            var env = ProcessInfo.processInfo.environment
            
            env["INSTALL_PATH"] = installLocation.path
            env["LANG_SHORTCODE"] = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String
            
            self.appendToInstallLog("Checking for available ports")
            
            env["FPROXY_PORT"] = self.availableFProxyPort()
            env["FCP_PORT"] = self.availableFCPPort()

            scriptTask.environment = env

            scriptTask.launch()
            scriptTask.waitUntilExit()

            let exitStatus = scriptTask.terminationStatus
            
            let t = DispatchTime.now() + Double(Int64(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: t, execute: {
                if exitStatus != 0 {
                    self.stateDelegate.installerDidFailWithLog(self.installLog.string)
                    return
                }
                self.updateProgress(FNInstallerProgress.startingNode)
                self.appendToInstallLog("Installer environment: \(env.description)")
                self.stateDelegate.installerDidCopyFiles()
            })
        })

    }

    // MARK: - Java helpers
    
    fileprivate var javaInstalled: Bool {
        get {
            let oraclePipe:Pipe! = Pipe()
            let oracleJRETask:Process! = Process()
            
            oracleJRETask.launchPath = "/usr/sbin/pkgutil"
            oracleJRETask.arguments = ["--pkgs=com.oracle.jre"]
            oracleJRETask.standardOutput = oraclePipe
            
            oracleJRETask.launch()
            oracleJRETask.waitUntilExit()
            
            if oracleJRETask.terminationStatus == 0 {
                return true
            }
            return false
        }
    }

    func promptForJavaInstallation() {
        DispatchQueue.main.async(execute: { 
            let installJavaAlert = NSAlert()

            installJavaAlert.messageText = NSLocalizedString("Java not found", comment: "String informing the user that Java was not found")
            installJavaAlert.informativeText = NSLocalizedString("Freenet requires Java, would you like to install it now?", comment: "String asking the user if they would like to install Java")

            installJavaAlert.addButton(withTitle: NSLocalizedString("Install Java", comment: "Button title"))
            installJavaAlert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))

            let button:Int = installJavaAlert.runModal()

            if button == NSAlertFirstButtonReturn {
                self.installOracleJRE()
            }
            else if button == NSAlertSecondButtonReturn {
                NSApp.terminate(self)
            }
        })
    }

    func installOracleJRE() {
        let oracleJREPath:String! = Bundle.main.path(forResource: "jre-8u66-macosx-x64", ofType:"dmg")
        NSWorkspace.shared().openFile(oracleJREPath)
    }

    // MARK: - Port test helpers
    
    func availableFCPPort() -> String? {
        for port in FNInstallDefaultFCPPort  ... (FNInstallDefaultFCPPort + 256)  {
            if self.testListenPort(port) {
                return String(port)
            }
        }
        return nil
    }

    func availableFProxyPort() -> String? {
        for port in FNInstallDefaultFProxyPort  ... (FNInstallDefaultFProxyPort + 256)  {
            if self.testListenPort(port) {
                return String(port)
            }
         }
        return nil
    }

    func testListenPort(_ port: Int) -> Bool {
        let listenSocket = GCDAsyncSocket(delegate: self, delegateQueue:DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default))

        do {
            try listenSocket.accept(onInterface: "localhost", port: UInt16(port))
        }
        catch let error as NSError {
            self.appendToInstallLog("Port \(port) unavailable: \(error.localizedDescription)")
            listenSocket.disconnect()
            return false
        }
        self.appendToInstallLog("Port \(port) available")
        listenSocket.disconnect()
        return true
    }

    // MARK: - Logging
    
    func appendToInstallLog(_ line: String, _ arguments: CVarArg...) -> Void {
        return withVaList(arguments) { args in
            let st:String! = String(format: line, arguments: arguments)
            let attr: NSMutableAttributedString! = NSMutableAttributedString(string: st)
            attr.append(NSAttributedString(string:"\n"))
            self.installLog.append(attr)
        }
    }

    // MARK: - Internal state

    func updateProgress(_ progress:FNInstallerProgress) {
        DispatchQueue.main.async(execute: {
            let factory = NIKFontAwesomeIconFactory()
            if progress.rawValue >= FNInstallerProgress.finished.rawValue {
                self.finishedStatus.image = factory.createImage(for: .checkCircle)
                self.finishedStatus.isHidden = false
                self.finishedTitle.isHidden = false        
            }

            if progress.rawValue >= FNInstallerProgress.startingNode.rawValue {
                self.startNodeStatus.image = factory.createImage(for: .clockO)
                self.startNodeStatus.isHidden = false
                self.startNodeTitle.isHidden = false        
            }

            if progress.rawValue >= FNInstallerProgress.startedNode.rawValue {
                self.startNodeStatus.image = factory.createImage(for: .checkCircle)
                self.startNodeStatus.isHidden = false
                self.startNodeTitle.isHidden = false        
            }

            if progress.rawValue >= FNInstallerProgress.setupPorts.rawValue {
                self.portsStatus.image = factory.createImage(for: .checkCircle)
                self.portsStatus.isHidden = false
                self.portsTitle.isHidden = false      
            }

            if progress.rawValue >= FNInstallerProgress.copyingFiles.rawValue {
                self.fileCopyStatus.image = factory.createImage(for: .clockO)
                self.fileCopyStatus.isHidden = false
                self.fileCopyTitle.isHidden = false     
            }

            if progress.rawValue >= FNInstallerProgress.copiedFiles.rawValue {
                self.fileCopyStatus.image = factory.createImage(for: .checkCircle)
                self.fileCopyStatus.isHidden = false
                self.fileCopyTitle.isHidden = false     
            }

            if progress.rawValue >= FNInstallerProgress.javaInstalling.rawValue {
                self.javaInstallationStatus.image = factory.createImage(for: .clockO)
                self.javaInstallationStatus.isHidden = false
                self.javaInstallationTitle.isHidden = false   
            }
            if progress.rawValue >= FNInstallerProgress.javaFound.rawValue {
                self.javaInstallationStatus.image = factory.createImage(for: .checkCircle)
                self.javaInstallationStatus.isHidden = false
                self.javaInstallationTitle.isHidden = false    
            }
        })
    }

    // MARK: - FNNodeStateProtocol methods

    func nodeStateUnknown(_ notification:Notification!) {

    }

    func nodeStateRunning(_ notification:Notification!) {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")

    }

    func nodeStateNotRunning(_ notification:Notification!) {

    }

    func nodeConfigured(_ notification:Notification!) {
        assert(Thread.current == Thread.main, "NOT RUNNING ON MAIN THREAD")
        self.updateProgress(FNInstallerProgress.startedNode)
        self.updateProgress(FNInstallerProgress.finished)
        self.appendToInstallLog("Installation finished")
        self.stateDelegate.installerDidFinish()
        NotificationCenter.default.removeObserver(self)
    }
}

extension InstallerProgressViewController: GCDAsyncSocketDelegate {

}
