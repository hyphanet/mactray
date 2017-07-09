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
    case disconnected
    case connected
    case ready
}


enum FCPResponseState: Int {
    case unknown
    case ready
    case header
    case data
}


class FCP: NSObject, GCDAsyncSocketDelegate {

    var delegate: FCPDelegate!
    var dataSource: FCPDataSource!
    
    fileprivate var nodeSocket: GCDAsyncSocket!
    fileprivate var connectionState: FCPConnectionState = .disconnected
    fileprivate var responseState: FCPResponseState = .ready
    fileprivate var response = [String: String]()
    fileprivate var commandExecuting: Bool = false
    fileprivate var isWatchingFeeds: Bool = false
    fileprivate let LineFeed = String(data: GCDAsyncSocket.lfData(), encoding: String.Encoding.utf8)!

    override init() {
        super.init()
        self.isWatchingFeeds = false
        self.commandExecuting = false
        self.nodeSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }

    func nodeStateLoop() {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { 
            while true {
                switch (self.connectionState) { 
                    case FCPConnectionState.disconnected: 
                        guard let nodeFCPURL = self.dataSource.nodeFCPURL(),
                                  let port = (nodeFCPURL as NSURL).port?.intValue,
                                  let host = nodeFCPURL.host else {
                            Thread.sleep(forTimeInterval: 1)
                            continue
                        }
                        do {
                            try self.nodeSocket.connect(toHost: host, onPort:UInt16(port), withTimeout:5)
                        }
                        catch _ as NSError {
                        
                        }
                    case FCPConnectionState.connected: 
                        if !self.commandExecuting {
                            self.clientHello()
                            self.commandExecuting = false
                        }
                    case FCPConnectionState.ready: 
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
                Thread.sleep(forTimeInterval: 1)
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

    func watchFeeds(_ enabled: Bool) {
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

    func sendFCPMessage(_ message: String) {
        guard let data = message.data(using: String.Encoding.utf8) else {
            return
        }
        self.nodeSocket.write(data, withTimeout:5, tag:-1)
        self.nodeSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout:5, tag:-1)
    }

    func parseFCPResponse(_ data: Data) -> [String: String] {
        var nodeResponse = [String: String]()

        guard let rawResponse = String(data: data, encoding: String.Encoding.utf8) else {
            // failed to
            return nodeResponse
        }


        for keyValuePair in rawResponse.components(separatedBy: "\n") {
            let pair = keyValuePair.components(separatedBy: "=")
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

    func parseFCPHeader(_ data: Data) -> String? {
        guard let rawResponse = String(data: data, encoding: String.Encoding.utf8) else {
            return nil
        }
        return rawResponse.trimmingCharacters(in: CharacterSet.newlines)
    }


    // MARK: - GCDAsyncSocketDelegate methods

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        self.connectionState = FCPConnectionState.connected
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        self.connectionState = FCPConnectionState.disconnected
        self.responseState = FCPResponseState.ready
        self.delegate.didDisconnect()
        self.response = [String: String]()
        self.isWatchingFeeds = false
        self.commandExecuting = false
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch (self.responseState) { 
            case .ready:
                self.response = [String: String]()

                self.response["Command"] = self.parseFCPHeader(data)
                self.responseState = .header
                self.nodeSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout:5, tag:-1)
                break

            case .header:
                let resp = self.parseFCPResponse(data)
                self.response = self.response.merge(resp)
                let type = resp.keys.first
                if (type == "Data") {
                    let length = self.response["DataLength"]
                    self.responseState = .data
                    self.nodeSocket.readData(toLength: UInt(length!)!, withTimeout:5, tag:-1)
                }
                else if (type == "EndMessage") {
                    self.responseState = .ready
                    self.processFCPResponse()
                }
                else {
                    self.nodeSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout:5, tag:-1)
                }
                break

            case .data:
                let message:String! = String(data:data, encoding:String.Encoding.utf8)
                self.response["Data"] = message
                self.processFCPResponse()
                self.responseState = .ready
                break

            default:
                print("############## WARNING ##################")
                print("UNPROCESSED PACKET RECEIVED:")
                let message = String(data:data, encoding:String.Encoding.utf8)!
                print("\(message)")
                print("############## WARNING ##################")

                self.responseState = .ready
                break
        }
    }

    func processFCPResponse() {
        guard let delegate = self.delegate else {
            return
        }
        guard let command = self.response["Command"] else {
            return
        }
        if (command == "NodeHello") {
            self.connectionState = .ready
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
