//
//  RapidHandler.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidHandler: NSObject {
    
    let socketManager: SocketManager
    
    init?(apiKey: String) {
        if let connectionValues = Decoder.decode(apiKey: apiKey) {
            socketManager = SocketManager(socketURL: connectionValues.hostURL)
        }
        else {
            return nil
        }
    }
    
    init(socketManager: SocketManager) {
        self.socketManager = socketManager
    }
}
