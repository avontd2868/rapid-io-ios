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

/// Protocol describing Rapid.io request that modifies data in a database
public protocol RapidWriteRequest {
    /// Cancel the request
    ///
    /// This method cancels either a scheduled action or a repeating action
    ///
    /// This operation does not work as a rollback
    /// It's not guaranteed that a data modification will not be performed
    func cancel()
}

/// Protocol describing Rapid.io reference that defines data mutation
public protocol RapidMutationReference {
    associatedtype MutationValue
    associatedtype MutationResult
    
    /// Mutate data
    ///
    /// Current data are deleted and replaced by the provided data
    ///
    /// - Parameters:
    ///   - value: New data
    ///   - completion: Mutation completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    func mutate(value: MutationValue, completion: ((RapidResult<MutationResult>) -> Void)?) -> RapidWriteRequest
}

/// Protocol describing Rapid.io reference that defines data merge
public protocol RapidMergeReference {
    associatedtype MergeValue
    associatedtype MergeResult
    
    /// Merge current data with a provided data
    ///
    /// - Parameters:
    ///   - value: New data
    ///   - completion: Merge completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    func merge(value: MergeValue, completion: ((RapidResult<MergeResult>) -> Void)?) -> RapidWriteRequest
}

/// Protocol describing Rapid.io reference that defines data deletion
public protocol RapidDeletionReference {
    associatedtype DeletionResult
    
    /// Delete data
    ///
    /// - Parameter completion: Deletion completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    func delete(completion: ((RapidResult<DeletionResult>) -> Void)?) -> RapidWriteRequest
}
