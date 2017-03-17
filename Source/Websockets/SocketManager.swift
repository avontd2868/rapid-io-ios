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
        case merge = "mer"
        case subscribe = "sub"
        case unsubscribe = "uns"
        case valueReceived = "val"
        case updateReceived = "upd"
        case error = "err"
        case acknowledgement = "ack"
    }
    
    let socket: WebSocket
    fileprivate(set) var status: Status = .disconnected
    
    fileprivate var requestQueue: [String: RapidRequest] = [:]
    
    init(socketURL: URL) {
        socket = WebSocket(url: socketURL)
        socket.delegate = self
        
        status = .connecting
        
        socket.connect()
    }
    
    func sendMutation(mutationRequest: MutationRequest) {
        let eventID = NSUUID().uuidString
        requestQueue[eventID] = mutationRequest
        
        let json = [Event.mutate.rawValue: mutationRequest.mutationJSON(withEventID: eventID)]
        
        write(eventWithID: eventID, json: json)
    }
}

fileprivate extension SocketManager {
    
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
        
        if let responses = RapidSocketParser.parse(json: json) {
            for response in responses {
                completeRequest(withResponse: response)
            }
        }
    }
    
    func write(eventWithID eventID: String, json: [AnyHashable: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: data, encoding: .utf8)
            socket.write(string: jsonString ?? "")
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
