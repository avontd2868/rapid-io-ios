//
//  Collection.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

/// Collection subscription handler which provides a client either with an error or with an array of documents
public typealias RapidCollectionSubscriptionHandler = (_ result: RapidResult<[RapidDocument]>) -> Void

/// Collection subscription handler which provides a client either with an error or with an array of all documents plus with arrays of new, updated and removed documents
public typealias RapidCollectionSubscriptionHandlerWithChanges = (_ result: RapidResult<(documents: [RapidDocument], added: [RapidDocument], updated: [RapidDocument], removed: [RapidDocument])>) -> Void

/// Collection fetch completion handler which provides a client either with an error or with an array of documents
public typealias RapidCollectionFetchCompletion = RapidCollectionSubscriptionHandler

/// Rapid collection reference
public struct RapidCollectionRef: RapidInstanceWithSocketManager {
    
    internal weak var handler: RapidHandler?
    
    /// Collection name
    public let collectionName: String
    
    /// Filters assigned to the collection instance
    public internal(set) var subscriptionFilter: RapidFilter?
    
    /// Order descriptors assigned to the collection instance
    public internal(set) var subscriptionOrdering: [RapidOrdering]?
    
    /// Pagination information assigned to the collection instance
    public internal(set) var subscriptionPaging: RapidPaging?

    init(id: String, handler: RapidHandler!, filter: RapidFilter? = nil, ordering: [RapidOrdering]? = nil, paging: RapidPaging? = nil) {
        self.collectionName = id
        self.handler = handler
        self.subscriptionFilter = filter
        self.subscriptionOrdering = ordering
        self.subscriptionPaging = paging
    }
    
    /// Get an instance of a Rapid document reference with a new unique ID in the collection
    ///
    /// - Returns: Instance of `RapidDocument` in the collection with a new unique ID
    public func newDocument() -> RapidDocumentRef {
        return document(withID: Rapid.uniqueID)
    }
    
    /// Get an instance of a Rapid document reference with a specified ID in the collection
    ///
    /// - Parameter id: Document ID
    /// - Returns: Instance of a `RapidDocument` in the collection with a specified ID
    public func document(withID id: String) -> RapidDocumentRef {
        return try! document(id: id)
    }
    
    /// Get a new collection object with a subscription filtering option assigned
    ///
    /// When the collection already contains a filter the new filter is combined with the original one with logical AND
    ///
    /// - Parameter filter: Filter object
    /// - Returns: The collection with the filter assigned
    public func filter(by filter: RapidFilter) -> RapidCollectionRef {
        var collection = RapidCollectionRef(id: collectionName, handler: handler, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging)
        collection.filtered(by: filter)
        return collection
    }
    
    /// Assign a subscription filtering option to the collection
    ///
    /// When the collection already contains a filter the new filter is combined with the original one with logical AND
    ///
    /// - Parameter filter: Filter object
    public mutating func filtered(by filter: RapidFilter) {
        if let previousFilter = self.subscriptionFilter {
            let compoundFilter = RapidFilter(compoundOperator: .and, operands: [previousFilter, filter])
            self.subscriptionFilter = compoundFilter
        }
        else {
            self.subscriptionFilter = filter
        }
    }
    
    /// Get a new collection object with a subscription ordering assigned
    ///
    /// When the collection already contains an ordering the original ordering is overwriten by the new one
    ///
    /// - Parameter ordering: Ordering object
    /// - Returns: The collection with the ordering assigned
    public func order(by ordering: RapidOrdering) -> RapidCollectionRef {
        var collection = RapidCollectionRef(id: collectionName, handler: handler, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging)
        collection.ordered(by: ordering)
        return collection
    }
    
    /// Assign subscription ordering to the collection
    ///
    /// When the collection already contains an ordering the original ordering is overwriten by the new one
    ///
    /// - Parameter ordering: Ordering object
    public mutating func ordered(by ordering: RapidOrdering) {
        if self.subscriptionOrdering == nil {
            self.subscriptionOrdering = []
        }
        //FIXME: Append ordering when multiple descriptors are done
        self.subscriptionOrdering = [ordering]
    }

