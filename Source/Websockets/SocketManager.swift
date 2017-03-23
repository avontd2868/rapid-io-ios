//
//  SocketManager.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class SocketManager {
    
    typealias Request = RapidRequest & RapidSerializable
    
    fileprivate(set) var connectionID: String
    fileprivate(set) var state: Rapid.ConnectionState = .disconnected
    
    fileprivate let socket: WebSocket
    fileprivate var requestQueue: [Request] = []
    fileprivate var pendingRequests: [String: Request] = [:]
    fileprivate var activeSubscriptions: [String: RapidSubscriptionHandler] = [:]
    
    fileprivate var socketTerminated = false
    
    init(socketURL: URL) {
        self.connectionID = Generator.uniqueID
        self.socket = WebSocket(url: socketURL)
        self.socket.delegate = self
        
        createConnection()
    }
    
    deinit {
        destroySocket()
    }
    
    func mutate<T: MutationRequest>(mutationRequest: T) {
        postEvent(serializableRequest: mutationRequest)
    }
    
    func subscribe(_ subscription: RapidSubscriptionInstance) {
        if let activeSubscription = activeSubscription(withHash: subscription.subscriptionHash) {
            activeSubscription.registerSubscription(subscription: subscription)
        }
        else {
            let subscriptionID = Generator.uniqueID
            
            let subscriptionHandler = RapidSubscriptionHandler(withSubscriptionID: subscriptionID, subscription: subscription, unsubscribeHandler: { [weak self] handler in
                self?.unsubscribe(handler)
            })
            
            activeSubscriptions[subscriptionID] = subscriptionHandler
            
            postEvent(serializableRequest: subscriptionHandler)
        }
    }
}

fileprivate extension SocketManager {
    
    func activeSubscription(withHash hash: String) -> RapidSubscriptionHandler? {
        for (_, subscription) in activeSubscriptions where subscription.subscriptionHash == hash {
            return subscription
        }
        
        return nil
    }
    
    func socketDidDisconnect() {
        let currentQueue = requestQueue.filter({
            switch $0 {
            case is RapidSubscriptionHandler, is RapidConnectionRequest, is RapidHeartbeat:
                return false
                
            default:
                return true
            }
        })
        
        requestQueue = activeSubscriptions.map({ $0.value })
        requestQueue.append(contentsOf: Array(pendingRequests.values))
        requestQueue.append(contentsOf: currentQueue)
        
        createConnection()
    }
}

fileprivate extension SocketManager {
    
    func createConnection() {
        state = .connecting
        
        socket.connect()
    }
    
    func restartSocket() {
        if socket.isConnected {
            socket.disconnect()
        }
        else if !socketTerminated {
            socketDidDisconnect()
        }
    }
    
    func destroySocket() {
        sendDisconnectionRequest()
        
        socketTerminated = true
        
        socket.disconnect()
    }
    
    func sendConnectionRequest() {
        let connection = RapidConnectionRequest(connectionID: connectionID, delegate: self)

        writeEvent(serializableRequest: connection)
    }
    
    func sendDisconnectionRequest() {
        postEvent(serializableRequest: RapidDisconnectionRequest())
    }
    
    @objc func sendHeartbeat() {
        if state == .connected {
            postEvent(serializableRequest: RapidHeartbeat(delegate: self))
        }
    }
    
    func acknowledge(eventWithID eventID: String) {
        let acknowledgement = RapidSocketAcknowledgement(eventID: eventID)
        
        postEvent(serializableRequest: acknowledgement)
    }
    
    func unsubscribe(_ handler: RapidUnsubscriptionHandler) {
        activeSubscriptions[handler.subscription.subscriptionID] = nil
        
        postEvent(serializableRequest: handler)
    }
    
    func parse(message: String) {
        if let data = message.data(using: .utf8) {
            parse(data: data)
        }
    }
    
    func parse(data: Data) {
        let json: [AnyHashable: Any]?
        
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            json = object as? [AnyHashable: Any]
        }
        catch {
            json = nil
        }
        
        if let responses = RapidSerialization.parse(json: json) {
            for response in responses {
                completeRequest(withResponse: response)
            }
        }
    }
    
    func flushQueue() {
        guard state == .connected else {
            return
        }
        
        let queueCopy = requestQueue
        
        requestQueue.removeAll()

        for request in queueCopy {
            writeEvent(serializableRequest: request)
        }
    }
    
    func writeEvent(serializableRequest: Request) {
        let eventID = Generator.uniqueID
        
        switch serializableRequest {
        case is RapidDisconnectionRequest, is RapidSocketAcknowledgement:
            break
            
        default:
            pendingRequests[eventID] = serializableRequest
        }
        
        do {
            let jsonString = try serializableRequest.serialize(withIdentifiers: [RapidSerialization.EventID.name: eventID])
            socket.write(string: jsonString)
        }
        catch {
            completeRequest(withResponse: RapidErrorInstance(eventID: eventID, error: .invalidData))
        }
    }
    
    func postEvent(serializableRequest: Request) {
        requestQueue.append(serializableRequest)
        flushQueue()
    }
    
    func completeRequest(withResponse response: RapidResponse) {
        switch response {
        case let response as RapidErrorInstance:
            let request = pendingRequests[response.eventID]
            request?.eventFailed(withError: response)
            
            if let subscription = request as? RapidSubscriptionHandler {
                activeSubscriptions[subscription.subscriptionID] = nil
            }
            
            pendingRequests[response.eventID] = nil
            
        case let response as RapidSocketAcknowledgement:
            let request = pendingRequests[response.eventID]
            request?.eventAcknowledged(response)
            pendingRequests[response.eventID] = nil
            
        case let response as RapidSubscriptionInitialValue:
            let subscription = activeSubscriptions[response.subscriptionID]
            subscription?.receivedInitialValue(response)
            acknowledge(eventWithID: response.eventID)
            
        case let response as RapidSubscriptionUpdate:
            let subscription = activeSubscriptions[response.subscriptionID]
            subscription?.receivedUpdate(response)
            acknowledge(eventWithID: response.eventID)
            
        default:
            print("Unrecognized response")
        }
    }
}

extension SocketManager: RapidConnectionRequestDelegate {
    
    func connectionEstablished(_ request: RapidConnectionRequest) {
        state = .connected
        
        flushQueue()
        sendHeartbeat()
    }
    
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance) {
        restartSocket()
    }
}

extension SocketManager: RapidHeartbeatDelegate {
    
    func connectionAlive(_ heartbeat: RapidHeartbeat) {
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.sendHeartbeat), userInfo: nil, repeats: false)
    }
    
    func connectionExpired(_ heartbeat: RapidHeartbeat) {
        connectionID = Generator.uniqueID
        
        restartSocket()
    }
}

extension SocketManager: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        sendConnectionRequest()
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        state = .disconnected
        
        if !socketTerminated {
            socketDidDisconnect()
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        parse(data: data)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        parse(message: text)
    }
}
