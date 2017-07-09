/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation

class NodeConfig: NSObject {

    class func fromFile(_ configFile: URL) -> [String: String]? {

        if let configContents = try? String(contentsOfFile: configFile.path, encoding: String.Encoding.utf8) {
            return NodeConfig.parseKeyValueString(configContents)
        }
        return nil
    }

    class func parseKeyValueString(_ string: String) -> [String: String] {
        var config = [String: String]()
        let pattern = "^\\s*(.+?)\\s*=\\s*(.+)$"
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            
            string.enumerateLines { (line, stop) in
                let s = line as NSString

                let result: [NSTextCheckingResult] = regex.matches(in: line, range: NSRange(location: 0, length: s.length))
                
                if result.count == 0 {
                    return
                }
                
                if result[0].numberOfRanges < 3 {
                    return
                }
                
                let keyRange = result[0].rangeAt(1) // <-- !!
                let valueRange = result[0].rangeAt(2) // <-- !!
                
                let key = s.substring(with: keyRange)
                let value = s.substring(with: valueRange)

                config[key] = value
                
            }

            

        }
        
        return config
    }
}
