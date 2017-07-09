/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation


protocol FNNodeStateProtocol {

    func nodeStateUnknown(_ notification: Notification)
    func nodeStateRunning(_ notification: Notification)
    func nodeStateNotRunning(_ notification: Notification)
}


protocol FNNodeStatsProtocol {

    func didReceiveNodeHello(_ notification: Notification)
    func didReceiveNodeStats(_ notification: Notification)
}


protocol FCPDelegate {

    func didDisconnect()
    func didReceiveNodeHello(_ nodeHello: [AnyHashable: Any])
    func didReceiveNodeStats(_ nodeStats: [AnyHashable: Any])
    func didReceiveUserAlert(_ nodeUserAlert: [AnyHashable: Any])
}


protocol FCPDataSource {

    func nodeFCPURL() -> URL?
}


protocol FNInstallerDelegate {

    func userDidSelectInstallLocation(_ installURL: URL)
    func installerDidCopyFiles()
    func installerDidFinish()
    func installerDidFailWithLog(_ log: String)
}

protocol FNInstallerDataSource {


}
