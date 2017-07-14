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
    associatedtype SubscriptionResult
    
    /// Subscribe for listening to data changes
    ///
    /// - Parameter block: Subscription handler that provides a client either with an error or with up-to-date data
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    func subscribe(block: @escaping (RapidResult<SubscriptionResult>) -> Void) -> RapidSubscription
}

/// Protocol describing Rapid.io reference that defines data fetch
public protocol RapidFetchReference {
    associatedtype FetchResult
    
    /// Fetch data
    ///
    /// - Parameter completion: Completion handler that provides a client either with an error or with data
    func fetch(completion: @escaping (RapidResult<FetchResult>) -> Void)
}

public protocol RapidWriteRequest {
    func cancel()
}

public protocol RapidMutationReference {
    associatedtype MutationValue
    associatedtype MutationResult
    
    @discardableResult
    func mutate(value: MutationValue, completion: ((RapidResult<MutationResult>) -> Void)?) -> RapidWriteRequest
}

public protocol RapidMergeReference {
    associatedtype MergeValue
    associatedtype MergeResult
    
    @discardableResult
    func merge(value: MergeValue, completion: ((RapidResult<MergeResult>) -> Void)?) -> RapidWriteRequest
}

public protocol RapidDeletionReference {
    associatedtype DeletionResult
    
    @discardableResult
    func delete(completion: ((RapidResult<DeletionResult>) -> Void)?) -> RapidWriteRequest
}
