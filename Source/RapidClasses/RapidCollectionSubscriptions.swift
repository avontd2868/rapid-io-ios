//
//  RapidSubscription.swift
//  Rapid
//
//  Created by Jan on 28/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Collection subscription

/// Collection subscription object
class RapidCollectionSub: NSObject {
    
    /// Collection ID
    let collectionID: String
    
    /// Subscription filter
    let filter: RapidFilter?
    
    /// Subscription ordering
    let ordering: [RapidOrdering]?
    
    /// Subscription paging
    let paging: RapidPaging?
    
    /// Subscription handler
    let handler: RapidCollectionSubscriptionHandler?
    
    /// Subscription handler with lists of changes
    let handlerWithChanges: RapidCollectionSubscriptionHandlerWithChanges?
    
    /// Block of code to be called when unsubscribing
    fileprivate var unsubscribeHandler: ((RapidSubscriptionInstance) -> Void)?
    
    /// Initialize collection subscription object
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - filter: Subscription filter
    ///   - ordering: Subscription ordering
    ///   - paging: Subscription paging
    ///   - handler: Subscription handler
    ///   - handlerWithChanges: Subscription handler with lists of changes
    init(collectionID: String, filter: RapidFilter?, ordering: [RapidOrdering]?, paging: RapidPaging?, handler: RapidCollectionSubscriptionHandler?, handlerWithChanges: RapidCollectionSubscriptionHandlerWithChanges?) {
        self.collectionID = collectionID
        self.filter = filter
        self.ordering = ordering
        self.paging = paging
        self.handler = handler
        self.handlerWithChanges = handlerWithChanges
    }
    
}

extension RapidCollectionSub: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(subscription: self, withIdentifiers: identifiers)
    }

}

extension RapidCollectionSub: RapidColSubInstance {
    
    /// Subscription identifier
    var subscriptionHash: String {
        return "collection#\(collectionID)#\(filter?.subscriptionHash ?? "")#\(ordering?.map({ $0.subscriptionHash }).joined(separator: "|") ?? "")#\(paging?.subscriptionHash ?? "")"
    }
    
    var subscriptionTake: Int? {
        return paging?.take
    }
    
    var subscriptionOrdering: [RapidOrdering.Ordering]? {
        return ordering?.map({ $0.ordering })
    }
    
    func subscriptionFailed(withError error: RapidError) {
        // Pass error to handler
        DispatchQueue.main.async {
            self.handler?(.failure(error: error))
            self.handlerWithChanges?(.failure(error: error))
        }
    }
    
    /// Assign a block of code that should be called on unsubscribing to `unsubscribeHandler`
    ///
    /// - Parameter block: Block of code that should be called on unsubscribing
    func registerUnsubscribeHandler(_ block: @escaping (RapidSubscriptionInstance) -> Void) {
        unsubscribeHandler = block
    }
    
    func receivedUpdate(_ documents: [RapidDocument], _ added: [RapidDocument], _ updated: [RapidDocument], _ removed: [RapidDocument]) {
        // Pass changes to handler
        DispatchQueue.main.async {
            self.handler?(.success(value: documents))
            self.handlerWithChanges?(.success(value: (documents, added, updated, removed) ))
        }
    }
    
}

extension RapidCollectionSub: RapidSubscription {
    
    /// Unregister subscription
    func unsubscribe() {
        unsubscribeHandler?(self)
    }
    
}

// MARK: Document subscription

/// Document subscription object
///
/// The class is a wrapper for `RapidCollectionSub`. Internally, it creates collection subscription filtered by `RapidFilterSimple.documentIdKey` = `documentID`
class RapidDocumentSub: NSObject {
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Subscription handler
    let handler: RapidDocumentSubscriptionHandler?
    
    /// Underlying collection subscription object
    fileprivate(set) var subscription: RapidCollectionSub!
    
    /// Block of code to be called when unsubscribing
    fileprivate var unsubscribeHandler: ((RapidSubscriptionInstance) -> Void)?
    
    /// Initialize document subscription object
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - handler: Subscription handler
    init(collectionID: String, documentID: String, handler: RapidDocumentSubscriptionHandler?) {
        self.collectionID = collectionID
        self.documentID = documentID
        self.handler = handler
        
        super.init()
        
        self.subscription = RapidCollectionSub(collectionID: collectionID, filter: RapidFilterSimple(keyPath: RapidFilterSimple.docIdKey, relation: .equal, value: documentID), ordering: nil, paging: nil, handler: nil, handlerWithChanges: nil)
    }
}

extension RapidDocumentSub: RapidSerializable {

    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try subscription.serialize(withIdentifiers: identifiers)
    }
    
}

extension RapidDocumentSub: RapidColSubInstance {
    
    var subscriptionHash: String {
        return subscription.subscriptionHash
    }
    
    var subscriptionTake: Int? {
        return 1
    }
    
    var subscriptionOrdering: [RapidOrdering.Ordering]? {
        return nil
    }
    
    func subscriptionFailed(withError error: RapidError) {
        // Pass error to handler
        DispatchQueue.main.async {
            self.handler?(.failure(error: error))
        }
    }
    
    func registerUnsubscribeHandler(_ block: @escaping (RapidSubscriptionInstance) -> Void) {
        unsubscribeHandler = block
    }
    
    func receivedUpdate(_ documents: [RapidDocument], _ added: [RapidDocument], _ updated: [RapidDocument], _ removed: [RapidDocument]) {
        // Pass changes to handler
        DispatchQueue.main.async {
            self.handler?(.success(value: documents.last ?? RapidDocument(removedDocId: self.documentID, collectionID: self.collectionID)))
        }
    }
    
}

extension RapidDocumentSub: RapidSubscription {
    
    func unsubscribe() {
        unsubscribeHandler?(self)
    }
}
