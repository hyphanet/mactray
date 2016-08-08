//
//  Browser.swift
//  FreenetTray
//
//  Created by steve on 8/7/16.
//
//

import Cocoa

@objc 
class Browser : NSObject {
    var url: NSURL
    var executablePath: String
    var name: String
    var icon: NSImage

    class func browserWithFileURL(fileURL: NSURL!) -> Browser {
        let browser = Browser(fileURL: fileURL)
        return browser
    }

    init(fileURL: NSURL) {
        self.url = fileURL
        let bundle:NSBundle! = NSBundle(URL: self.url)
        self.executablePath = bundle.executablePath!
        self.name = bundle.objectForInfoDictionaryKey(kCFBundleNameKey as String) as! String
        self.icon = NSWorkspace.sharedWorkspace().iconForFile(self.url.path!)
    }

    override var description: String {
        get {
            return self.name
        }
    }

    override var debugDescription: String {
        get {
            return String(format:"<%@>: %@", self.name, self.executablePath)
        }
    }

    func privateBrowsingFlag() -> String! {
        if (self.name == "Firefox") {
            return "--private"
        }
        else if (self.name == "Chrome") {
            return "--incognito"
        }
        else if (self.name == "Opera") {
            return "--newprivatetab"
        }    
        return ""
    }
}