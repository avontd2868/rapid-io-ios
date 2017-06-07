//
//  RapidChannels.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Collection subscription object
class RapidChannelSub: NSObject {
    
    /// Channel ID
    let channelID: RapidChannelRef.ChannelIdentifier
    
    /// Subscription handler
    let handler: RapidChanSubHandler?
    
    /// Block of code to be called when unsubscribing
    fileprivate var unsubscribeHandler: ((RapidSubscriptionInstance) -> Void)?
    
    init(channelID: RapidChannelRef.ChannelIdentifier, handler: RapidChanSubHandler?) {
        self.channelID = channelID
        self.handler = handler
    }
    
}

extension RapidChannelSub: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(subscription: self, withIdentifiers: identifiers)
    }
    
}

extension RapidChannelSub: RapidChanSubInstance {
    
    /// Subscription identifier
    var subscriptionHash: String {
        switch channelID {
        case .name(let name):
            return "channel#\(name)"
            
        case .prefix(let prefix):
            return "channel#\(prefix)*"
        }
    }
    
    func subscriptionFailed(withError error: RapidError) {
        // Pass error to handler
        DispatchQueue.main.async {
            self.handler?(.failure(error: error))
        }
    }
    
    /// Assign a block of code that should be called on unsubscribing to `unsubscribeHandler`
    ///
    /// - Parameter block: Block of code that should be called on unsubscribing
    func registerUnsubscribeHandler(_ block: @escaping (RapidSubscriptionInstance) -> Void) {
        unsubscribeHandler = block
    }
    
    func receivedMessage(_ message: RapidChannelMessage) {
        DispatchQueue.main.async {
            self.handler?(.success(value: message))
        }
    }
}

extension RapidChannelSub: RapidSubscription {
    
    /// Unregister subscription
    func unsubscribe() {
        unsubscribeHandler?(self)
    }
    
}
