//
//  Rapid.swift
//  Rapid
//
//  Created by Jan Schwarz on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Protocol for handling existing subscription
public protocol RapidSubscription {
    /// Remove subscription
    func unsubscribe()
}

public typealias RapidAuthCallback = (_ success: Bool, _ error: RapidError?) -> Void

/// Class representing a connection to Rapid.io database
public class Rapid: NSObject {
    
    /// All instances which have been initialized
    fileprivate static var instances: [WRO<Rapid>] = []
    
    /// Shared instance accessible by class methods
    static var sharedInstance: Rapid?
    
    /// Internal timeout which is used for connection requests etc.
    static var defaultTimeout: TimeInterval = 300
    
    /// Time interval between heartbeats
    static var heartbeatInterval: TimeInterval = 30
    
    /// Optional timeout for Rapid requests. If timeout is nil requests never end up with timout error
    public static var timeout: TimeInterval?
    
    /// API key that serves to connect to Rapid.io database
    public let apiKey: String
    
    /// If `true` subscription values are stored locally to be available offline
    public var isCacheEnabled: Bool {
        get {
            return handler.cacheEnabled
        }
        
        set {
            handler.cacheEnabled = newValue
        }
    }
    
    /// Current state of Rapid instance
    public var connectionState: ConnectionState {
        return handler.state
    }
    
    public var authorization: RapidAuthorization? {
        return handler.authorization
    }
    
    let handler: RapidHandler
    
    /// Initializes a Rapid instance
    ///
    /// - parameter withAPIKey:     API key that contains necessary information about a database to which you want to connect
    ///
    /// - returns: New or previously initialized instance
    public class func getInstance(withAPIKey apiKey: String) -> Rapid? {
        
        // Delete released instances
        Rapid.instances = Rapid.instances.filter({ $0.object != nil })
        
        // Loop through existing instances and if there is on with the same API key return it
        
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
        
        return Rapid(apiKey: apiKey)
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
    
    public func authorize(withAccessToken accessToken: String, completion: RapidAuthCallback? = nil) {
        let request = RapidAuthRequest(accessToken: accessToken, callback: completion)
        handler.socketManager.authorize(authRequest: request)
    }
    
    /// Creates a new object representing Rapid collection
    ///
    /// - parameter named:     Collection identifier
    ///
    /// - returns: New object representing Rapid collection
    public func collection(named: String) -> RapidCollection {
        return RapidCollection(id: named, handler: handler)
    }
    
    /// Disconnect from server
    public func goOffline() {
        RapidLogger.log(message: "Rapid went offline")
        
        handler.socketManager.goOffline()
    }
    
    /// Restore previously configured connection
    public func goOnline() {
        RapidLogger.log(message: "Rapid went online")
        
        handler.socketManager.goOnline()
    }
    
    /// Remove all subscriptions
    public func unsubscribeAll() {
        handler.socketManager.unsubscribeAll()
    }
}

// MARK: Singleton methods
public extension Rapid {
    
    /// Returns shared Rapid instance if it was previously configured by Rapid.configure()
    ///
    /// - Throws: `RapidInternalError.rapidInstanceNotInitialized` if shared instance hasn't been initialized with Rapid.configure()
    ///
    /// - Returns: Shared Rapid instance
    class func shared() throws -> Rapid {
        if let shared = sharedInstance {
            return shared
        }

        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, priority: .high)
        throw RapidInternalError.rapidInstanceNotInitialized
    }
    
    /// Possible connection states
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }
    
    /// Generates an unique ID which can be safely used as your document ID
    class var uniqueID: String {
        return Generator.uniqueID
    }
    
    class var debugLoggingEnabled: Bool {
        get {
            return RapidLogger.logDebugMessages
        }
        
        set {
            RapidLogger.logDebugMessages = newValue
        }
    }

    class var loggingEnabled: Bool {
        get {
            return RapidLogger.logMessages
        }
        
        set {
            RapidLogger.logMessages = newValue
        }
    }
    
    /// If `true` subscription values are stored locally to be available offline
    class var isCacheEnabled: Bool {
        get {
            let instance = try! shared()
            return instance.isCacheEnabled
        }
        
        set {
            let instance = try! shared()
            instance.isCacheEnabled = newValue
        }
    }
    
    /// Current state of shared Rapid instance
    class var connectionState: ConnectionState {
        return try! shared().connectionState
    }
    
    /// Disconnect from server
    class func goOffline() {
        try! shared().goOffline()
    }
    
    /// Restore previously configured connection
    class func goOnline() {
        try! shared().goOnline()
    }
    
    /// Remove all subscriptions
    class func unsubscribeAll() {
        try! shared().unsubscribeAll()
    }
    
    class func authorize(withAccessToken accessToken: String, completion: RapidAuthCallback? = nil) {
        try! shared().authorize(withAccessToken: accessToken, completion: completion)
    }
    
    /// Configures shared Rapid instance
    ///
    /// Initializes an instance that can be lately accessed through singleton class functions
    ///
    /// - parameter withAPIKey:     API key that contains necessary information about a database to which you want to connect
    class func configure(withAPIKey key: String) {
        sharedInstance = Rapid.getInstance(withAPIKey: key)
    }
    
    /// Creates a new object representing Rapid collection
    ///
    /// - parameter named:     Collection identifier
    ///
    /// - returns: New object representing Rapid collection
    class func collection(named: String) -> RapidCollection {
        return try! shared().collection(named: named)
    }
    
    /// Deinitialize shared Rapid instance
    class func deinitialize() {
        sharedInstance = nil
    }
}
