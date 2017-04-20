//
//  RapidSubscription.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidSubscriptionHashable {
    var subscriptionHash: String { get }
}

/// Protocol describing subscription objects
protocol RapidSubscriptionInstance: class, RapidSerializable, RapidSubscriptionHashable, RapidSubscription {
    /// Hash identifying the subscription
    var subscriptionHash: String { get }
    
    /// Subscription dataset changed
    ///
    /// - Parameters:
    ///   - documents: All documents that meet subscription definition
    ///   - added: Documents that have been added since last call
    ///   - updated: Documents that have been modified since last call
    ///   - removed: Documents that have been removed since last call
    func receivedUpdate(_ documents: [RapidDocumentSnapshot], _ added: [RapidDocumentSnapshot], _ updated: [RapidDocumentSnapshot], _ removed: [RapidDocumentSnapshot])
    
    /// Subscription failed to be registered
    ///
    /// - Parameter error: Failure reason
    func subscriptionFailed(withError error: RapidError)
    
    /// Pass a block of code that should be called when the subscription should be unregistered
    ///
    /// - Parameter callback: Block of code that should be called when the subscription should be unregistered
    func registerUnsubscribeCallback(_ callback: @escaping (RapidSubscriptionInstance) -> Void)
}
