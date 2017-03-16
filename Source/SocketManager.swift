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
        socket = WebSocket(url: URL(string: "ws://localhost:8080/")!, protocols: [apiKey])
    }
}
