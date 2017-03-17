//
//  SocketManager.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class SocketManager {
    
    enum Status {
        case disconnected
        case connecting
        case connected
    }
    
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
    fileprivate(set) var status: Status = .disconnected
    
    fileprivate var requestQueue: [String: RapidRequest] = [:]
    fileprivate var activeSubscriptions: [String: NSObject] = [:]
    
    init(socketURL: URL) {
        socket = WebSocket(url: socketURL)
        socket.delegate = self
        
        status = .connecting
        
        socket.connect()
    }
    
    deinit {
        socket.disconnect()
    }
    
    func mutate(mutationRequest: MutationRequest) {
        let eventID = NSUUID().uuidString
        requestQueue[eventID] = mutationRequest
        
        writeEvent(withID: eventID, withIdentifiers: [RapidSerialization.Mutation.EventID.name: eventID], serializableObject: mutationRequest)
    }
    
    func subscribe<T: RapidSubscription>(_ subscription: T) {
        if let activeSubscription = activeSubscriptions[subscription.hash] as? RapidSubscriptionHandler<T> {
            activeSubscription.registerSubscription(subscription: subscription)
        }
        else {
            let eventID = NSUUID().uuidString
            let subscriptionID = NSUUID().uuidString
            
            let subscriptionHandler = RapidSubscriptionHandler(withSubscriptionID: subscriptionID, subscription: subscription, unsubscribeHandler: { [weak self] handler in
                self?.unsubscribe(handler)
            })
            
            activeSubscriptions[subscriptionHandler.subscriptionHash] = subscriptionHandler
            requestQueue[eventID] = subscriptionHandler
            
            let identifiers: [AnyHashable: Any] = [
                RapidSerialization.Subscription.EventID.name: eventID,
                RapidSerialization.Subscription.SubscriptionID.name: subscriptionID
            ]
            
            writeEvent(withID: eventID, withIdentifiers: identifiers, serializableObject: subscription)
        }
    }
}

fileprivate extension SocketManager {
    
    func unsubscribe<T>(_ subscription: RapidSubscriptionHandler<T>) {
        
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
            completeRequest(withResponse: RapidSocketError.invalidData(eventID: eventID, message: nil))
        }
    }
    
    func completeRequest(withResponse response: RapidResponse) {
        if let request = requestQueue[response.eventID] {
            requestQueue[response.eventID] = nil
            
            switch response {
            case let response as RapidSocketError:
                request.eventFailed(withError: response)
                
            case let response as RapidSubscriptionInitialValue:
                request.eventAcknowledged(response)
                
            case let response as RapidSocketAcknowledgement:
                request.eventAcknowledged(response)
                
            default:
                request.eventFailed(withError: RapidSocketError.default(eventID: response.eventID))
            }
        }
    }
}

extension SocketManager: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        status = .connected
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        status = .disconnected
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        parse(data: data)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        parse(message: text)
    }
}
