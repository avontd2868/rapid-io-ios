//
//  RapidHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// General dependency object containing managers
class RapidHandler: NSObject {
    
    let socketManager: SocketManager
    fileprivate(set) var state: Rapid.ConnectionState = .disconnected
    
    init?(apiKey: String) {
        // Decode connection information from API key
        if let connectionValues = Decoder.decode(apiKey: apiKey) {
            socketManager = SocketManager(socketURL: connectionValues.hostURL)
        }
        else {
            return nil
        }
        
        super.init()
        
        socketManager.connectionStateDelegate = self
    }

}

extension RapidHandler: RapidConnectionStateChangeDelegate {
    
    func connectionStateChanged(currentState: Rapid.ConnectionState) {
        state = currentState
    }
}
