//
//  Collection.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Collection subscription callback which provides a client either with an error or with an array of documents
public typealias RapidColSubCallback = (_ error: Error?, _ value: [RapidDocumentSnapshot]) -> Void

/// Collection subscription callback which provides a client either with an error or with an array of all documents plus with arrays of new, updated and removed documents
public typealias RapidColSubCallbackWithChanges = (_ error: Error?, _ value: [RapidDocumentSnapshot], _ added: [RapidDocumentSnapshot], _ updated: [RapidDocumentSnapshot], _ removed: [RapidDocumentSnapshot]) -> Void

/// Class representing Rapid.io collection
public class RapidCollection: NSObject {
    
    weak var handler: RapidHandler?
    var socketManager: SocketManager {
        return try! getSocketManager()
    }
    
    /// Collection identifier
    public let collectionID: String
    
    /// Filters assigned to the collection instance
    public fileprivate(set) var subscriptionFilter: RapidFilter?
    
    /// Order descriptors assigned to the collection instance
    public fileprivate(set) var subscriptionOrdering: [RapidOrdering]?
    
    /// Pagination information assigned to the collection instance
    public fileprivate(set) var subscriptionPaging: RapidPaging?

    init(id: String, handler: RapidHandler) {
        self.collectionID = id
        self.handler = handler
    }
    
    /// Create an instance of a Rapid document in the collection with a new unique ID
    ///
    /// - Returns: Instance of `RapidDocument` in the collection with a new unique ID
    public func newDocument() -> RapidDocument {
        return document(withID: Rapid.uniqueID)
    }
    
    /// Get an instance of a Rapid document in the collection with a specified ID
    ///
    /// - Parameter id: Document ID
    /// - Returns: Instance of a `RapidDocument` in the collection with a specified ID
    public func document(withID id: String) -> RapidDocument {
        return try! document(id: id)
    }
    
    /// Assign an filtering option to the collection which is applied for subscription
    ///
    /// When the collection already contains a filter the new filter is combined with the original one with logical AND
    ///
    /// - Parameter filter: Filter object
    /// - Returns: The collection with the filter assigned
    public func filter(by filter: RapidFilter) -> RapidCollection {
        if let previousFilter = self.subscriptionFilter {
            let compoundFilter = RapidFilterCompound(compoundOperator: .and, operands: [previousFilter, filter])
            self.subscriptionFilter = compoundFilter
        }
        else {
            self.subscriptionFilter = filter
        }
        return self
    }
    
    /// Assign ordering options to the collection which are applied for subscription
    ///
    /// An ordering with the array index 0 has the highest priority.
    /// When the collection already contains an ordering the new ordering is appended to the original one
    ///
    /// - Parameter ordering: Ordering object
    /// - Returns: The collection with the ordering array assigned
    public func order(by ordering: RapidOrdering) -> RapidCollection {
        if self.subscriptionOrdering == nil {
            self.subscriptionOrdering = []
        }
        self.subscriptionOrdering?.append(ordering)
        return self
    }
    
    /// Assign an ordering option to the collection which is applied for subscription
    ///
    /// When the collection already contains an ordering the new ordering is appended to the original one
    ///
    /// - Parameter ordering: Array of ordering objects
    /// - Returns: The collection with the ordering array assigned
    public func order(by ordering: [RapidOrdering]) -> RapidCollection {
        if self.subscriptionOrdering == nil {
            self.subscriptionOrdering = []
        }
        self.subscriptionOrdering?.append(contentsOf: ordering)
        return self
    }
    
    /// Assing an limit options to the collection which are applied for subscription
    ///
    /// When the collection already contains a limit the original limit is replaced by the new one
    ///
    /// - Parameters:
    ///   - take: Maximum number of documents to be returned
    ///   - skip: Number of documents to be skipped
    /// - Returns: The collection with the limit assigned
    public func limit(to take: Int, skip: Int? = nil) -> RapidCollection {
        
        self.subscriptionPaging = RapidPaging(skip: skip, take: take)
        return self
    }
    
    /// Subscribe for listening to the collection changes
    ///
    /// Only filters, orderings and limits that are assigned to the collection by the time of creating a subscription are applied
    ///
    /// - Parameter completion: Subscription callback which provides a client either with an error or with an array of documents
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribe(completion: @escaping RapidColSubCallback) -> RapidSubscription {
        let subscription = RapidCollectionSub(collectionID: collectionID, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging, callback: completion, callbackWithChanges: nil)
        
        socketManager.subscribe(subscription)
        
        return subscription
    }
    
    /// Subscribe for listening to the collection changes
    ///
    /// Only filters, orderings and limits that are assigned to the collection by the time of creating a subscription are applied
    ///
    /// - Parameter completion: Subscription callback which provides a client either with an error or with an array of all documents plus with arrays of new, updated and removed documents
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribe(completionWithChanges completion: @escaping RapidColSubCallbackWithChanges) -> RapidSubscription {
        let subscription = RapidCollectionSub(collectionID: collectionID, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging, callback: nil, callbackWithChanges: completion)
        
        socketManager.subscribe(subscription)
        
        return subscription
    }
}

fileprivate extension RapidCollection {
    
    func document(id: String) throws -> RapidDocument {
        if let handler = handler {
            return RapidDocument(id: id, inCollection: collectionID, handler: handler)
        }
        else {
            print(RapidInternalError.rapidInstanceNotInitialized.message)
            throw RapidInternalError.rapidInstanceNotInitialized
        }
    }
    
    func getSocketManager() throws -> SocketManager {
        if let manager = handler?.socketManager {
            return manager
        }
        else {
            print(RapidInternalError.rapidInstanceNotInitialized.message)
            throw RapidInternalError.rapidInstanceNotInitialized
        }
    }

}
