//
//  SocketManager.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Starscream

class SocketManager {
    
    let socket: WebSocket
    
    init(apiKey: String) {
        socket = WebSocket(url: URL(string: "ws://13.64.77.202:8080")!)
        socket.delegate = self
        socket.connect()
    }
}

extension SocketManager: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        print("Connect")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("Disconnect")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        
    }
}
