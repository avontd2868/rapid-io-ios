//
//  Rapid.swift
//  Rapid
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class Rapid {
    
    let socketManager: SocketManager
    
    static var sharedInstance: Rapid?
    
    public init(apiKey: String) {
        socketManager = SocketManager(apiKey: apiKey)
    }
}

// MARK: Class methods
extension Rapid {
    
    class func shared() throws -> Rapid {
        if let shared = sharedInstance {
            return shared
        }
        else {
            throw NSError(domain: "Bla", code: 1, userInfo: nil)
        }
    }
    
}

// MARK: Singleton methods
public extension Rapid {
    
    public class func configure(withAPIKey key: String) {
        sharedInstance = Rapid(apiKey: key)
    }
    
}
