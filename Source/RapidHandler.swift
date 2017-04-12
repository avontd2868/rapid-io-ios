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
    
    let socketManager: RapidSocketManager
    var state: Rapid.ConnectionState {
        return socketManager.state
    }
    
    init?(apiKey: String) {
        // Decode connection information from API key
        if let connectionValues = Decoder.decode(apiKey: apiKey) {
            let networkHandler = RapidNetworkHandler(socketURL: connectionValues.hostURL)
            
            socketManager = RapidSocketManager(networkHandler: networkHandler)
        }
        else {
            return nil
        }
    }

}
