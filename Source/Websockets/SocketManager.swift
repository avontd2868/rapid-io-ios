//
//  SocketManager.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class SocketManager {
    
    enum Event {
        case mutate
        case merge
        case subscribe
        case unsubscribe
        case valueReceived
        case updateReceived
        case error
        case acknowledgement
    }
    
    let socket: WebSocket
    fileprivate(set) var state: Rapid.ConnectionState = .disconnected
    
    fileprivate var requestQueue: [String: RapidRequest] = [:]
    fileprivate var activeSubscriptions: [String: RapidSubscriptionHandler] = [:]
    
    init(socketURL: URL) {
        socket = WebSocket(url: socketURL)
        socket.delegate = self
        
        state = .connecting
        
        socket.connect()
    }
    
    deinit {
        socket.disconnect()
    }
    
    func mutate(mutationRequest: MutationRequest) {
        let eventID = Generator.uniqueID
        requestQueue[eventID] = mutationRequest
        
        writeEvent(withID: eventID, withIdentifiers: [RapidSerialization.Mutation.EventID.name: eventID], serializableObject: mutationRequest)
    }
    
    func subscribe(_ subscription: RapidSubscriptionInstance) {
        if let activeSubscription = activeSubscription(withHash: subscription.subscriptionHash) {
            activeSubscription.registerSubscription(subscription: subscription)
        }
        else {
            let eventID = Generator.uniqueID
            let subscriptionID = Generator.uniqueID
            
            let subscriptionHandler = RapidSubscriptionHandler(withSubscriptionID: subscriptionID, subscription: subscription, unsubscribeHandler: { [weak self] handler in
                self?.unsubscribe(handler)
            })
            
            activeSubscriptions[subscriptionID] = subscriptionHandler
            requestQueue[eventID] = subscriptionHandler
            
            let identifiers: [AnyHashable: Any] = [
                RapidSerialization.Subscription.EventID.name: eventID,
                RapidSerialization.Subscription.SubscriptionID.name: subscriptionID
            ]
            
            writeEvent(withID: eventID, withIdentifiers: identifiers, serializableObject: subscriptionHandler)
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
}

fileprivate extension SocketManager {
    
    func acknowledge(eventWithID eventID: String) {
        let acknowledgement = RapidSocketAcknowledgement(eventID: eventID)
        
        writeEvent(withID: eventID, withIdentifiers: [RapidSerialization.Acknowledgement.EventID.name: eventID], serializableObject: acknowledgement)
    }
    
    func unsubscribe(_ handler: RapidUnsubscriptionHandler) {
        activeSubscriptions[handler.subscription.subscriptionID] = nil
        
        let eventID = Generator.uniqueID
        requestQueue[eventID] = handler
        
        writeEvent(withID: eventID, withIdentifiers: [RapidSerialization.Unsubscribe.EventID.name: eventID], serializableObject: handler)
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
    
    func writeEvent(withID eventID: String, withIdentifiers identifiers: [AnyHashable: Any], serializableObject: RapidSerializable) {
        do {
            let jsonString = try serializableObject.serialize(withIdentifiers: identifiers)
            socket.write(string: jsonString)
        }
        catch {
            completeRequest(withResponse: RapidErrorInstance(eventID: eventID, error: .invalidData))
        }
    }
    
    func completeRequest(withResponse response: RapidResponse) {
        switch response {
        case let response as RapidErrorInstance:
            let request = requestQueue[response.eventID]
            request?.eventFailed(withError: response)
            requestQueue[response.eventID] = nil
            
        case let response as RapidSocketAcknowledgement:
            let request = requestQueue[response.eventID]
            request?.eventAcknowledged(response)
            requestQueue[response.eventID] = nil
            
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

extension SocketManager: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        state = .connected
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        state = .disconnected
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        parse(data: data)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        parse(message: text)
    }
}
