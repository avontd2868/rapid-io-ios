//
//  RapidSubscriptionReference.swift
//  Rapid
//
//  Created by Jan on 13/07/2017.
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

/// Protocol describing Rapid.io reference that defines data subscription
public protocol RapidSubscriptionReference {
    associatedtype Result
    
    /// Subscribe for listening to data changes
    ///
    /// - Parameter block: Subscription handler that provides a client either with an error or with up-to-date data
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    func subscribe(block: @escaping (RapidResult<Result>) -> Void) -> RapidSubscription
}

/// Protocol describing Rapid.io reference that defines data fetch
public protocol RapidFetchReference {
    associatedtype Result
    
    /// Fetch data
    ///
    /// - Parameter completion: Completion handler that provides a client either with an error or with data
    func fetch(completion: @escaping (RapidResult<Result>) -> Void)
}
