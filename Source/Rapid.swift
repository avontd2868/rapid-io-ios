//
//  Rapid.swift
//  Rapid
//
//  Created by Jan Schwarz on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Possible connection states
///
/// - disconnected: Rapid instance is disconnected
/// - connecting: Rapid instance is connecting to server
/// - connected: Rapid instance is connected
public enum RapidConnectionState {
    case disconnected
    case connecting
    case connected
}

/// Authorization completion handler
public typealias RapidAuthHandler = (_ result: RapidResult<RapidAuthorization>) -> Void

/// Deauthorization completion handler
public typealias RapidDeuthHandler = (_ result: RapidResult<Any?>) -> Void

/// Server time offset handler
public typealias RapidTimeOffsetHandler = (_ offset: RapidResult<TimeInterval>) -> Void

/// Result of a request that is passed to a completion handler
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
    
    /// API key that serves to connect to Rapid.io database
    public let apiKey: String
    
    /// Optional timeout in seconds for requests. If `timeout` is nil requests never end up with timeout error
    public var timeout: TimeInterval? {
        get {
            return handler.timeout
        }
        
        set {
            handler.timeout = newValue
        }
    }
    
    /// If `true` subscription values are stored locally to be available offline
    public var isCacheEnabled: Bool {
        get {
            return handler.cacheEnabled
        }
        
        set {
            handler.cacheEnabled = newValue
        }
    }
    
    /// Current connection state of Rapid instance
    public var connectionState: RapidConnectionState {
        return handler.state
    }
    
    /// Block of code that is called every time the `connectionState` changes
    public var onConnectionStateChanged: ((RapidConnectionState) -> Void)? {
        get {
            return handler.onConnectionStateChanged
        }
        
        set {
            handler.onConnectionStateChanged = newValue
        }
    }
    
    /// Current authorization instance
    public var authorization: RapidAuthorization? {
        return handler.authorization
    }
    
    let handler: RapidHandler
    
    /// Initialize a Rapid instance
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
    
    /// Create a new object representing Rapid.io collection
    ///
    /// - parameter named: Collection name
    ///
    /// - returns: New object representing Rapid.io collection
    open func collection(named name: String) -> RapidCollectionRef {
        return RapidCollectionRef(id: name, handler: handler)
    }
    
    /// Creates a new object representing Rapid.io channel
    ///
    /// - Parameter name: Channel name
    /// - Returns: New object representing Rapid.io channel
    open func channel(named name: String) -> RapidChannelRef {
        return RapidChannelRef(name: name, handler: handler)
    }
    
    /// Creates a new object representing multiple Rapid.io channels identified by a name prefix
    ///
    /// - Parameter prefix: Channel name prefix
    /// - Returns: New object representing multiple Rapid.io channels
    open func channels(nameStartsWith prefix: String) -> RapidChannelsRef {
        return RapidChannelsRef(prefix: prefix, handler: handler)
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
    
    /// Get a difference between local device time and server time
    ///
    /// When server time is 1.1.2017 7:18:19 AM and device time is 1.1.2017 7:18:20
    /// the offset is positive 1
    ///
    /// Offset's accuracy can be affected by network latency, so it is useful primarily for discovering large (> 1 second) discrepancies in clock time
    ///
    /// - Parameter completion: Completion handler which returns the offset
    open func serverTimeOffset(completion: @escaping RapidTimeOffsetHandler) {
        let request = RapidTimeOffset(completion: completion)
        
        handler.socketManager.requestTimestamp(request)
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
    
    /// Generate an unique ID which can be safely used as your document ID
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
    
    /// Optional timeout in seconds for requests. If `timeout` is nil requests never end up with timeout error
    class var timeout: TimeInterval? {
        get {
            let instance = try! shared()
            return instance.timeout
        }
        
        set {
            let instance = try! shared()
            instance.timeout = newValue
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
    
    /// Current connection state of shared Rapid instance
    class var connectionState: RapidConnectionState {
        return try! shared().connectionState
    }
    
    /// Block of code that is called every time the `connectionState` changes
    class var onConnectionStateChanged: ((RapidConnectionState) -> Void)? {
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
    
    /// Get a difference between local device time and server time
    ///
    /// When server time is 1.1.2017 7:18:19 AM and device time is 1.1.2017 7:18:20
    /// the offset is positive 1
    ///
    /// Offset's accuracy can be affected by network latency, so it is useful primarily for discovering large (> 1 second) discrepancies in clock time
    ///
    /// - Parameter completion: Completion handler which returns the offset
    class func serverTimeOffset(completion: @escaping RapidTimeOffsetHandler) {
        try! shared().serverTimeOffset(completion: completion)
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
    
    /// Configure shared Rapid instance
    ///
    /// It initializes a shared instance that can be lately accessed through class functions
    ///
    /// - parameter withApiKey:     API key that contains necessary information about a database to which you want to connect
    class func configure(withApiKey key: String) {
        sharedInstance = Rapid.getInstance(withApiKey: key)
    }
    
    /// Create a new object representing Rapid.io collection
    ///
    /// - parameter named: Collection name
    ///
    /// - returns: New object representing Rapid.io collection
    class func collection(named: String) -> RapidCollectionRef {
        return try! shared().collection(named: named)
    }
    
    /// Create a new object representing Rapid.io channel
    ///
    /// - Parameter name: Channel name
    /// - Returns: New object representing Rapid.io channel
    class func channel(named name: String) -> RapidChannelRef {
        return try! shared().channel(named: name)
    }
    
    /// Creates a new object representing multiple Rapid.io channels identified by a name prefix
    ///
    /// - Parameter prefix: Channel name prefix
    /// - Returns: New object representing multiple Rapid.io channels
    class func channels(nameStartsWith prefix: String) -> RapidChannelsRef {
        return try! shared().channels(nameStartsWith: prefix)
    }
    
    /// Deinitialize shared Rapid instance
    class func deinitialize() {
        sharedInstance = nil
    }
}
