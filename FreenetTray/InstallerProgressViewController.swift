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

    private var javaInstallationTitle: NSTextField!

    private var javaInstallationStatus: NIKFontAwesomeImageView!

    private var fileCopyTitle: NSTextField!

    private var fileCopyStatus: NIKFontAwesomeImageView!

    private var portsTitle: NSTextField!

    private var portsStatus: NIKFontAwesomeImageView!

    private var startNodeTitle: NSTextField!

    private var startNodeStatus: NIKFontAwesomeImageView!

    private var finishedTitle: NSTextField!

    private var finishedStatus: NIKFontAwesomeImageView!

    private var installLog: NSMutableAttributedString!
    
    var stateDelegate:FNInstallerDelegate!
    
    private var javaPromptShown: Bool = false
 
    
    
    
    
    override func awakeFromNib() {
        self.updateProgress(FNInstallerProgress.Unknown)
        self.installLog = NSMutableAttributedString()
        self.javaPromptShown = false
    }
    
    // MARK: - Step 1: Entry point

    func installNodeAtFileURL(installLocation:NSURL!) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(nodeConfigured), name:FNNodeConfiguredNotification, object:nil)

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { 
            // wait until java is properly installed before continuing, but
            // don't repeatedly prompt the user to install it
            while !self.javaInstalled {
                if !self.javaPromptShown {
                    self.javaPromptShown = true
                    self.promptForJavaInstallation()
                    self.updateProgress(FNInstallerProgress.JavaInstalling)
                }
                NSThread.sleepForTimeInterval(1)
                continue
            }
            // Java is now installed, continue installation
            self.updateProgress(FNInstallerProgress.JavaFound)
            let t = dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC)))
            dispatch_after(t, dispatch_get_main_queue(), {
                self.copyNodeToFileURL(installLocation)
                self.setupNodeAtFileURL(installLocation)
            })
        })
    }

    // MARK: - Step 2: Copy files

    func copyNodeToFileURL(installLocation:NSURL!) {
        self.updateProgress(FNInstallerProgress.CopyingFiles)
        self.appendToInstallLog("Starting installation")
        let bundledNode:NSURL! = NSBundle.mainBundle().URLForResource("Bundled Node", withExtension:nil)
        let fileManager:NSFileManager! = NSFileManager()  
        if fileManager.fileExistsAtPath(installLocation.path!, isDirectory:nil) {
            self.appendToInstallLog("Removing existing files at: \(installLocation.path)")
            do {
                try fileManager.removeItemAtURL(installLocation)
            }
            catch let removeError as NSError {
                self.appendToInstallLog("Error removing existing files \(removeError.code): \(removeError.localizedDescription)")
                self.stateDelegate.installerDidFailWithLog(self.installLog.string)
                return
            }
        }
        self.appendToInstallLog("Copying files to \(installLocation.path)")

        do {
            try fileManager.copyItemAtURL(bundledNode, toURL:installLocation)
        }
        catch let copyError as NSError {
            self.appendToInstallLog("File copy error \(copyError.code): \(copyError.localizedDescription)")
            self.stateDelegate.installerDidFailWithLog(self.installLog.string)
            return
        }
        self.appendToInstallLog("Copy finished")
        self.updateProgress(FNInstallerProgress.CopiedFiles)
    }

    // MARK: - Step 3: Set up node and find available ports

    func setupNodeAtFileURL(installLocation:NSURL!) {
        self.updateProgress(FNInstallerProgress.SetupPorts)
        self.appendToInstallLog("Running setup script")
        let t = dispatch_time(DISPATCH_TIME_NOW, (1 * Int64(NSEC_PER_SEC)))
        dispatch_after(t, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

            let pipe:NSPipe! = NSPipe()
            let stdOutHandle:NSFileHandle! = pipe.fileHandleForReading
            stdOutHandle.readabilityHandler = { (fileHandle:NSFileHandle!) in 
                let data:NSData! = fileHandle.readDataToEndOfFile()
                let str:String! = String(data:data, encoding:NSUTF8StringEncoding)
                self.appendToInstallLog(str)
            }

            let scriptTask:NSTask! = NSTask()
            scriptTask.currentDirectoryPath = installLocation.path!
            scriptTask.launchPath = installLocation.URLByAppendingPathComponent("bin/setup.sh").path
            scriptTask.standardOutput = pipe

            var env = [String: String]()
            env.merge(NSProcessInfo.processInfo().environment)
            
            env["INSTALL_PATH"] = installLocation.path
            env["LANG_SHORTCODE"] = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String
            
            self.appendToInstallLog("Checking for available ports")
            
            env.merge(self.availablePorts())
            
            scriptTask.environment = env

            scriptTask.launch()
            scriptTask.waitUntilExit()

            let exitStatus = scriptTask.terminationStatus
            
            let t = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
            
            dispatch_after(t, dispatch_get_main_queue(), {
                if exitStatus != 0 {
                    self.stateDelegate.installerDidFailWithLog(self.installLog.string)
                    return
                }
                self.updateProgress(FNInstallerProgress.StartingNode)
                self.appendToInstallLog("Installer environment: \(env.description)")
                self.stateDelegate.installerDidCopyFiles()
            })
        })

    }

    // MARK: - Java helpers
    
    private var javaInstalled: Bool {
        get {
            let oraclePipe:NSPipe! = NSPipe()
            let oracleJRETask:NSTask! = NSTask()
            
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
        dispatch_async(dispatch_get_main_queue(), { 
            let installJavaAlert = NSAlert()

            installJavaAlert.messageText = NSLocalizedString("Java not found", comment: "String informing the user that Java was not found")
            installJavaAlert.informativeText = NSLocalizedString("Freenet requires Java, would you like to install it now?", comment: "String asking the user if they would like to install Java")

            installJavaAlert.addButtonWithTitle(NSLocalizedString("Install Java", comment: "Button title"))
            installJavaAlert.addButtonWithTitle(NSLocalizedString("Quit", comment: ""))

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
        let oracleJREPath:String! = NSBundle.mainBundle().pathForResource("jre-8u66-macosx-x64", ofType:"dmg")
        NSWorkspace.sharedWorkspace().openFile(oracleJREPath)
    }

    // MARK: - Port test helpers

    func availablePorts() -> [String: String] {
        var availablePorts = [String: String]()
        // fproxy ports
        for port in FNInstallDefaultFProxyPort  ... (FNInstallDefaultFProxyPort + 256)  {
            if self.testListenPort(port) {
                availablePorts["FPROXY_PORT"] = String(port)
                break
            }
         }
        // fcp ports
        for port in FNInstallDefaultFCPPort  ... (FNInstallDefaultFCPPort + 256)  {
            if self.testListenPort(port) {
                availablePorts["FCP_PORT"] = String(port)
                break
            }
         }
        return availablePorts
    }

    func testListenPort(port: Int) -> Bool {
        let listenSocket = GCDAsyncSocket(delegate: self, delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        do {
            try listenSocket.acceptOnInterface("localhost", port: UInt16(port))
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
    
    func appendToInstallLog(line: String, _ arguments: CVarArgType...) -> Void {
        return withVaList(arguments) { args in
            let st:String! = String(format: line, arguments: arguments)
            let attr: NSMutableAttributedString! = NSMutableAttributedString(string: st)
            attr.appendAttributedString(NSAttributedString(string:"\n"))
            self.installLog.appendAttributedString(attr)
        }
    }

    // MARK: - Internal state

    func updateProgress(progress:FNInstallerProgress) {
        dispatch_async(dispatch_get_main_queue(), {
            let factory = NIKFontAwesomeIconFactory()
            if progress.rawValue >= FNInstallerProgress.Finished.rawValue {
                self.finishedStatus.image = factory.createImageForIcon(.CheckCircle)
                self.finishedStatus.hidden = false
                self.finishedTitle.hidden = false        
            }

            if progress.rawValue >= FNInstallerProgress.StartingNode.rawValue {
                self.startNodeStatus.image = factory.createImageForIcon(.ClockO)
                self.startNodeStatus.hidden = false
                self.startNodeTitle.hidden = false        
            }

            if progress.rawValue >= FNInstallerProgress.StartedNode.rawValue {
                self.startNodeStatus.image = factory.createImageForIcon(.CheckCircle)
                self.startNodeStatus.hidden = false
                self.startNodeTitle.hidden = false        
            }

            if progress.rawValue >= FNInstallerProgress.SetupPorts.rawValue {
                self.portsStatus.image = factory.createImageForIcon(.CheckCircle)
                self.portsStatus.hidden = false
                self.portsTitle.hidden = false      
            }

            if progress.rawValue >= FNInstallerProgress.CopyingFiles.rawValue {
                self.fileCopyStatus.image = factory.createImageForIcon(.ClockO)
                self.fileCopyStatus.hidden = false
                self.fileCopyTitle.hidden = false     
            }

            if progress.rawValue >= FNInstallerProgress.CopiedFiles.rawValue {
                self.fileCopyStatus.image = factory.createImageForIcon(.CheckCircle)
                self.fileCopyStatus.hidden = false
                self.fileCopyTitle.hidden = false     
            }

            if progress.rawValue >= FNInstallerProgress.JavaInstalling.rawValue {
                self.javaInstallationStatus.image = factory.createImageForIcon(.ClockO)
                self.javaInstallationStatus.hidden = false
                self.javaInstallationTitle.hidden = false   
            }
            if progress.rawValue >= FNInstallerProgress.JavaFound.rawValue {
                self.javaInstallationStatus.image = factory.createImageForIcon(.CheckCircle)
                self.javaInstallationStatus.hidden = false
                self.javaInstallationTitle.hidden = false    
            }
        })
    }

    // MARK: - FNNodeStateProtocol methods

    func nodeStateUnknown(notification:NSNotification!) {

    }

    func nodeStateRunning(notification:NSNotification!) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")

    }

    func nodeStateNotRunning(notification:NSNotification!) {

    }

    func nodeConfigured(notification:NSNotification!) {
        assert(NSThread.currentThread() == NSThread.mainThread(), "NOT RUNNING ON MAIN THREAD")
        self.updateProgress(FNInstallerProgress.StartedNode)
        self.updateProgress(FNInstallerProgress.Finished)
        self.appendToInstallLog("Installation finished")
        self.stateDelegate.installerDidFinish()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension InstallerProgressViewController: GCDAsyncSocketDelegate {

}
