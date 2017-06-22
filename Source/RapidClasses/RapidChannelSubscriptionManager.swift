//
//  RapidChannelSubscriptionManager.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Class that handles all channel subscriptions which listen to the same channel
class RapidChanSubManager: NSObject, RapidSubscriptionManager {
    
    /// Hash that identifies subscriptions handled by the class
    ///
    /// Subscriptions that listen to the same dataset have equal hashes
    var subscriptionHash: String {
        return subscriptions.first?.subscriptionHash ?? ""
    }
    
    /// ID of subscription
    let subscriptionID: String
    
    /// Handler delegate
    internal weak var delegate: RapidSubscriptionManagerDelegate?
    
    /// Array of subscription objects
    fileprivate var subscriptions: [RapidChanSubInstance] = []
    
    /// Subscription state
    internal var state: RapidSubscriptionState = .unsubscribed
    
    /// Handler initializer
    ///
    /// - Parameters:
    ///   - subscriptionID: Subscription identifier
    ///   - subscription: Subscription object
    ///   - delegate: Handler delegate
    init(withSubscriptionID subscriptionID: String, subscription: RapidChanSubInstance, delegate: RapidSubscriptionManagerDelegate?) {
        self.subscriptionID = subscriptionID
        self.delegate = delegate
        
        super.init()
        
        state = .registering
        appendSubscription(subscription)
    }
    
    /// Add another subscription object to the handler
    ///
    /// - Parameter subscription: New subscription object
    func registerSubscription(subscription: RapidChanSubInstance) {
        delegate?.websocketQueue.async {
            self.appendSubscription(subscription)
        }
    }

}

extension RapidChanSubManager: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        if let subscription = subscriptions.first {
            var idef = identifiers
            
            idef[RapidSerialization.ChannelSubscription.SubscriptionID.name] = subscriptionID
            
            return try subscription.serialize(withIdentifiers: idef)
        }
        else {
            throw RapidError.invalidData(reason: .serializationFailure)
        }
    }
    
    /// JSON message for unsubscribing request
    ///
    /// - Parameter identifiers: Custom identifiers
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` and `RapidError.invalidData` errors
    func serializeForUnsubscription(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(unsubscription: self, withIdentifiers: identifiers)
    }
}

fileprivate extension RapidChanSubManager {
    
    /// Add a new subscription object
    ///
    /// - Parameter subscription: New subscription object
    func appendSubscription(_ subscription: RapidChanSubInstance) {
        subscription.registerUnsubscribeHandler { [weak self] instance in
            self?.delegate?.websocketQueue.async {
                self?.unsubscribe(instance: instance)
            }
        }
        subscriptions.append(subscription)
    }

    func unsubscribe(instance: RapidSubscriptionInstance) {
        // If there is only one subscription object unsubscribe the handler
        // Otherwise just remove the subscription object from array of registered subscription objects
        if subscriptions.count == 1 {
            state = .unsubscribing
            delegate?.unsubscribe(handler: RapidUnsubscriptionManager(subscription: self))
        }
        else if let index = subscriptions.index(where: { $0 === instance }) {
            subscriptions.remove(at: index)
        }
    }

}

extension RapidChanSubManager: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        delegate?.websocketQueue.async {
            self.state = .subscribed
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        delegate?.websocketQueue.async {
            RapidLogger.log(message: "Subscription failed \(self.subscriptionHash) with error \(error.error)", level: .info)
            
            self.state = .unsubscribed
            
            for subscription in self.subscriptions {
                subscription.subscriptionFailed(withError: error.error)
            }
        }
    }
    
    func receivedMessage(_ message: RapidChannelMessage) {
        delegate?.websocketQueue.async {
            RapidLogger.log(message: "Subscription \(self.subscriptionHash) received message \(message.message)", level: .info)
            
            for subscription in self.subscriptions {
                subscription.receivedMessage(message)
            }
        }
    }
}
