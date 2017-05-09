//
//  RapidUpdate.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Wrapper for subscription events that came in one batch
class RapidSubscriptionBatch: RapidResponse {
    
    let eventID: String
    let subscriptionID: String
    let collectionID: String
    
    internal(set) var collection: [RapidDocumentSnapshot]?
    internal(set) var updates: [RapidDocumentSnapshot]
    
    init(withSubscriptionID id: String, collection: [RapidDocumentSnapshot]) {
        self.eventID = Rapid.uniqueID
        self.subscriptionID = id
        self.collectionID = collection.first?.collectionID ?? ""
        self.collection = collection
        self.updates = []
    }
    
    init?(withCollectionJSON json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
            return nil
        }
        
        guard let subscriptionID = dict[RapidSerialization.SubscriptionValue.SubscriptionID.name] as? String else {
            return nil
        }
        
        guard let collectionID = dict[RapidSerialization.SubscriptionValue.CollectionID.name] as? String else {
            return nil
        }
        
        guard let documents = dict[RapidSerialization.SubscriptionValue.Documents.name] as? [Any] else {
            return nil
        }
        
        self.eventID = eventID
        self.subscriptionID = subscriptionID
        self.collectionID = collectionID
        self.collection = documents.flatMap({ RapidDocumentSnapshot(json: $0, collectionID: collectionID) })
        self.updates = []
    }
    
    init?(withUpdateJSON json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
            return nil
        }
        
        guard let subscriptionID = dict[RapidSerialization.SubscriptionUpdate.SubscriptionID.name] as? String else {
            return nil
        }
        
        guard let collectionID = dict[RapidSerialization.SubscriptionUpdate.CollectionID.name] as? String else {
            return nil
        }
        
        guard let document = dict[RapidSerialization.SubscriptionUpdate.Document.name] as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let snapshot = RapidDocumentSnapshot(json: document, collectionID: collectionID) else {
            return nil
        }
        
        self.eventID = eventID
        self.subscriptionID = subscriptionID
        self.collectionID = collectionID
        self.collection = nil
        self.updates = [snapshot]
    }

    /// Add subscription event to the batch
    ///
    /// - Parameter initialValue: Subscription dataset object
    func merge(event: RapidSubscriptionBatch) {
        // Since initial value contains whole dataset it overrides all previous single updates
        if let collection = event.collection {
            self.collection = collection
            self.updates = event.updates
        }
        else {
            self.updates.append(contentsOf: event.updates)
        }
    }
    
}