    //TODO: Ordering with multiple descriptors
    /*
    /// Get a new collection object with a subscription ordering options assigned
    ///
    /// When the collection already contains an ordering the new ordering is appended to the original one
    ///
    /// - Parameter ordering: Array of ordering objects
    /// - Returns: The collection with the ordering array assigned
    public func order(by ordering: [RapidOrdering]) -> RapidCollectionRef {
        let collection = RapidCollectionRef(id: collectionName, handler: handler, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging)
        collection.ordered(by: ordering)
        return collection
    }
    
    /// Assign subscription ordering options to the collection
    ///
    /// When the collection already contains an ordering the new ordering is appended to the original one
    ///
    /// - Parameter ordering: Array of ordering objects
    public func ordered(by ordering: [RapidOrdering]) {
        if self.subscriptionOrdering == nil {
            self.subscriptionOrdering = []
        }
        self.subscriptionOrdering?.append(contentsOf: ordering)
    }*/
    
    /// Get a new collection object with a subscription limit options assigned
    ///
    /// When the collection already contains a limit the original limit is replaced by the new one
    ///
    /// - Parameters:
    ///   - take: Maximum number of documents to be returned
    /// - Returns: The collection with the limit assigned
    public func limit(to take: Int) -> RapidCollectionRef {
        var collection = RapidCollectionRef(id: collectionName, handler: handler, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging)
        collection.limited(to: take)
        return collection
    }

    /// Assing a subscription limit options to the collection
    ///
    /// When the collection already contains a limit the original limit is replaced by the new one
    ///
    /// - Parameters:
    ///   - take: Maximum number of documents to be returned
    public mutating func limited(to take: Int) {
        self.subscriptionPaging = RapidPaging(take: take)
    }

    //TODO: Implement skip
    /*/// Get a new collection object with a subscription limit options assigned
    ///
    /// When the collection already contains a limit the original limit is replaced by the new one
    ///
    /// - Parameters:
    ///   - take: Maximum number of documents to be returned
    ///   - skip: Number of documents to be skipped
    /// - Returns: The collection with the limit assigned
    public func limit(to take: Int, skip: Int? = nil) -> RapidCollectionRef {
        let collection = RapidCollectionRef(id: collectionName, handler: handler, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging)
        collection.limited(to: take, skip: skip)
        return collection
    }
    
    /// Assing a subscription limit options to the collection
    ///
    /// When the collection already contains a limit the original limit is replaced by the new one
    ///
    /// - Parameters:
    ///   - take: Maximum number of documents to be returned
    ///   - skip: Number of documents to be skipped
    public func limited(to take: Int, skip: Int? = nil) {
        self.subscriptionPaging = RapidPaging(skip: skip, take: take)
    }*/
}

extension RapidCollectionRef: RapidSubscriptionReference {
    
    /// Subscribe for listening to the collection changes
    ///
    /// Only filters, orderings and limits that are assigned to the collection by the time of creating a subscription are applied
    ///
    /// - Parameter block: Subscription handler that provides a client either with an error or with an array of documents
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribe(block: @escaping RapidCollectionSubscriptionHandler) -> RapidSubscription {
        let subscription = RapidCollectionSub(collectionID: collectionName, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging, handler: block, handlerWithChanges: nil)
        
        socketManager.subscribe(toCollection: subscription)
        
        return subscription
    }
    
    /// Subscribe for listening to the collection changes
    ///
    /// Only filters, orderings and limits that are assigned to the collection by the time of creating a subscription are applied
    ///
    /// - Parameter decodableType: Type of object to which should be json coming from Rapid server deserialized
    /// - Parameter decoder: JSON decoder that should be used instead of a default one
    /// - Parameter block: Subscription handler that provides a client either with an error or with an array of documents
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribe<T>(decodableType type: T.Type, decoder: JSONDecoder? = nil, block: @escaping (_ result: RapidResult<[T]>) -> Void) -> RapidSubscription where T: Decodable {
        return self.subscribe { result in
            switch result {
            case .failure(let error):
                block(RapidResult.failure(error: error))
                
            case .success(let documents):
                do {
                    let dec = decoder ?? self.handler?.decoder
                    let object = try documents.decode(toType: type, decoder: dec)
                    block(RapidResult.success(value: object))
                }
                catch let error {
                    block(RapidResult.failure(error: RapidError.decodingFailed(messaage: error.localizedDescription)))
                }
            }
        }
    }

