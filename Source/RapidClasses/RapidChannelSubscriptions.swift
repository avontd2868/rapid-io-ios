//
//  RapidChannels.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Channel identifier
///
/// - name: Single channel identified by full name
/// - prefix: Multimple channels identified by their prefix
enum RapidChannelIdentifier {
    case name(String)
    case prefix(String)
}

/// Channel subscription object
class RapidChannelSub: NSObject {
    
    /// Channel ID
    let channelID: RapidChannelIdentifier
    
    /// Subscription handler
    let handler: RapidChannelSubscriptionHandler?
    
    /// Block of code to be called when unsubscribing
    fileprivate var unsubscribeHandler: ((RapidSubscriptionInstance) -> Void)?
    
    /// Initialize channel subscription object
    ///
    /// - Parameters:
    ///   - channelID: Channel identifier
    ///   - handler: Subscription handler
    init(channelID: RapidChannelIdentifier, handler: RapidChannelSubscriptionHandler?) {
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
    
    /// Channel received a new message
    ///
    /// - Parameter message: New message
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
