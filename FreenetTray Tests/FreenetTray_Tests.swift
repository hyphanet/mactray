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
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["NSApplicationCrashOnExceptions": true, FNEnableNotificationsKey: true, FNBrowserPreferenceKey: "Safari", FNStartAtLaunchKey: true, FNNodeFirstLaunchKey: true])
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_userSelectedBrowser() {
        let userSelectedBrowser = UserDefaults.standard.object(forKey: FNBrowserPreferenceKey) as! String
        print("userSelectedBrowser: \(userSelectedBrowser)")
        XCTAssertTrue((userSelectedBrowser == "Safari"))

    }
    
    func test_browserList() {
        // using an expectation here because it can explicitly pass the test rather than looking for failures
        let expectation = self.expectation(description: "test_browserList")

        guard let browsers = Helpers.installedWebBrowsers() else {
            XCTFail("Browsers returned nil")
            return
        }
        for browser in browsers {
            // one of them should always be Safari, so we can test for it
            if browser.name == "Safari" {
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 5, handler:{ (error) in
            if error != nil {
                XCTFail("test_browserList failed with error: \(error)")
            }
        })
        
    }

    func test_createGist() {
        // NOTE: This test sometimes fails on CI servers, Github returns a 403 error.
        let expectation = self.expectation(description: "test_createPaste")

        Helpers.createGist("test", withTitle:"test", success:{ (url) in
            XCTAssertNotNil(url)
            NSLog("URL: %@", url)
            expectation.fulfill()
        }, failure:{ (error:NSError!) in 
            XCTFail("Error: \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 60.0, handler:{ (error) in
            if error != nil {
                XCTFail("test_createPaste failed with error: \(error)")
            }
        })
    }
    
}