    /// Subscribe for listening to the collection changes
    ///
    /// Only filters, orderings and limits that are assigned to the collection by the time of creating a subscription are applied
    ///
    /// - Parameter block: Subscription handler that provides a client either with an error or with an array of all documents plus with arrays of new, updated and removed documents
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribeWithChanges(block: @escaping RapidCollectionSubscriptionHandlerWithChanges) -> RapidSubscription {
        let subscription = RapidCollectionSub(collectionID: collectionName, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging, handler: nil, handlerWithChanges: block)
        
        socketManager.subscribe(toCollection: subscription)
        
        return subscription
    }

    /// Subscribe for listening to the collection changes
    ///
    /// Only filters, orderings and limits that are assigned to the collection by the time of creating a subscription are applied
    ///
    /// - Parameter decodableType: Type of object to which should be json coming from Rapid server deserialized
    /// - Parameter decoder: JSON decoder that should be used instead of a default one
    /// - Parameter block: Subscription handler that provides a client either with an error or with an array of all documents plus with arrays of new, updated and removed documents
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribeWithChanges<T>(decodableType type: T.Type, decoder: JSONDecoder? = nil, block: @escaping (_ result: RapidResult<(documents: [T], added: [T], updated: [T], removed: [T])>) -> Void) -> RapidSubscription where T: Decodable {
        return self.subscribeWithChanges { result in
            switch result {
            case .failure(let error):
                block(RapidResult.failure(error: error))
                
            case .success(let tuple):
                do {
                    let dec = decoder ?? self.handler?.decoder
                    let documents = try tuple.documents.decode(toType: type, decoder: dec)
                    let added = try tuple.added.decode(toType: type, decoder: dec)
                    let updated = try tuple.updated.decode(toType: type, decoder: dec)
                    let removed = try tuple.removed.decode(toType: type, decoder: dec)
                    block(RapidResult.success(value: (documents, added, updated, removed)))
                }
                catch let error {
                    block(RapidResult.failure(error: RapidError.decodingFailed(messaage: error.localizedDescription)))
                }
            }
        }
    }

}

extension RapidCollectionRef: RapidFetchReference {
    
    /// Fetch collection
    ///
    /// Only documents that match filters, orderings and limits that are assigned to the collection by the time of calling the function, are retured
    ///
    /// - Parameter completion: Fetch completion handler that provides a client either with an error or with an array of documents
    public func fetch(completion: @escaping RapidCollectionFetchCompletion) {
        let fetch = RapidCollectionFetch(collectionID: collectionName, filter: subscriptionFilter, ordering: subscriptionOrdering, paging: subscriptionPaging, cache: handler, completion: completion)
        
        socketManager.fetch(fetch)
    }
    
    /// Fetch collection
    ///
    /// Only documents that match filters, orderings and limits that are assigned to the collection by the time of calling the function, are retured
    ///
    /// - Parameter decodableType: Type of object to which should be json coming from Rapid server deserialized
    /// - Parameter decoder: JSON decoder that should be used instead of a default one
    /// - Parameter completion: Fetch completion handler that provides a client either with an error or with an array of documents
    public func fetch<T>(decodableType type: T.Type, decoder: JSONDecoder? = nil, completion: @escaping (_ result: RapidResult<[T]>) -> Void) where T : Decodable {
        self.fetch { result in
            switch result {
            case .failure(let error):
                completion(RapidResult.failure(error: error))
                
            case .success(let documents):
                do {
                    let dec = decoder ?? self.handler?.decoder
                    let object = try documents.decode(toType: type, decoder: dec)
                    completion(RapidResult.success(value: object))
                }
                catch let error {
                    completion(RapidResult.failure(error: RapidError.decodingFailed(messaage: error.localizedDescription)))
                }
            }
        }
    }

}

extension RapidCollectionRef {
    
    func document(id: String) throws -> RapidDocumentRef {
        if let handler = handler {
            return RapidDocumentRef(id: id, inCollection: collectionName, handler: handler)
        }

        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, level: .critical)
        throw RapidInternalError.rapidInstanceNotInitialized
    }

}
