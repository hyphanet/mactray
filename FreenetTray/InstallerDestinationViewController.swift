/*
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Cocoa

extension FileManager {
    func isEmptyDirectoryAtURL(_ url: URL) -> Bool {
        do {
            return try (self.contentsOfDirectory(at: url, includingPropertiesForKeys:nil, options:[]).count <= 1)
        }
        catch {
            return false
        }
    }
}

class InstallerDestinationViewController: NSViewController, NSOpenSavePanelDelegate {

    var stateDelegate: FNInstallerDelegate!
    fileprivate var installPathIndicator: NSPathControl!
    
    override func awakeFromNib() {
        self.installPathIndicator.url = URL(fileURLWithPath: FNInstallDefaultLocation).standardizedFileURL
    }
    
    
    // MARK: - Interface actions

    func selectInstallLocation(_ sender: AnyObject) {

        let panel = NSOpenPanel()

        panel.delegate = self
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        let panelTitle:String! = NSLocalizedString("Select a location to install Freenet", comment: "Title of window")
        panel.title = panelTitle

        let promptString:String! = NSLocalizedString("Install here", comment: "Button title")
        panel.prompt = promptString
        panel.begin(completionHandler: { (result:Int) in 
            if result == NSFileHandlingPanelOKButton {
                self.installPathIndicator.url = panel.url
                self.stateDelegate.userDidSelectInstallLocation(panel.url!)
            }
        })
    }
    
    
    // MARK: - NSOpenPanelDelegate

    func panel(_ sender: Any, validate url: URL) throws {
        let existingInstallation = Helpers.validateNodeInstallationAtURL(url)
       
        if existingInstallation {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Freenet is already installed here", comment: "String informing the user that the selected location is an existing Freenet installation") ]

            throw NSError(domain: "org.freenetproject", code:0x1000, userInfo: errorInfo)
        }

        let fileManager = FileManager.default

        // check if the candidate installation path is actually writable
        if !fileManager.isWritableFile(atPath: url.path) {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Cannot install to this directory, write permission denied", comment: "String informing the user that they do not have permission to write to the selected directory") ]

            throw NSError(domain: "org.freenetproject", code:0x1001, userInfo: errorInfo)
        }

        // make sure the directory is empty, protects against users accidentally picking their home folder etc
        if !fileManager.isEmptyDirectoryAtURL(url) {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Directory is not empty", comment: "String informing the user that the selected directory is not empty") ]

            throw NSError(domain: "org.freenetproject", code:0x1002, userInfo: errorInfo)
        }
    }
}
