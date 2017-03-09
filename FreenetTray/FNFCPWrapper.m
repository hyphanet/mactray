/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>
    
    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNFCPWrapper.h"

#import <dispatch/dispatch.h>

#pragma mark - Node state

typedef NS_ENUM(NSInteger, FCPConnectionState) {
    FCPConnectionStateDisconnected    =  0,
    FCPConnectionStateConnected       =  1,
    FCPConnectionStateReady           =  2
};


typedef NS_ENUM(NSInteger, FCPResponseState) {
    FCPResponseStateUnknown         =  0,
    FCPResponseStateReady           =  1,
    FCPResponseStateHeader          =  2,
    FCPResponseStateData            =  3

};

@interface FNFCPWrapper ()
@property GCDAsyncSocket *nodeSocket;
@property enum FCPConnectionState connectionState;
@property enum FCPResponseState responseState;
@property NSMutableDictionary *response;
@property BOOL commandExecuting;
@property BOOL isWatchingFeeds;

-(void)sendFCPMessage:(NSString *)message;
-(NSDictionary *)parseFCPResponse:(NSData *)data;
-(NSString *)parseFCPHeader:(NSData *)data;

@end

@implementation FNFCPWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.connectionState = FCPConnectionStateDisconnected;
        self.responseState = FCPResponseStateReady;
        self.response = [NSMutableDictionary new];
        self.isWatchingFeeds = NO;
        self.commandExecuting = NO;
        self.nodeSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

-(void)nodeStateLoop {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
            switch (self.connectionState) {
                case FCPConnectionStateDisconnected: {
                    NSURL *nodeFCPURL = [self.dataSource nodeFCPURL];
                    if (!nodeFCPURL) {
                        [NSThread sleepForTimeInterval:1];
                        continue;
                    }
                    NSError *fcpConnectionError;
                    [self.nodeSocket connectToHost:nodeFCPURL.host onPort:nodeFCPURL.port.integerValue withTimeout:5 error:&fcpConnectionError];
                    if (fcpConnectionError) {
                        // don't need to do anything about this here
                    }
                    break;
                }
                case FCPConnectionStateConnected: {
                    if (!self.commandExecuting) {
                        [self clientHello];
                        self.commandExecuting = NO;
                    }

                    break;
                }
                case FCPConnectionStateReady: {
                    if (!self.commandExecuting) {
                        if (!self.isWatchingFeeds) {
                            [self watchFeeds:YES];
                            self.isWatchingFeeds = YES;
                            self.commandExecuting = NO;

                        }
                        else {
                            [self getNode];
                            self.commandExecuting = NO;
                        }
                    }
                    break;
                }
                default: {
                    break;
                }
            }
            [NSThread sleepForTimeInterval:1];
        }
        
    });
}

-(void)clientHello {
    NSString *lf = [[NSString alloc] initWithData:[GCDAsyncSocket LFData] encoding:NSUTF8StringEncoding];
    NSMutableString *clientHello = [NSMutableString new];
    [clientHello appendString:@"ClientHello"];
    [clientHello appendString:lf];
    [clientHello appendString:@"Name=FreenetTray"];
    [clientHello appendString:lf];
    [clientHello appendString:@"ExpectedVersion=2.0"];
    [clientHello appendString:lf];
    [clientHello appendString:@"EndMessage"];
    [clientHello appendString:lf];
    [self sendFCPMessage:clientHello];
}

-(void)getNode {
    NSString *lf = [[NSString alloc] initWithData:[GCDAsyncSocket LFData] encoding:NSUTF8StringEncoding];
    NSMutableString *getNode = [NSMutableString new];
    [getNode appendString:@"GetNode"];
    [getNode appendString:lf];
    [getNode appendString:@"WithVolatile=true"];
    [getNode appendString:lf];
    [getNode appendString:@"EndMessage"];
    [getNode appendString:lf];
    [self sendFCPMessage:getNode];
}

