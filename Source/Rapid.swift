//
//  Rapid.swift
//  Rapid
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class Rapid: NSObject {
    
    static var instances: [WRO<Rapid>] = []
    static var sharedInstance: Rapid?
    
    public let apiKey: String
    
    let handler: RapidHandler
    
    public init?(apiKey: String) {
        Rapid.instances = Rapid.instances.filter({ $0.object != nil })
        
        var existingInstance: Rapid?
        for weakInstance in Rapid.instances {
            if let rapid = weakInstance.object, rapid.apiKey == apiKey {
                existingInstance = rapid
                break
            }
        }
        
        if let rapid = existingInstance {
            self.handler = RapidHandler(socketManager: rapid.handler.socketManager)
        }
        else if let handler = RapidHandler(apiKey: apiKey) {
            self.handler = handler
        }
        else {
            return nil
        }
        
        self.apiKey = apiKey
        
        super.init()

        Rapid.instances.append(WRO(object: self))
    }
    
    public func collection(named: String) -> RapidCollection {
        return RapidCollection(id: named, handler: handler)
    }
}

// MARK: Class methods
extension Rapid {
    
    class func shared() throws -> Rapid {
        if let shared = sharedInstance {
            return shared
        }
        else {
            throw RapidError.rapidInstanceNotInitialized
        }
    }
    
}

// MARK: Singleton methods
public extension Rapid {
    
    public class var uniqueID: String {
        return NSUUID().uuidString
    }
    
    public class func configure(withAPIKey key: String) {
        sharedInstance = Rapid(apiKey: key)
    }
    
    public class func collection(named: String) -> RapidCollection {
        return try! shared().collection(named: named)
    }
}
