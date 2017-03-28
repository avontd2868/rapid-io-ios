//
//  RapidSubscriptionHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidSubscriptionHandler: NSObject {
    
    enum State {
        case unsubscribed
        case registering
        case subscribed
        case unsubscribing
    }
    
    var subscriptionHash: String {
        return subscriptions.first?.subscriptionHash ?? ""
    }
    
    let needsAcknowledgement = true
    let subscriptionID: String
    
    fileprivate let dispatchQueue: DispatchQueue
    fileprivate let unsubscribeHandler: (RapidUnsubscriptionHandler) -> Void
    fileprivate var subscriptions: [RapidSubscriptionInstance] = []
    
    fileprivate var value: [RapidDocumentSnapshot]?
    
    fileprivate var state: State = .unsubscribed
    
    init(withSubscriptionID subscriptionID: String, subscription: RapidSubscriptionInstance, dispatchQueue: DispatchQueue, unsubscribeHandler: @escaping (RapidUnsubscriptionHandler) -> Void) {
        self.unsubscribeHandler = unsubscribeHandler
        self.subscriptionID = subscriptionID
        self.dispatchQueue = dispatchQueue
        
        super.init()
        
        state = .registering
        appendSubscription(subscription)
    }
    
    func registerSubscription(subscription: RapidSubscriptionInstance) {
        appendSubscription(subscription)
        
        if state == .subscribed {
            subscription.receivedUpdate(value ?? [], [], [], [])
        }
    }
    
    func retryUnsubscription(withHandler handler: RapidUnsubscriptionHandler) {
        if state == .unsubscribing {
            unsubscribeHandler(handler)
        }
    }
    
    func didUnsubscribe() {
        state = .unsubscribed
    }
}

extension RapidSubscriptionHandler: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        if let subscription = subscriptions.first {
            var idef = identifiers
            
            idef[RapidSerialization.Subscription.SubscriptionID.name] = subscriptionID
            
            return try subscription.serialize(withIdentifiers: identifiers)
        }
        else {
            throw RapidError.invalidData
        }
    }
}

fileprivate extension RapidSubscriptionHandler {
    
    func appendSubscription(_ subscription: RapidSubscriptionInstance) {
        subscription.registerUnsubscribeCallback { [weak self] instance in
            self?.dispatchQueue.async {
                self?.unsubscribe(instance: instance)
            }
        }
        subscriptions.append(subscription)
    }
    
    func receivedNewValue(_ newValue: [RapidDocumentSnapshot]) {
        let updates = incorporateChanges(newValue: newValue, oldValue: value)
        
        for subsription in subscriptions {
            subsription.receivedUpdate(updates.dataSet, updates.insert, updates.update, updates.delete)
        }
        
        value = updates.dataSet
    }
    
    func incorporateChanges(newValue rawArray: [RapidDocumentSnapshot], oldValue: [RapidDocumentSnapshot]?) -> (dataSet: [RapidDocumentSnapshot], insert: [RapidDocumentSnapshot], update: [RapidDocumentSnapshot], delete: [RapidDocumentSnapshot]) {
        
        var newValue = rawArray
        var removeIndexes = [Int]()
        var swapIndexes = [(Int,Int)]()
        var indexForDocument = [String: Int]()
        
        for (index, document) in rawArray.enumerated() {
            let existingIndex = indexForDocument[document.id]
            
            if existingIndex == nil {
                indexForDocument[document.id] = index
            }
            else if oldValue == nil, let existingIndex = existingIndex {
                swapIndexes.append((existingIndex, index))
                removeIndexes.append(index)
            }
            else if let existingIndex = existingIndex {
                indexForDocument[document.id] = index
                removeIndexes.append(existingIndex)
            }
        }
        
        for swap in swapIndexes {
            let tmp = newValue[swap.0]
            newValue[swap.0] = newValue[swap.1]
            newValue[swap.1] = tmp
        }
        
        for index in removeIndexes.reversed() {
            newValue.remove(at: index)
        }
        
        guard var documents = oldValue else {
            let dataSet = newValue.flatMap({ $0.value == nil ? nil : $0 })
            return (dataSet, dataSet, [], [])
        }
        
        var inserted = [RapidDocumentSnapshot]()
        var updated = [RapidDocumentSnapshot]()
        var deleted = [RapidDocumentSnapshot]()
        
        for value in newValue {
            let index = documents.index(where: { $0.id == value.id })
            
            if let index = index, value.value == nil {
                let document = documents.remove(at: index)
                deleted.append(document)
            }
            else if let predID = value.predecessorID, let predIndex = documents.index(where: { $0.id == predID }) {
                if let index = index {
                    documents.remove(at: index)
                    let newIndex = predIndex < index ? predIndex + 1 : predIndex
                    documents.insert(value, at: newIndex)
                    updated.append(value)
                }
                else {
                    documents.insert(value, at: predIndex + 1)
                    inserted.append(value)
                }
            }
            else if let index = index {
                documents.remove(at: index)
                documents.insert(value, at: 0)
                updated.append(value)
            }
            else {
                documents.insert(value, at: 0)
                inserted.append(value)
            }
        }
        
        return (documents, inserted, updated, deleted)
    }

    func unsubscribe(instance: RapidSubscriptionInstance) {
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

class RapidUnsubscriptionHandler: NSObject {
    
    let subscription: RapidSubscriptionHandler
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
