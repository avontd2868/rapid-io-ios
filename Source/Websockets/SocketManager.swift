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
    
    enum Event: String {
        case mutate = "mut"
        case subscribe = "sub"
        case unsubscribe = "unsub"
    }
    
    let socket: WebSocket
    fileprivate(set) var status: Status = .disconnected
    
    fileprivate var requestQueue: [String: RapidMutationCallback] = [:]
    
    init(apiKey: String) {
        socket = WebSocket(url: URL(string: "ws://13.64.77.202:8080")!)
        socket.delegate = self
        
        status = .connecting
        
        socket.connect()
    }
    
    func sendMutation(forObject object: MutationEntity, withCompletion completion: RapidMutationCallback? = nil) {
        let eventID = NSUUID().uuidString
        requestQueue[eventID] = completion
        
        let json = [Event.mutate.rawValue: object.mutationJSON(withEventID: eventID)]
        
        write(eventWithID: eventID, json: json)
    }
}

fileprivate extension SocketManager {
    
    func parse(message: String) {
        print(message)
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
        
        print(json ?? [:])
    }
    
    func write(eventWithID eventID: String, json: [AnyHashable: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            socket.write(data: data)
        }
        catch {
            completeMutation(withID: eventID, object: nil, error: RapidError.invalidData)
        }
    }
    
    func completeMutation(withID eventID: String, object: Any?, error: Error?) {
        if let completion = requestQueue[eventID] {
            requestQueue[eventID] = nil
            completion(error, object)
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
