//
//  RapidSubscription.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidSubscriptionHashable {
    /// Hash identifying the subscription
    var subscriptionHash: String { get }
}

/// Protocol describing subscription objects
protocol RapidSubscriptionInstance: class, RapidSerializable, RapidSubscriptionHashable, RapidSubscription {
    
    /// Subscription failed to be registered
    ///
    /// - Parameter error: Failure reason
    func subscriptionFailed(withError error: RapidError)
    
    /// Pass a block of code that should be called when the subscription should be unregistered
    ///
    /// - Parameter block: Block of code that should be called when the subscription should be unregistered
    func registerUnsubscribeHandler(_ block: @escaping (RapidSubscriptionInstance) -> Void)
}

protocol RapidChanSubInstance: RapidSubscriptionInstance {

    func receivedMessage(_ message: RapidChannelMessage)
}

protocol RapidColSubInstance: RapidSubscriptionInstance {
    /// Maximum number of documents in subscription
    var subscriptionTake: Int? { get }
    
    var subscriptionOrdering: [RapidOrdering.Ordering]? { get }
    
    /// Subscription dataset changed
    ///
    /// - Parameters:
    ///   - documents: All documents that meet subscription definition
    ///   - added: Documents that have been added since last call
    ///   - updated: Documents that have been modified since last call
    ///   - removed: Documents that have been removed since last call
    func receivedUpdate(_ documents: [RapidDocument], _ added: [RapidDocument], _ updated: [RapidDocument], _ removed: [RapidDocument])
}

protocol RapidFetchInstance: class, RapidSerializable, RapidTimeoutRequest, RapidSubscriptionHashable {
    var fetchID: String { get }
    
    func receivedData(_ documents: [RapidDocument])
    func fetchFailed(withError error: RapidError)
}

extension RapidFetchInstance {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {}
    
    func eventFailed(withError error: RapidErrorInstance) {
        fetchFailed(withError: error.error)
    }

}

enum RapidSubscriptionState {
    case unsubscribed
    case registering
    case subscribed
    case unsubscribing
}

/// Subscription manager delegate
protocol RapidSubscriptionManagerDelegate: class {
    /// Dedicated queue for task management
    var websocketQueue: OperationQueue { get }
    
    /// Dedicated queue for parsing
    var parseQueue: OperationQueue { get }
    
    /// Cache handler
    var cacheHandler: RapidCacheHandler? { get }
    
    var authorization: RapidAuthorization? { get }
    
    /// Method for unregistering a subscription
    ///
    /// - Parameter handler: Unsubscription handler
    func unsubscribe(handler: RapidUnsubscriptionManager)
}

/// Subscription manager that handles events for subscriptions with a same subscription hash
protocol RapidSubscriptionManager: class, RapidSubscriptionHashable, RapidSerializable, RapidClientRequest {
    
    /// Subscription state
    var state: RapidSubscriptionState { get set }
    
    /// Subscription manager delegate
    var delegate: RapidSubscriptionManagerDelegate? { get set }
    
    /// Subscription identifier
    var subscriptionID: String { get }
    
    /// JSON message for unsubscribing request
    ///
    /// - Parameter identifiers: Custom identifiers
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` and `RapidError.invalidData` errors
    func serializeForUnsubscription(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String
}

extension RapidSubscriptionManager {
    
    var shouldSendOnReconnect: Bool {
        return false
    }
    
    /// Unsubscribe handler
    ///
    /// - Parameter handler: Previously creaated unsubscription handler
    func retryUnsubscription(withHandler handler: RapidUnsubscriptionManager) {
        delegate?.websocketQueue.async { [weak self] in
            if self?.state == .unsubscribing {
                self?.delegate?.unsubscribe(handler: handler)
            }
        }
    }
    
    /// Inform handler about being unsubscribed
    func didUnsubscribe() {
        delegate?.websocketQueue.async { [weak self] in
            self?.state = .unsubscribed
        }
    }

}
