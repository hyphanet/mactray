/* 
    Copyright (C) 2016 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

import Foundation
import CocoaAsyncSocket

enum FCPConnectionState: Int {
    case Disconnected
    case Connected
    case Ready
}


enum FCPResponseState: Int {
    case Unknown
    case Ready
    case Header
    case Data
}


class FCP: NSObject, GCDAsyncSocketDelegate {

    var delegate: FCPDelegate!
    var dataSource: FCPDataSource!
    
    private var nodeSocket: GCDAsyncSocket!
    private var connectionState: FCPConnectionState = .Disconnected
    private var responseState: FCPResponseState = .Ready
    private var response = [String: AnyObject]()
    private var commandExecuting: Bool = false
    private var isWatchingFeeds: Bool = false
    private let LineFeed = String(data: GCDAsyncSocket.LFData(), encoding: NSUTF8StringEncoding)!

    override init() {
        super.init()
        self.isWatchingFeeds = false
        self.commandExecuting = false
        self.nodeSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
    }

    func nodeStateLoop() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { 
            while true {
                switch (self.connectionState) { 
                    case FCPConnectionState.Disconnected: 
                        guard let nodeFCPURL = self.dataSource.nodeFCPURL(),
                                  port = nodeFCPURL.port?.integerValue,
                                  host = nodeFCPURL.host else {
                            NSThread.sleepForTimeInterval(1)
                            continue
                        }
                        do {
                            try self.nodeSocket.connectToHost(host, onPort:UInt16(port), withTimeout:5)
                        }
                        catch _ as NSError {
                        
                        }
                    case FCPConnectionState.Connected: 
                        if !self.commandExecuting {
                            self.clientHello()
                            self.commandExecuting = false
                        }
                    case FCPConnectionState.Ready: 
                        if !self.commandExecuting {
                            if !self.isWatchingFeeds {
                                self.watchFeeds(true)
                                self.isWatchingFeeds = true
                                self.commandExecuting = false

                            }
                            else {
                                self.getNode()
                                self.commandExecuting = false
                            }
                        }
                }
                NSThread.sleepForTimeInterval(1)
            }

        })
    }

    func clientHello() {
        var clientHello = String()
        clientHello += "ClientHello"
        clientHello += LineFeed
        clientHello += "Name=FreenetTray"
        clientHello += LineFeed
        clientHello += "ExpectedVersion=2.0"
        clientHello += LineFeed
        clientHello += "EndMessage"
        clientHello += LineFeed
        self.sendFCPMessage(clientHello)
    }

    func getNode() {
        var getNode = String()
        getNode += "GetNode"
        getNode += LineFeed
        getNode += "WithVolatile=true"
        getNode += LineFeed
        getNode += "EndMessage"
        getNode += LineFeed
        self.sendFCPMessage(getNode)
    }

    func watchFeeds(enabled: Bool) {
        var watchFeeds = String()
        watchFeeds += "WatchFeeds"
        watchFeeds += LineFeed
        watchFeeds += "Enabled=true"
        watchFeeds += LineFeed
        watchFeeds += "EndMessage"
        watchFeeds += LineFeed
        self.sendFCPMessage(watchFeeds)
    }

    // MARK: - Message and response handling

    func sendFCPMessage(message: String) {
        guard let data = message.dataUsingEncoding(NSUTF8StringEncoding) else {
            return
        }
        self.nodeSocket.writeData(data, withTimeout:5, tag:-1)
        self.nodeSocket.readDataToData(GCDAsyncSocket.LFData(), withTimeout:5, tag:-1)
    }

    func parseFCPResponse(data:NSData) -> [String: AnyObject] {
        var nodeResponse = [String: AnyObject]()

        guard let rawResponse = String(data: data, encoding: NSUTF8StringEncoding) else {
            // failed to
            return nodeResponse
        }


        for keyValuePair in rawResponse.componentsSeparatedByString("\n") {
            let pair = keyValuePair.componentsSeparatedByString("=")
            if pair.count != 2 {
                // handle keys with no value by adding empty one
                if pair[0].characters.count > 0 {
                    nodeResponse[pair[0]] = ""
                }
                continue
            }
            nodeResponse[pair[0]] = pair[1]
         }
        return nodeResponse
    }

    func parseFCPHeader(data: NSData) -> String? {
        guard let rawResponse = String(data: data, encoding: NSUTF8StringEncoding) else {
            return nil
        }
        return rawResponse.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }


    // MARK: - GCDAsyncSocketDelegate methods

    func socket(sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        self.connectionState = FCPConnectionState.Connected
    }

    func socketDidDisconnect(sock: GCDAsyncSocket, withError err: NSError?) {
        self.connectionState = FCPConnectionState.Disconnected
        self.responseState = FCPResponseState.Ready
        self.delegate.didDisconnect()
        self.response = [String: AnyObject]()
        self.isWatchingFeeds = false
        self.commandExecuting = false
    }

    func socket(sock: GCDAsyncSocket, didReadData data: NSData, withTag tag: Int) {
        switch (self.responseState) { 
            case .Ready:
                self.response = [String: AnyObject]()

                self.response["Command"] = self.parseFCPHeader(data)
                self.responseState = .Header
                self.nodeSocket.readDataToData(GCDAsyncSocket.LFData(), withTimeout:5, tag:-1)
                break

            case .Header:
                let resp = self.parseFCPResponse(data)
                self.response = self.response.merge(resp)
                let type = resp.keys.first
                if (type == "Data") {
                    let length = self.response["DataLength"] as! String
                    self.responseState = .Data
                    self.nodeSocket.readDataToLength(UInt(length)!, withTimeout:5, tag:-1)
                }
                else if (type == "EndMessage") {
                    self.responseState = .Ready
                    self.processFCPResponse()
                }
                else {
                    self.nodeSocket.readDataToData(GCDAsyncSocket.LFData(), withTimeout:5, tag:-1)
                }
                break

            case .Data:
                let message:String! = String(data:data, encoding:NSUTF8StringEncoding)
                self.response["Data"] = message
                self.processFCPResponse()
                self.responseState = .Ready
                break

            default:
                print("############## WARNING ##################")
                print("UNPROCESSED PACKET RECEIVED:")
                let message = String(data:data, encoding:NSUTF8StringEncoding)
                print("\(message)")
                print("############## WARNING ##################")

                self.responseState = .Ready
                break
        }
    }

    func processFCPResponse() {
        guard let delegate = self.delegate else {
            return
        }
        guard let command = self.response["Command"] as? String else {
            return
        }
        if (command == "NodeHello") {
            self.connectionState = .Ready
            delegate.didReceiveNodeHello(self.response)
        }
        else if (command == "NodeData") {
            delegate.didReceiveNodeStats(self.response)
            
        }
        else if (command == "Feed") {
            delegate.didReceiveUserAlert(self.response)
            
        }
        else if (command == "TextFeed") {
            delegate.didReceiveUserAlert(self.response)
        }
        else {
            print("Unknown: \(self.response)")
        }
        self.commandExecuting = false
    }
}