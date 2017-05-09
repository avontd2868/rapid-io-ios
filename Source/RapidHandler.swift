//
//  RapidHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Handler for accessing `RapidCache`
protocol RapidCacheHandler: class {
    /// Load data associated with a given subscription
    ///
    /// - Parameters:
    ///   - subscription: Subscription handler object
    ///   - completion: Completion handler. If there are any cached data for the subscription they are passed in the completion handler parameter
    func loadSubscriptionValue(forSubscription subscription: RapidSubscriptionHandler, completion: @escaping (_ value: Any?) -> Void)
    
    /// Store data associated with a given subscription
    ///
    /// - Parameters:
    ///   - value: Data to be stored
    ///   - subscription: Subscription handler object
    func storeValue(_ value: [CachableObject], forSubscription subscription: RapidSubscriptionHandler)
    
    func storeObject(_ object: CachableObject)
    
    func loadObject(withGroupID groupID: String, objectID: String, completion: @escaping (_ value: Any?) -> Void)
    
    func removeObject(withGroupID groupID: String, objectID: String)
}

/// General dependency object containing managers
class RapidHandler: NSObject {
    
    let apiKey: String
    
    let socketManager: RapidSocketManager!
    var state: Rapid.ConnectionState {
        return socketManager.networkHandler.state
    }
    
    var authorization: RapidAuthorization? {
        return socketManager.auth
    }
    
    fileprivate(set) var cache: RapidCache?
    var cacheEnabled: Bool = false {
        didSet {
            RapidLogger.log(message: "Rapid cache enabled \(cacheEnabled)")
            
            // If caching was enbaled and there is no cache instance create it
            if cacheEnabled && cache == nil {
                self.cache = RapidCache(apiKey: apiKey)
            }
            // If caching was disabled release a cache instance and remove cached data
            else if !cacheEnabled {
                cache = nil
                RapidCache.clearCache(forAPIKey: apiKey)
            }
        }
    }
    
    init?(apiKey: String) {
        self.apiKey = apiKey
        
        // Decode connection information from API key
        if let connectionValues = Decoder.decode(apiKey: apiKey) {
            let networkHandler = RapidNetworkHandler(socketURL: connectionValues.hostURL)
            
            socketManager = RapidSocketManager(networkHandler: networkHandler)
        }
        else {
            return nil
        }
        
        super.init()
        
        socketManager.cacheHandler = self
    }

}

extension RapidHandler: RapidCacheHandler {
    
    func loadSubscriptionValue(forSubscription subscription: RapidSubscriptionHandler, completion: @escaping (Any?) -> Void) {
        cache?.cache(forKey: subscription.subscriptionHash, secret: socketManager.auth?.accessToken, completion: completion)
    }

    func storeValue(_ value: [CachableObject], forSubscription subscription: RapidSubscriptionHandler) {
        cache?.save(data: value, forKey: subscription.subscriptionHash, secret: socketManager.auth?.accessToken)
    }
    
    func storeObject(_ object: CachableObject) {
        cache?.save(object: object, withSecret: socketManager.auth?.accessToken)
    }
    
    func loadObject(withGroupID groupID: String, objectID: String, completion: @escaping (Any?) -> Void) {
        cache?.loadObject(withGroupID: groupID, objectID: objectID, secret: socketManager.auth?.accessToken, completion: completion)
    }
    
    func removeObject(withGroupID groupID: String, objectID: String) {
        cache?.removeObject(withGroupID: groupID, objectID: objectID)
    }
}