-(void)watchFeeds:(BOOL)enabled {
    NSString *lf = [[NSString alloc] initWithData:[GCDAsyncSocket LFData] encoding:NSUTF8StringEncoding];
    NSMutableString *watchFeeds = [NSMutableString new];
    [watchFeeds appendString:@"WatchFeeds"];
    [watchFeeds appendString:lf];
    [watchFeeds appendString:@"Enabled=true"];
    [watchFeeds appendString:lf];
    [watchFeeds appendString:@"EndMessage"];
    [watchFeeds appendString:lf];
    [self sendFCPMessage:watchFeeds];
}

#pragma mark - Message and response handling

-(void)sendFCPMessage:(NSString *)message {
    [self.nodeSocket writeData:[message dataUsingEncoding:NSUTF8StringEncoding] withTimeout:5 tag:-1];
    [self.nodeSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:5 tag:-1];
}

-(NSDictionary *)parseFCPResponse:(NSData *)data {
    NSString *rawResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *nodeResponse = [NSMutableDictionary dictionary];
    
    for (NSString *keyValuePair in [rawResponse componentsSeparatedByString:@"\n"]) {
        NSArray *pair = [keyValuePair componentsSeparatedByString:@"="];
        if ([pair count] != 2) {
            // handle keys with no value by adding empty one
            if ([pair[0] length] > 0) {
                nodeResponse[pair[0]] = @"";
            }
            continue;
        }
        nodeResponse[pair[0]] = pair[1];
    }
    return nodeResponse;
}

-(NSString *)parseFCPHeader:(NSData *)data {
    NSString *rawResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return [rawResponse stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}


#pragma mark - GCDAsyncSocketDelegate methods

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connectionState = FCPConnectionStateConnected;
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.connectionState = FCPConnectionStateDisconnected;
    self.responseState = FCPResponseStateReady;
    [self.delegate didDisconnect];
    self.response = [NSMutableDictionary new];
    self.isWatchingFeeds = NO;
    self.commandExecuting = NO;
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    switch (self.responseState) {
        case FCPResponseStateReady: {
            self.response = [NSMutableDictionary new];

            self.response[@"Command"] = [self parseFCPHeader:data];
            self.responseState = FCPResponseStateHeader;
            [self.nodeSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:5 tag:-1];
            break;
        }
        case FCPResponseStateHeader: {
            NSDictionary *resp = [self parseFCPResponse:data];
            [self.response addEntriesFromDictionary:resp];
            if ([resp.allKeys.firstObject isEqualToString:@"Data"]) {
                NSString *length = self.response[@"DataLength"];
                self.responseState = FCPResponseStateData;
                [self.nodeSocket readDataToLength:length.integerValue withTimeout:5 tag:-1];
            }
            else if ([resp.allKeys.firstObject isEqualToString:@"EndMessage"]) {
                self.responseState = FCPResponseStateReady;
                [self processFCPResponse];
            }
            else {
                [self.nodeSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:5 tag:-1];
            }
            break;
        }
        case FCPResponseStateData: {
            NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            self.response[@"Data"] = message;
            [self processFCPResponse];
            self.responseState = FCPResponseStateReady;
            break;
        }
        default:
            DebugLog(@"############## WARNING ##################");
            DebugLog(@"UNPROCESSED PACKET RECEIVED:");
            NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DebugLog(@"%@", message);
            DebugLog(@"############## WARNING ##################");

            self.responseState = FCPResponseStateReady;
            break;
    }
}

-(void)processFCPResponse {
    if ([self.response[@"Command"] isEqualToString:@"NodeHello"]) {
        self.connectionState = FCPConnectionStateReady;
        if (self.delegate != nil) {
            [self.delegate didReceiveNodeHello:self.response];
        }
    }
    else  if ([self.response[@"Command"] isEqualToString:@"NodeData"]) {
        if (self.delegate != nil) {
            [self.delegate didReceiveNodeStats:self.response];
        }
    }
    else  if ([self.response[@"Command"] isEqualToString:@"Feed"]) {
        if (self.delegate != nil) {
            [self.delegate didReceiveUserAlert:self.response];
        }
    }
    else  if ([self.response[@"Command"] isEqualToString:@"TextFeed"]) {
        if (self.delegate != nil) {
            [self.delegate didReceiveUserAlert:self.response];
        }
    }
    else {
        DebugLog(@"Unknown: %@", self.response);
    }
    self.commandExecuting = NO;
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag  {

}



@end
