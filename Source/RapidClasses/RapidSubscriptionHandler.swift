//
//  RapidSubscriptionHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

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
    ///   - dispatchQueue: `SocketManager` dedicated thread
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
        appendSubscription(subscription)
        
        // If the handler is subscribed pass the last known value immediatelly
        if state == .subscribed, let value = value {
            subscription.receivedUpdate(value, value, [], [])
        }
    }
    
    /// Unsubscribe handler
    ///
    /// - Parameter handler: Previously creaated unsubscription handler
    func retryUnsubscription(withHandler handler: RapidUnsubscriptionHandler) {
        if state == .unsubscribing {
            unsubscribeHandler(handler)
        }
    }
    
    /// Inform handler about being unsubscribed
    func didUnsubscribe() {
        state = .unsubscribed
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
            throw RapidError.invalidData
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
    func receivedNewValue(_ newValue: [RapidDocumentSnapshot]) {
        let updates = incorporateChanges(newValue: newValue, oldValue: value)
        
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
    func incorporateChanges(newValue rawArray: [RapidDocumentSnapshot], oldValue: [RapidDocumentSnapshot]?) -> (dataSet: [RapidDocumentSnapshot], insert: [RapidDocumentSnapshot], update: [RapidDocumentSnapshot], delete: [RapidDocumentSnapshot]) {
        
        // Firstly, duplicates need to be removed
        var newValue = rawArray
        var removeIndexes = [Int]()
        var swapIndexes = [(Int, Int)]()
        var indexForDocument = [String: Int]()
        
        // Loop through updated documents
        for (index, document) in rawArray.enumerated() {
            // `existingIndex` if not nil is always lower than `index`
            let existingIndex = indexForDocument[document.id]
            
            // If this is the first occurance of the document just register its array index
            if existingIndex == nil {
                indexForDocument[document.id] = index
            }
            // If the document has occured, but this is the first time the handler received any data from the server
            else if oldValue == nil, let existingIndex = existingIndex {
                // Replace a document with a lower index by a document with a higher index and remove a document which used to have a lower index and now has a higher index
                // Exlanation: A document with a higher index is newer and since these are the first data from the server we want to preserve the ordering
                swapIndexes.append((existingIndex, index))
                removeIndexes.append(index)
            }
            // If the document has occured and the handler has already received any data from the server
            else if let existingIndex = existingIndex {
                // Remove an outdated document with a lower index and keep just an updated document with a higher index
                indexForDocument[document.id] = index
                removeIndexes.append(existingIndex)
            }
        }
        
        // Process swaps and removings
        for swap in swapIndexes {
            let tmp = newValue[swap.0]
            newValue[swap.0] = newValue[swap.1]
            newValue[swap.1] = tmp
        }
        for index in removeIndexes.reversed() {
            newValue.remove(at: index)
        }
        
        // If this is the first time the handler received any data from the server
        guard var documents = oldValue else {
            // Remove documents with no values (those documents have been removed)
            let dataSet = newValue.flatMap({ $0.value == nil ? nil : $0 })
            return (dataSet, dataSet, [], [])
        }
        
        var inserted = [RapidDocumentSnapshot]()
        var updated = [RapidDocumentSnapshot]()
        var deleted = [RapidDocumentSnapshot]()
        
        // Loop through updated documents
        for document in newValue {
            // Index of the document in the last known dataset
            let index = documents.index(where: { $0.id == document.id })
            
            // If the document was removed
            if let index = index, document.value == nil {
                let document = documents.remove(at: index)
                deleted.append(document)
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
                    
                    updated.append(document)
                }
                else {
                    documents.insert(document, at: predIndex + 1)
                    inserted.append(document)
                }
            }
            // If the document doesn't have a predecessor, but it is in the last known dataset update it and move it to the index 0
            else if let index = index {
                documents.remove(at: index)
                documents.insert(document, at: 0)
                updated.append(document)
            }
            // If the document doesn't have a predecessor and it isn't in the last known dataset insert it to the index 0
            else {
                documents.insert(document, at: 0)
                inserted.append(document)
            }
        }
        
        return (documents, inserted, updated, deleted)
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
        state = .subscribed
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        state = .unsubscribed
        
        for subscription in subscriptions {
            subscription.subscriptionFailed(withError: error.error)
        }
    }
    
    func receivedSubscriptionEvent(_ update: RapidSubscriptionEvent) {
        receivedNewValue(update.documents)
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
