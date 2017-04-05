//
//  RapidSubscriptionHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

fileprivate func == (lhs: RapidDocumentSnapshotOperation, rhs: RapidDocumentSnapshotOperation) -> Bool {
    return lhs.snapshot.id == rhs.snapshot.id
}

fileprivate class RapidDocumentSnapshotOperation: Hashable {
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
    
    init(snapshot: RapidDocumentSnapshot, operation: Operation) {
        self.snapshot = snapshot
        self.operation = operation
    }
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
    
    /// Requst waits for acknowledgement
    let needsAcknowledgement = true
    
    /// ID of subscription
    let subscriptionID: String
    
    /// Dedicated thread inheritited from `SocketManager`
    fileprivate let dispatchQueue: DispatchQueue
    
    /// Block of code which must be called to unregister the subscription
    fileprivate let unsubscribeHandler: (RapidUnsubscriptionHandler) -> Void
    
    /// Array of subscription objects
    fileprivate var subscriptions: [RapidSubscriptionInstance] = []
    
    /// Last known value of the dataset
    fileprivate var value: [RapidDocumentSnapshot]?
    
    /// Subscription state
    fileprivate var state: State = .unsubscribed
    
    /// Handler initializer
    ///
    /// - Parameters:
    ///   - subscriptionID: Subscription ID
    ///   - subscription: Subscription object
    ///   - dispatchQueue: `SocketManager` dedicated thread for parsing
    ///   - unsubscribeHandler: Block of code which must be called to unregister the subscription
    init(withSubscriptionID subscriptionID: String, subscription: RapidSubscriptionInstance, dispatchQueue: DispatchQueue, unsubscribeHandler: @escaping (RapidUnsubscriptionHandler) -> Void) {
        self.unsubscribeHandler = unsubscribeHandler
        self.subscriptionID = subscriptionID
        self.dispatchQueue = dispatchQueue
        
        super.init()
        
        state = .registering
        appendSubscription(subscription)
    }
    
    /// Add another subscription object to the handler
    ///
    /// - Parameter subscription: New subscription object
    func registerSubscription(subscription: RapidSubscriptionInstance) {
        dispatchQueue.async { [weak self] in
            self?.appendSubscription(subscription)
            
            // If the handler is subscribed pass the last known value immediatelly
            if self?.state == .subscribed, let value = self?.value {
                subscription.receivedUpdate(value, value, [], [])
            }
        }
    }
    
    /// Unsubscribe handler
    ///
    /// - Parameter handler: Previously creaated unsubscription handler
    func retryUnsubscription(withHandler handler: RapidUnsubscriptionHandler) {
        dispatchQueue.async { [weak self] in
            if self?.state == .unsubscribing {
                self?.unsubscribeHandler(handler)
            }
        }
    }
    
    /// Inform handler about being unsubscribed
    func didUnsubscribe() {
        dispatchQueue.async { [weak self] in
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
    
    /// Add a new subscription object
    ///
    /// - Parameter subscription: New subscription object
    func appendSubscription(_ subscription: RapidSubscriptionInstance) {
        subscription.registerUnsubscribeCallback { [weak self] instance in
            self?.dispatchQueue.async {
                self?.unsubscribe(instance: instance)
            }
        }
        subscriptions.append(subscription)
    }
    
    /// Updated dataset received from the server
    ///
    /// - Parameter newValue: Updated dataset
    func receivedNewValue(_ update: RapidSubscriptionBatch) {
        let updates = incorporateChanges(update: update, oldValue: value)
        
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
    func incorporateChanges(update: RapidSubscriptionBatch, oldValue: [RapidDocumentSnapshot]?) -> (dataSet: [RapidDocumentSnapshot], insert: [RapidDocumentSnapshot], update: [RapidDocumentSnapshot], delete: [RapidDocumentSnapshot]) {
        
        var updates = Set<RapidDocumentSnapshotOperation>()
        
        // Store previously known dataset to `documents`
        // If there is no previous dataset work with a collection from the update
        var documents: [RapidDocumentSnapshot]
        if let oldValue = oldValue {
            documents = oldValue
            
            // Incorporate new dataset from the udpate
            if let collection = update.collection?.flatMap({ $0.value == nil ? nil : $0 }) {
                // Firstly, consider all original documents as being removed
                // Their status will be changed to updated if they are present in the new dataset from update
                updates.formUnion(documents.map { RapidDocumentSnapshotOperation(snapshot: $0, operation: .remove) })
                
                for document in collection {
                    let operation = incorporate(document: document, inCollection: &documents)
                    updates.update(with: operation)
                }
            }
        }
        else {
            documents = update.collection?.flatMap({ $0.value == nil ? nil : $0 }) ?? []
            updates.formUnion(documents.map { RapidDocumentSnapshotOperation(snapshot: $0, operation: .add) })
        }
        
        // Loop through updated documents
        for document in update.updates {
            let operation = incorporate(document: document, inCollection: &documents)
            updates.update(with: operation)
        }
        
        // If there was no previous dataset consider all values as new
        // Otherwise, deal with different types of updates
        if oldValue == nil {
            return (documents, documents, [], [])
        }
        else {
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
    }

    /// Sort the document in the collection
    ///
    /// - Parameters:
    ///   - document: Document to process
    ///   - documents: Original collection
    /// - Returns: Resulting `RapidDocumentSnapshotOperation`
    func incorporate(document: RapidDocumentSnapshot, inCollection documents: inout [RapidDocumentSnapshot]) -> RapidDocumentSnapshotOperation {
        // Index of the document in the last known dataset
        let index = documents.index(where: { $0.id == document.id })
        
        // If etag of the document hasn't changed the document itself hasn't changed
        if let index = index, documents[index].etag == document.etag {
            return RapidDocumentSnapshotOperation(snapshot: document, operation: .none)
        }
        // If the document was removed
        else if let index = index, document.value == nil {
            let document = documents.remove(at: index)
            return RapidDocumentSnapshotOperation(snapshot: document, operation: .remove)
        }
        // If the document has a predecessor and the predecessor is in the last known dataset
        else if let predID = document.predecessorID, let predIndex = documents.index(where: { $0.id == predID }) {
            // If the document is in the last known dataset update it and move it to the correct index
            // Otherwise, just insert it to the correct index
            if let index = index {
                let newIndex = predIndex < index ? predIndex + 1 : predIndex
                
                if newIndex == index {
                    documents[newIndex] = document
                }
                else {
                    documents.remove(at: index)
                    documents.insert(document, at: newIndex)
                }
                
                return RapidDocumentSnapshotOperation(snapshot: document, operation: .update)
            }
            else {
                documents.insert(document, at: predIndex + 1)
                return RapidDocumentSnapshotOperation(snapshot: document, operation: .add)
            }
        }
        // If the document doesn't have a predecessor, but it is in the last known dataset update it and move it to the index 0
        else if let index = index {
            documents.remove(at: index)
            documents.insert(document, at: 0)
            return RapidDocumentSnapshotOperation(snapshot: document, operation: .update)
        }
        // If the document doesn't have a predecessor and it isn't in the last known dataset insert it to the index 0
        else {
            documents.insert(document, at: 0)
            return RapidDocumentSnapshotOperation(snapshot: document, operation: .add)
        }
    }
    
    /// Unregister subscription object from listening to the dataset changes
    ///
    /// - Parameter instance: Subscription object
    func unsubscribe(instance: RapidSubscriptionInstance) {
        // If there is only one subscription object unsubscribe alse the handler
        // Otherwise just remove the subscription object from array of registered subscription objects
        if subscriptions.count == 1 {
            state = .unsubscribing
            unsubscribeHandler(RapidUnsubscriptionHandler(subscription: self))
        }
        else if let index = subscriptions.index(where: { $0 === instance }) {
            subscriptions.remove(at: index)
        }
    }
}

extension RapidSubscriptionHandler: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        dispatchQueue.async { [weak self] in
            self?.state = .subscribed
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        dispatchQueue.async { [weak self] in
            self?.state = .unsubscribed
            
            for subscription in self?.subscriptions ?? [] {
                subscription.subscriptionFailed(withError: error.error)
            }
        }
    }
    
    func receivedSubscriptionEvent(_ update: RapidSubscriptionBatch) {
        dispatchQueue.async { [weak self] in
            self?.receivedNewValue(update)
        }
    }
}

// MARK: Unsubscription handler

// Wrapper for `RapidSubscriptionHandler` that handles unsubscription
class RapidUnsubscriptionHandler: NSObject {
    
    let subscription: RapidSubscriptionHandler
    
    /// Requst waits for acknowledgement
    let needsAcknowledgement = true
    
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
