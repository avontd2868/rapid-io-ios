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
    
    fileprivate let websocketQueue: DispatchQueue
    fileprivate let socket: WebSocket
    fileprivate var requestQueue: [Request] = []
    fileprivate var pendingRequests: [String: Request] = [:]
    fileprivate var activeSubscriptions: [String: RapidSubscriptionHandler] = [:]
    
    fileprivate var socketTerminated = false
    
    init(socketURL: URL) {
        self.websocketQueue = DispatchQueue(label: "RapidWebsocketQueue-\(socketURL.lastPathComponent)", attributes: [])
        self.connectionID = Generator.uniqueID
        self.socket = WebSocket(url: socketURL)
        self.socket.delegate = self
        
        websocketQueue.async { [weak self] in
            self?.createConnection()
        }
    }
    
    deinit {
        destroySocket()
    }
    
    func mutate<T: MutationRequest>(mutationRequest: T) {
        websocketQueue.async { [weak self] in
            self?.postEvent(serializableRequest: mutationRequest)
        }
    }
    
    func merge<T: MergeRequest>(mergeRequest: T) {
        websocketQueue.async { [weak self] in
            self?.postEvent(serializableRequest: mergeRequest)
        }
    }
    
    func subscribe(_ subscription: RapidSubscriptionInstance) {
        websocketQueue.async { [weak self] in
            guard let queue = self?.websocketQueue else {
                return
            }
            
            if let activeSubscription = self?.activeSubscription(withHash: subscription.subscriptionHash) {
                activeSubscription.registerSubscription(subscription: subscription)
            }
            else {
                let subscriptionID = Generator.uniqueID
                
                let subscriptionHandler = RapidSubscriptionHandler(withSubscriptionID: subscriptionID, subscription: subscription, dispatchQueue: queue, unsubscribeHandler: { [weak self] handler in
                    self?.unsubscribe(handler)
                })
                
                self?.activeSubscriptions[subscriptionID] = subscriptionHandler
                
                self?.postEvent(serializableRequest: subscriptionHandler)
            }
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
    
    func eventID(forPendingRequest request: RapidRequest) -> String? {
        let pendingTuples = pendingRequests.filter({ $0.value === request })
        return pendingTuples.first?.key
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

        if let timeout = Rapid.timeout {
            connection.requestSent(withTimeout: timeout, delegate: self)
        }
        else {
            connection.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)
        }

        writeEvent(serializableRequest: connection)
    }
    
    func sendDisconnectionRequest() {
        postEvent(serializableRequest: RapidDisconnectionRequest())
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
        
        registerPendingRequest(serializableRequest, withID: eventID)
        
        do {
            let jsonString = try serializableRequest.serialize(withIdentifiers: [RapidSerialization.EventID.name: eventID])
            
            socket.write(string: jsonString)
        }
        catch {
            completeRequest(withResponse: RapidErrorInstance(eventID: eventID, error: .invalidData))
        }
    }
    
    func registerPendingRequest(_ request: Request, withID eventID: String) {
        switch request {
        case is RapidDisconnectionRequest, is RapidSocketAcknowledgement:
            break
            
        default:
            pendingRequests[eventID] = request
        }
    }
    
    func postEvent(serializableRequest: Request) {
        
        if let timeoutRequest = serializableRequest as? RapidTimeoutRequest, let timeout = Rapid.timeout {
            timeoutRequest.requestSent(withTimeout: timeout, delegate: self)
        }
        else if let timeoutRequest = serializableRequest as? RapidTimeoutRequest, timeoutRequest.alwaysTimeout {
            timeoutRequest.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)
        }

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

// MARK: Connection request delegate
extension SocketManager: RapidConnectionRequestDelegate {
    
    func connectionEstablished(_ request: RapidConnectionRequest) {
        websocketQueue.async { [weak self] in
            self?.state = .connected
            
            self?.flushQueue()
            self?.sendHeartbeat()
        }
    }
    
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance) {
        websocketQueue.async { [weak self] in
            self?.restartSocket()
        }
    }
}

// MARK: Heartbeat delegate
extension SocketManager: RapidHeartbeatDelegate {
    
    func connectionAlive(_ heartbeat: RapidHeartbeat) {
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                Timer.scheduledTimer(timeInterval: 10, target: strongSelf, selector: #selector(strongSelf.sendHeartbeat), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func sendHeartbeat() {
        websocketQueue.async { [weak self] in
            if let strongSelf = self, strongSelf.state == .connected {
                self?.postEvent(serializableRequest: RapidHeartbeat(delegate: strongSelf))
            }
        }
    }
    
    func connectionExpired(_ heartbeat: RapidHeartbeat) {
        websocketQueue.async { [weak self] in
            self?.connectionID = Generator.uniqueID
            
            self?.restartSocket()
        }
    }
}

// MARK: Timout request delegate
extension SocketManager: RapidTimeoutRequestDelegate {
    
    func requestTimeout(_ request: RapidTimeoutRequest) {
        websocketQueue.async { [weak self] in
            if let eventID = self?.eventID(forPendingRequest: request) {
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.completeRequest(withResponse: error)
            }
            else if let index = self?.requestQueue.index(where: { request === $0 }), let request = request as? Request {
                self?.requestQueue.remove(at: index)
                
                let eventID = Generator.uniqueID
                self?.registerPendingRequest(request, withID: eventID)
                
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.completeRequest(withResponse: error)
            }
        }
    }
}

// MARK: Websocket delegate
extension SocketManager: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        websocketQueue.async { [weak self] in
            self?.sendConnectionRequest()
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        websocketQueue.async { [weak self] in
            self?.state = .disconnected
            
            if !(self?.socketTerminated ?? true) {
                self?.socketDidDisconnect()
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        websocketQueue.async { [weak self] in
            self?.parse(data: data)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        websocketQueue.async { [weak self] in
            self?.parse(message: text)
        }
    }
}
