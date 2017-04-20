//
//  RapidSubscriptionHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

fileprivate func == (lhs: RapidDocSnapOperation, rhs: RapidDocSnapOperation) -> Bool {
    return lhs.snapshot.id == rhs.snapshot.id
}

/// Struct describing what happened with a document since previous subscription update
fileprivate struct RapidDocSnapOperation: Hashable {
    enum Operation {
        case add
        case update
        case remove
        case none
    }
    
    let snapshot: RapidDocumentSnapshot
    let operation: Operation
    
    var hashValue: Int {
        return snapshot.id.hashValue
    }
}

/// Wrapper for a set of `RPDSnapshotOperation`
///
/// Set updates are treated specially because operations have different priority
fileprivate struct RapidDocSnapOperationSet: Sequence {
    
    fileprivate var set = Set<RapidDocSnapOperation>()
    
    /// Inserts or updates the given element into the set
    ///
    /// - Parameter operation: An element to insert into the set.
    mutating func insertOrUpdate(_ operation: RapidDocSnapOperation) {
        if let index = set.index(of: operation) {
            let previousOperation = set[index]
            
            switch (previousOperation.operation, operation.operation) {
            case (.none, .add), (.none, .update), (.none, .remove), (.update, .remove):
                set.update(with: operation)
                
            case (.add, .add), (.add, .update), (.update, .add), (.update, .update), (.remove, .update), (.remove, .remove), (.add, .none), (.update, .none), (.remove, .none), (.none, .none):
                break
                
            case (.add, .remove):
                set.remove(at: index)
                
            case (.remove, .add):
                set.update(with: RapidDocSnapOperation(snapshot: operation.snapshot, operation: .update))
            }
        }
        else {
            set.insert(operation)
        }
    }
    
    /// Inserts the given element into the set unconditionally
    ///
    /// - Parameter operation: An element to insert into the set
    mutating func update(_ operation: RapidDocSnapOperation) {
        set.update(with: operation)
    }
    
    /// Adds the elements of the given array to the set
    ///
    /// - Parameter other: An array of document snapshots
    mutating func formUnion(_ other: [RapidDocSnapOperation]) {
        set.formUnion(other)
    }
    
    /// Returns an iterator over the elements of this sequence
    ///
    /// - Returns: Iterator
    func makeIterator() -> SetIterator<RapidDocSnapOperation> {
        return set.makeIterator()
    }
}

/// Subscription handler delegate
protocol RapidSubscriptionHandlerDelegate: class {
    /// Dedicated queue for parsing
    var dispatchQueue: DispatchQueue { get }
    
    /// Cache handler
    var cacheHandler: RapidCacheHandler? { get }
    
    /// Method for unregistering a subscription
    ///
    /// - Parameter handler: Unsubscription handler
    func unsubscribe(handler: RapidUnsubscriptionHandler)
}

/// Class that handles all subscriptions which listen to the same dataset
class RapidSubscriptionHandler: NSObject {
    
    /// Subscripstion state
    enum State {
        case unsubscribed
        case registering
        case subscribed
        case unsubscribing
    }
    
    /// Hash that identifies subscriptions handled by the class
    ///
    /// Subscriptions that listen to the same dataset have equal hashes
    var subscriptionHash: String {
        return subscriptions.first?.subscriptionHash ?? ""
    }
    
    /// ID of subscription
    let subscriptionID: String
    
    /// Handler delegate
    fileprivate weak var delegate: RapidSubscriptionHandlerDelegate?
    
    /// Array of subscription objects
    fileprivate var subscriptions: [RapidSubscriptionInstance] = []
    
    /// Last known value of the dataset
    fileprivate var value: [RapidDocumentSnapshot]? {
        didSet {
            if let value = value {
                // Store last known value to a cache
                delegate?.cacheHandler?.storeValue(NSArray(array: value), forSubscription: self)
            }
        }
    }
    
    /// Subscription state
    fileprivate var state: State = .unsubscribed
    
    /// Handler initializer
    ///
    /// - Parameters:
    ///   - subscriptionID: Subscription ID
    ///   - subscription: Subscription object
    ///   - dispatchQueue: `SocketManager` dedicated thread for parsing
    ///   - unsubscribeHandler: Block of code which must be called to unregister the subscription
    init(withSubscriptionID subscriptionID: String, subscription: RapidSubscriptionInstance, delegate: RapidSubscriptionHandlerDelegate?) {
        self.subscriptionID = subscriptionID
        self.delegate = delegate
        
        super.init()
        
        state = .registering
        appendSubscription(subscription)
        
        loadCachedData()
    }
    
    /// Add another subscription object to the handler
    ///
    /// - Parameter subscription: New subscription object
    func registerSubscription(subscription: RapidSubscriptionInstance) {
        delegate?.dispatchQueue.async {
            self.appendSubscription(subscription)
            
            // Pass the last known value immediatelly if there is any
            if let value = self.value {
                subscription.receivedUpdate(value, value, [], [])
            }
        }
    }
    
