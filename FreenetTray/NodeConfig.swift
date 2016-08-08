/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation
import RegexKitLite

class NodeConfig: NSObject {

    class func fromFile(configFile: NSURL) -> NSDictionary? {

        if let configContents = try? String(contentsOfFile: configFile.path!, encoding: NSUTF8StringEncoding) {
            return NodeConfig.parseKeyValueString(configContents)
        }
        return nil
    }

    class func parseKeyValueString(string: String) -> [String: String] {
        var config = [String: String]()
        let regex = "\\s*(.+?)\\s*=\\s*(.+)"
        string.enumerateLines { (line, stop) in
            if line.isMatchedByRegex("^\\s*$") {
                // whitespace line
            }
            else if line.isMatchedByRegex("^#") {
                // comment line
            }
            else if line.isMatchedByRegex(regex) {
                let captureArray = line.arrayOfCaptureComponentsMatchedByRegex(regex)
                if captureArray.count == 1 {
                    if let capture = captureArray[0] as? [String] {
                        if capture.count == 3 {
                            let key = capture[1]
                            let value = capture[2]
                            config[key] = value
                        }
                    }
                }
            }
        }
        return config
    }
}