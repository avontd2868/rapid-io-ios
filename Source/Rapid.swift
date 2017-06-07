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
    /// Unique subscription identifier
    var subscriptionHash: String { get }
    
    /// Remove subscription
    func unsubscribe()
}

/// Authorization completion handler
public typealias RapidAuthHandler = (_ result: RapidResult<RapidAuthorization>) -> Void

/// Authorization completion handler
public typealias RapidDeuthHandler = (_ result: RapidResult<Any?>) -> Void

/// Result for completion handlers
///
/// - success: Request was proceeded without any error
/// - failure: An error occured
public enum RapidResult<Value> {
    case success(value: Value)
    case failure(error: RapidError)
}

/// Class representing a connection to Rapid.io database
open class Rapid: NSObject {
    
    /// All instances which have been initialized
    fileprivate static var instances: [WRO<Rapid>] = []
    
    /// Shared instance accessible by class methods
    static var sharedInstance: Rapid?
    
    /// Internal timeout which is used for connection requests etc.
    static var defaultTimeout: TimeInterval = 300
    
    /// Time interval between heartbeats
    static var heartbeatInterval: TimeInterval = 30
    
    /// Nil value
    ///
    /// This value can be used in document merge (e.g. `["attribute": Rapid.nilValue]` would remove `attribute` from a document)
    public static let nilValue = NSNull()
    
    /// Placeholder for a server timestamp
    ///
    /// When Rapid.io tries to write a json to a database it replaces every occurance of `serverTimestamp` with Unix timestamp
    public static let serverTimestamp = "__TIMESTAMP__"
    
    /// Optional timeout is seconds for Rapid requests. If timeout is nil requests never end up with timeout error
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
    
    /// Block of code that is called every time the `connectionState` changes
    var onConnectionStateChanged: ((Rapid.ConnectionState) -> Void)? {
        get {
            return handler.onConnectionStateChanged
        }
        
        set {
            handler.onConnectionStateChanged = newValue
        }
    }
    
    /// Current authorization instace
    public var authorization: RapidAuthorization? {
        return handler.authorization
    }
    
    let handler: RapidHandler
    
    /// Initializes a Rapid instance
    ///
    /// - parameter withApiKey:     API key that contains necessary information about a database to which you want to connect
    ///
    /// - returns: New or previously initialized instance
    public class func getInstance(withApiKey apiKey: String) -> Rapid? {
        
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
    
    /// Authorize Rapid instance
    ///
    /// - Parameters:
    ///   - token: Authorization token
    ///   - completion: Authorization completion handler
    open func authorize(withToken token: String, completion: RapidAuthHandler? = nil) {
        let request = RapidAuthRequest(token: token, handler: completion)
        handler.socketManager.authorize(authRequest: request)
    }
    
    /// Deauthorize Rapid instance
    ///
    /// - Parameter completion: Deauthorization completion handler
    open func deauthorize(completion: RapidDeuthHandler? = nil) {
        let request = RapidDeauthRequest(handler: completion)
        handler.socketManager.deauthorize(deauthRequest: request)
    }
    
    /// Creates a new object representing Rapid collection
    ///
    /// - parameter named:     Collection identifier
    ///
    /// - returns: New object representing Rapid collection
    open func collection(named name: String) -> RapidCollectionRef {
        return RapidCollectionRef(id: name, handler: handler)
    }
    
    open func channel(named name: String) -> RapidChannelRef {
        return RapidChannelRef(identifier: .name(name), handler: handler)
    }
    
    open func channels(nameStartingWith prefix: String) -> RapidChannelRef {
        return RapidChannelRef(identifier: .prefix(prefix), handler: handler)
    }
    
    /// Disconnect from server
    open func goOffline() {
        RapidLogger.log(message: "Rapid went offline", level: .info)
        
        handler.socketManager.goOffline()
    }
    
    /// Restore previously configured connection
    open func goOnline() {
        RapidLogger.log(message: "Rapid went online", level: .info)
        
        handler.socketManager.goOnline()
    }
    
    /// Remove all subscriptions
    open func unsubscribeAll() {
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

        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, level: .critical)
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
    
    /// Log level
    class var logLevel: RapidLogger.Level {
        get {
            return RapidLogger.level
        }
        
        set {
            RapidLogger.level = newValue
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
    
    /// Block of code that is called every time the `connectionState` changes
    class var onConnectionStateChanged: ((Rapid.ConnectionState) -> Void)? {
        get {
            let instance = try! shared()
            return instance.onConnectionStateChanged
        }
        
        set {
            let instance = try! shared()
            instance.onConnectionStateChanged = newValue
        }
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
    
    /// Authorize Rapid instance
    ///
    /// - Parameters:
    ///   - token: Authorization token
    ///   - completion: Authorization completion handler
    class func authorize(withToken token: String, completion: RapidAuthHandler? = nil) {
        try! shared().authorize(withToken: token, completion: completion)
    }
    
    /// Deauthorize Rapid instance
    ///
    /// - Parameter completion: Deauthorization completion handler
    class func deauthorize(completion: RapidDeuthHandler? = nil) {
        try! shared().deauthorize(completion: completion)
    }
    
    /// Configures shared Rapid instance
    ///
    /// Initializes an instance that can be lately accessed through singleton class functions
    ///
    /// - parameter withApiKey:     API key that contains necessary information about a database to which you want to connect
    class func configure(withApiKey key: String) {
        sharedInstance = Rapid.getInstance(withApiKey: key)
    }
    
    /// Creates a new object representing Rapid collection
    ///
    /// - parameter named:     Collection identifier
    ///
    /// - returns: New object representing Rapid collection
    class func collection(named: String) -> RapidCollectionRef {
        return try! shared().collection(named: named)
    }
    
    class func channel(named name: String) -> RapidChannelRef {
        return try! shared().channel(named: name)
    }
    
    class func channels(nameStartingWith prefix: String) -> RapidChannelRef {
        return try! shared().channels(nameStartingWith: prefix)
    }
    
    /// Deinitialize shared Rapid instance
    class func deinitialize() {
        sharedInstance = nil
    }
}
