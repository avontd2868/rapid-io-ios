//
//  Rapid.swift
//  Rapid
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public protocol RapidSubscription {
    func unsubscribe()
}

public class Rapid: NSObject {
    
    static var instances: [WRO<Rapid>] = []
    static var sharedInstance: Rapid?
    
    static var defaultTimeout: TimeInterval = 300
    public static var timeout: TimeInterval?
    
    public let apiKey: String
    
    public var connectionState: ConnectionState {
        return handler.socketManager.state
    }
    
    let handler: RapidHandler
    
    public class func getInstance(withAPIKey apiKey: String) -> Rapid? {
        Rapid.instances = Rapid.instances.filter({ $0.object != nil })
        
        var existingInstance: Rapid?
        for weakInstance in Rapid.instances {
            if let rapid = weakInstance.object, rapid.apiKey == apiKey {
                existingInstance = rapid
                break
            }
        }
        
        if let rapid = existingInstance {
            return rapid
        }
        else {
            return Rapid(apiKey: apiKey)
        }
    }
    
    init?(apiKey: String) {
        if let handler = RapidHandler(apiKey: apiKey) {
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
    
    func goOffline() {
        handler.socketManager.goOffline()
    }
    
    func goOnline() {
        handler.socketManager.goOnline()
    }
}

// MARK: Singleton methods
public extension Rapid {
    
    class func shared() throws -> Rapid {
        if let shared = sharedInstance {
            return shared
        }
        else {
            throw RapidInternalError.rapidInstanceNotInitialized
        }
    }
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }
    
    class var uniqueID: String {
        return Generator.uniqueID
    }
    
    class var connectionState: ConnectionState {
        return try! shared().connectionState
    }
    
    class func configure(withAPIKey key: String) {
        sharedInstance = Rapid(apiKey: key)
    }
    
    class func collection(named: String) -> RapidCollection {
        return try! shared().collection(named: named)
    }
    
    class func deinitialize() {
        sharedInstance = nil
    }
}
