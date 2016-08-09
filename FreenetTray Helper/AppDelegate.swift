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
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if NSWorkspace.sharedWorkspace().launchApplication("FreenetTray") {
            NSLog("FreenetTray launched")
        } else {
            NSLog("Failed to launch FreenetTray")
        }
        NSApplication.sharedApplication().terminate(self)
    }
}