    /// Unsubscribe handler
    ///
    /// - Parameter handler: Previously creaated unsubscription handler
    func retryUnsubscription(withHandler handler: RapidUnsubscriptionHandler) {
        delegate?.dispatchQueue.async { [weak self] in
            if self?.state == .unsubscribing {
                self?.delegate?.unsubscribe(handler: handler)
            }
        }
    }
    
    /// Inform handler about being unsubscribed
    func didUnsubscribe() {
        delegate?.dispatchQueue.async { [weak self] in
            self?.state = .unsubscribed
        }
    }
}

extension RapidSubscriptionHandler: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        if let subscription = subscriptions.first {
            var idef = identifiers
            
            idef[RapidSerialization.Subscription.SubscriptionID.name] = subscriptionID
            
            return try subscription.serialize(withIdentifiers: idef)
        }
        else {
            throw RapidError.invalidData(reason: .serializationFailure)
        }
    }
}

fileprivate extension RapidSubscriptionHandler {
    
    /// Load cached data if there are any
    func loadCachedData() {
        delegate?.cacheHandler?.loadSubscriptionValue(forSubscription: self, completion: { [weak self] (cachedValue) in
            self?.delegate?.dispatchQueue.async {
                if let subscriptionID = self?.subscriptionID, self?.value == nil, let cachedValue = cachedValue as? [RapidDocumentSnapshot] {
                    let batch = RapidSubscriptionBatch(withSubscriptionID: subscriptionID, collection: cachedValue)
                    self?.receivedNewValue(batch)
                }
            }
        })
    }
    
    /// Add a new subscription object
    ///
    /// - Parameter subscription: New subscription object
    func appendSubscription(_ subscription: RapidSubscriptionInstance) {
        subscription.registerUnsubscribeCallback { [weak self] instance in
            self?.delegate?.dispatchQueue.async {
                self?.unsubscribe(instance: instance)
            }
        }
        subscriptions.append(subscription)
    }
    
    /// Updated dataset received from the server
    ///
    /// - Parameter newValue: Updated dataset
    func receivedNewValue(_ update: RapidSubscriptionBatch) {
        let updates = incorporate(batch: update, oldValue: value)
        
        // Inform subscriptions only if any change occured
        guard updates.insert.count > 0 || updates.update.count > 0 || updates.delete.count > 0 || value == nil else {
            value = updates.dataSet
            return
        }
        
        // Inform all subscription objects
        for subsription in subscriptions {
            subsription.receivedUpdate(updates.dataSet, updates.insert, updates.update, updates.delete)
        }
        
        value = updates.dataSet
    }
    
    /// Proces updated dataset
    ///
    /// - Parameters:
    ///   - rawArray: Updated documents
    ///   - oldValue: Last known dataset
    /// - Returns: Tuple with a new dataset and arrays of new, updated and removed documents
    func incorporate(batch: RapidSubscriptionBatch, oldValue: [RapidDocumentSnapshot]?) -> (dataSet: [RapidDocumentSnapshot], insert: [RapidDocumentSnapshot], update: [RapidDocumentSnapshot], delete: [RapidDocumentSnapshot]) {
        
        var updates = RapidDocSnapOperationSet()
        
        // Store previously known dataset to `documents`
        // If there is a new complete dataset in the update work with it
        // If there is no previous dataset work with a collection from the update
        var documents: [RapidDocumentSnapshot]
        
        if var oldValue = oldValue, let collection = batch.collection {
            documents = collection.flatMap({ $0.value == nil ? nil : $0 })
            
            // Firstly, consider all original documents as being removed
            // Their status will be changed if they are present in the new dataset from update
            updates.formUnion(oldValue.map { RapidDocSnapOperation(snapshot: $0, operation: .remove) })
            
            for document in documents {
                let operation = incorporate(document: document, inCollection: &oldValue, mutateCollection: false)
                updates.update(operation)
            }
        }
        else if let oldValue = oldValue {
            documents = oldValue
        }
        else {
            documents = batch.collection?.flatMap({ $0.value == nil ? nil : $0 }) ?? []
            updates.formUnion(documents.map { RapidDocSnapOperation(snapshot: $0, operation: .add) })
        }
        
        // Loop through updated documents
        for update in batch.updates {
            let operation = incorporate(update: update, inCollection: &documents)
            updates.insertOrUpdate(operation)
        }
        
        // If there was no previous dataset consider all values as new
        // Otherwise, deal with different types of updates
        if oldValue == nil {
            return (documents, documents, [], [])
        }

        var inserted = [RapidDocumentSnapshot]()
        var updated = [RapidDocumentSnapshot]()
        var deleted = [RapidDocumentSnapshot]()
        
        // Sort updates according to type
        for document in updates {
            switch document.operation {
            case .add:
                inserted.append(document.snapshot)
                
            case .update:
                updated.append(document.snapshot)
                
            case .remove:
                deleted.append(document.snapshot)
                
            case .none:
                break
            }
        }
        
        return (documents, inserted, updated, deleted)
    }

    /// Sort the update in the collection
    ///
    /// - Parameters:
    ///   - update: Update to process
    ///   - documents: Original collection
    /// - Returns: Resulting `RapidDocumentSnapshotOperation`
    func incorporate(update: RapidSubscriptionUpdate, inCollection documents: inout [RapidDocumentSnapshot]) -> RapidDocSnapOperation {
        return incorporate(document: update.snapshot, withPredecessor: update.predecessorID, inCollection: &documents)
    }
    
    /// Sort the document in the collection
    ///
    /// - Parameters:
    ///   - document: Document to process
    ///   - predID: Predecessor ID
    ///   - documents: Original collection
    ///   - mutateCollection: Set to `true` if `documents` array should be mutated
    /// - Returns: Resulting `RapidDocumentSnapshotOperation`
    func incorporate(document: RapidDocumentSnapshot, withPredecessor predID: String? = nil, inCollection documents: inout [RapidDocumentSnapshot], mutateCollection: Bool = true) -> RapidDocSnapOperation {
        // Index of the document in the last known dataset
        let index = documents.index(where: { $0.id == document.id })
        
        // If etag of the document hasn't changed the document itself hasn't changed
        if let index = index, documents[index].etag == document.etag {
            return RapidDocSnapOperation(snapshot: document, operation: .none)
        }
        // If the document was removed
        else if document.value == nil {
            let removedDoc: RapidDocumentSnapshot
            
            if mutateCollection, let index = index {
                removedDoc = documents.remove(at: index)
                
                return RapidDocSnapOperation(snapshot: removedDoc, operation: .remove)
            }
            else if !mutateCollection, let index = index {
                removedDoc = documents[index]
                
                return RapidDocSnapOperation(snapshot: removedDoc, operation: .remove)
            }
            
            return RapidDocSnapOperation(snapshot: document, operation: .none)
        }
        // If the document has a predecessor and the predecessor is in the last known dataset
        else if let predID = predID, let predIndex = documents.index(where: { $0.id == predID }) {
            // If the document is in the last known dataset update it and move it to the correct index
            // Otherwise, just insert it to the correct index
            if !mutateCollection {
                return RapidDocSnapOperation(snapshot: document, operation: index == nil ? .add : .update)
            }
            else if let index = index {
                let newIndex = predIndex < index ? predIndex + 1 : predIndex
                
                if newIndex == index {
                    documents[newIndex] = document
                }
                else {
                    documents.remove(at: index)
                    documents.insert(document, at: newIndex)
                }
                
                return RapidDocSnapOperation(snapshot: document, operation: .update)
            }

            documents.insert(document, at: predIndex + 1)
            return RapidDocSnapOperation(snapshot: document, operation: .add)
        }
        // If the document doesn't have a predecessor, but it is in the last known dataset update it and move it to the index 0
        else if let index = index {
            
            if mutateCollection {
                documents.remove(at: index)
                documents.insert(document, at: 0)
            }
            
            return RapidDocSnapOperation(snapshot: document, operation: .update)
        }
        
        // If the document doesn't have a predecessor and it isn't in the last known dataset insert it to the index 0
        if mutateCollection {
            documents.insert(document, at: 0)
        }
        return RapidDocSnapOperation(snapshot: document, operation: .add)
    }
    
    /// Unregister subscription object from listening to the dataset changes
    ///
    /// - Parameter instance: Subscription object
    func unsubscribe(instance: RapidSubscriptionInstance) {
        // If there is only one subscription object unsubscribe alse the handler
        // Otherwise just remove the subscription object from array of registered subscription objects
        if subscriptions.count == 1 {
            state = .unsubscribing
            delegate?.unsubscribe(handler: RapidUnsubscriptionHandler(subscription: self))
        }
        else if let index = subscriptions.index(where: { $0 === instance }) {
            subscriptions.remove(at: index)
        }
    }
}

extension RapidSubscriptionHandler: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        delegate?.dispatchQueue.async {
            self.state = .subscribed
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        delegate?.dispatchQueue.async {
            self.state = .unsubscribed
            
            for subscription in self.subscriptions {
                subscription.subscriptionFailed(withError: error.error)
            }
        }
    }
    
    func receivedSubscriptionEvent(_ update: RapidSubscriptionBatch) {
        delegate?.dispatchQueue.async {
            self.receivedNewValue(update)
        }
    }
}

// MARK: Unsubscription handler

// Wrapper for `RapidSubscriptionHandler` that handles unsubscription
class RapidUnsubscriptionHandler: NSObject {
    
    let subscription: RapidSubscriptionHandler
    
    init(subscription: RapidSubscriptionHandler) {
        self.subscription = subscription
    }
    
}

extension RapidUnsubscriptionHandler: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(unsubscription: self, withIdentifiers: identifiers)
    }
}

extension RapidUnsubscriptionHandler: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        subscription.didUnsubscribe()
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        subscription.retryUnsubscription(withHandler: self)
    }
}
