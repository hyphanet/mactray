/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNSettingsWindowController.h"

#import "NSBundle+LoginItem.h"

#import "FNHelpers.h"

#import "FNNodeController.h"

#import "TrayIcon.h"

@interface FNSettingsWindowController ()

@end

@implementation FNSettingsWindowController
@dynamic validNodeFound;
@dynamic loginItem;

- (void)windowDidLoad {

}

-(void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSettingsWindow:) name:FNNodeShowSettingsWindow object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeStateUnknown:) name:FNNodeStateUnknownNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeStateRunning:) name:FNNodeStateRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeStateNotRunning:) name:FNNodeStateNotRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNodeHello:) name:FNNodeHelloReceivedNotification object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNodeStats:) name:FNNodeStatsReceivedNotification object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDisconnect) name:FNNodeFCPDisconnectedNotification object:nil];   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNodeFinderPanel:) name:FNNodeShowNodeFinderInSettingsWindow object:nil];
}

#pragma mark - Notification handlers 

-(void)showNodeFinderPanel:(NSNotification *)notification {
    [self selectNodeLocation:nil];
}

-(void)showSettingsWindow:(NSNotification *)notification {
    [self showWindow:nil];
}

#pragma mark - Dynamic properties

-(BOOL)isLoginItem {
    return [[NSBundle mainBundle] isLoginItem];
}

-(void)setLoginItem:(BOOL)state {
    if (state) {
        [[NSBundle mainBundle] addToLoginItems];
    }
    else {
        [[NSBundle mainBundle] removeFromLoginItems];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FNStartAtLaunchKey];
    }
}

-(BOOL)validNodeFound {
    BOOL valid = [FNHelpers validateNodeInstallationAtURL:self.nodeController.nodeLocation];
    return valid;
}

#pragma mark - Interface actions

-(IBAction)selectNodeLocation:(id)sender {
    NSOpenPanel *openpanel = [NSOpenPanel openPanel];

    [openpanel setDelegate:self];
    [openpanel setCanChooseFiles:NO];
    [openpanel setAllowsMultipleSelection:NO];
    [openpanel setCanChooseDirectories:YES];
    NSString *panelTitle = NSLocalizedString(@"Find your Freenet installation", @"Title of window");
    [openpanel setTitle:panelTitle];
 
    NSString *promptString = NSLocalizedString(@"Select Freenet installation", @"Button title");
    [openpanel setPrompt:promptString];
    [openpanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            self.nodeController.nodeLocation = openpanel.URL;
            self.nodePathDisplay.URL = openpanel.URL;
            [self showWindow:nil];
        }
    }];
    
}

-(IBAction)changeTrayIconColor:(id)sender {
    [TrayIcon refreshColors];
}

-(IBAction)uninstallFreenet:(id)sender {
    [FNHelpers displayUninstallAlert];
}

#pragma mark - NSOpenPanelDelegate

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    BOOL valid = [FNHelpers validateNodeInstallationAtURL:url];
    if (!valid) {
        NSDictionary *errorInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Not a valid Freenet installation", @"String informing the user that the selected location is not a Freenet installation") };
    
        *outError = [NSError errorWithDomain:@"org.freenetproject" code:0x1000 userInfo:errorInfo];
    }
    return valid;
}

#pragma mark - FNNodeStateProtocol methods

-(void)nodeStateUnknown:(NSNotification*)notification {
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"NOT RUNNING ON MAIN THREAD");
    [self willChangeValueForKey:@"validNodeFound"];
    [self didChangeValueForKey:@"validNodeFound"];
    self.nodeRunningStatusView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
}

-(void)nodeStateRunning:(NSNotification*)notification {
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"NOT RUNNING ON MAIN THREAD");
    [self willChangeValueForKey:@"validNodeFound"];
    [self didChangeValueForKey:@"validNodeFound"];
    self.nodeRunningStatusView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
}

-(void)nodeStateNotRunning:(NSNotification*)notification {
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"NOT RUNNING ON MAIN THREAD");
    [self willChangeValueForKey:@"validNodeFound"];
    [self didChangeValueForKey:@"validNodeFound"];
    self.nodeRunningStatusView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
}

#pragma mark - FNNodeStatsProtocol methods

-(void)didReceiveNodeHello:(NSNotification*)notification {
    NSDictionary *nodeHello = notification.object;
    NSString *build = nodeHello[@"Build"];
    if (build) {
        self.nodeBuildField.stringValue = build;
    }
    self.fcpStatusView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
}

-(void)didReceiveNodeStats:(NSNotification*)notification {
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"NOT RUNNING ON MAIN THREAD");
    self.fcpStatusView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
}

#pragma mark - FNFCPWrapperDelegate methods

-(void)didDisconnect {
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"NOT RUNNING ON MAIN THREAD");
    self.fcpStatusView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
    self.nodeBuildField.stringValue = @"";
}

@end
