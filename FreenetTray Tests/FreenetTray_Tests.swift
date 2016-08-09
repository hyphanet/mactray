/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import XCTest

class FreenetTray_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults(["NSApplicationCrashOnExceptions": true, FNEnableNotificationsKey: true, FNBrowserPreferenceKey: "Safari", FNStartAtLaunchKey: true, FNNodeFirstLaunchKey: true])
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_userSelectedBrowser() {
        let userSelectedBrowser = NSUserDefaults.standardUserDefaults().objectForKey(FNBrowserPreferenceKey) as! String
        print("userSelectedBrowser: \(userSelectedBrowser)")
        XCTAssertTrue((userSelectedBrowser == "Safari"))

    }

    func test_createGist() {
        // NOTE: This test sometimes fails on CI servers, Github returns a 403 error.
        let expectation = self.expectationWithDescription("test_createPaste")

        Helpers.createGist("test", withTitle:"test", success:{ (url) in
            XCTAssertNotNil(url)
            NSLog("URL: %@", url)
            expectation.fulfill()
        }, failure:{ (error:NSError!) in 
            XCTFail("Error: \(error.localizedDescription)")
        })

        self.waitForExpectationsWithTimeout(60.0, handler:{ (error) in
            if error != nil {
                XCTFail("test_createPaste failed with error: \(error)")
            }
        })
    }
    
}
