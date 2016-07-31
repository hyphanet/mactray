/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import <XCTest/XCTest.h>

#import "FNConstants.h"
#import "FNHelpers.h"
#import "FNBrowser.h"

@interface FreenetTrayTests : XCTestCase

@end

@implementation FreenetTrayTests

+(void)setUp {
    // load factory defaults for node location variables, sourced from defaults.plist
    NSString *defaultsPlist = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
    NSLog(@"Defaults plist: %@", defaultsPlist);
    NSDictionary *defaultsPlistDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlist];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    [defaults registerDefaults:defaultsPlistDict];
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)test_enumerateInstalledWebBrowsers {
    NSArray<FNBrowser *> *browsers = [FNHelpers installedWebBrowsers];
    
    XCTAssertNotNil(browsers);
    for (FNBrowser *browser in browsers) {
        XCTAssertNotNil(browser);
        XCTAssertTrue(browser.class == FNBrowser.class);
        XCTAssertNotNil(browser.name);
        XCTAssertNotNil(browser.icon);
        XCTAssertNotNil(browser.url);
        XCTAssertNotNil(browser.executablePath);
        NSLog(@"Found: %@", [browser debugDescription]);
    }

}

-(void)test_userSelectedBrowser {
    NSString *userSelectedBrowser = [[NSUserDefaults standardUserDefaults] objectForKey:FNBrowserPreferenceKey];
    NSLog(@"userSelectedBrowser: %@", userSelectedBrowser);
    XCTAssertTrue([userSelectedBrowser isEqualToString:@"Safari"]);
    
}

-(void)test_createGist {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_createPaste"];

    [FNHelpers createGist:@"test" withTitle:@"test" success:^(NSURL *url) {
        XCTAssertNotNil(url);
        NSLog(@"URL: %@", url);
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Error: %@", error.localizedDescription);
    }];
    
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        if(error) {
            XCTFail(@"test_createPaste failed with error: %@", error);
        }
    }];
}


@end
