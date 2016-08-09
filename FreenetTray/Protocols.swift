/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation


protocol FNNodeStateProtocol {

    func nodeStateUnknown(notification: NSNotification)
    func nodeStateRunning(notification: NSNotification)
    func nodeStateNotRunning(notification: NSNotification)
}


protocol FNNodeStatsProtocol {

    func didReceiveNodeHello(notification: NSNotification)
    func didReceiveNodeStats(notification: NSNotification)
}


protocol FCPDelegate {

    func didDisconnect()
    func didReceiveNodeHello(nodeHello: [NSObject: AnyObject])
    func didReceiveNodeStats(nodeStats: [NSObject: AnyObject])
    func didReceiveUserAlert(nodeUserAlert: [NSObject: AnyObject])
}


protocol FCPDataSource {

    func nodeFCPURL() -> NSURL?
}


protocol FNInstallerDelegate {

    func userDidSelectInstallLocation(installURL: NSURL)
    func installerDidCopyFiles()
    func installerDidFinish()
    func installerDidFailWithLog(log: String)
}

protocol FNInstallerDataSource {


}