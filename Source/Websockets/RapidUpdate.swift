//
//  RapidUpdate.swift
//  Rapid
//
//  Created by Jan on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

struct RapidSubscriptionInitialValue: RapidResponse {
    
    let eventID: String
    let subscriptionID: String
    let documents: [RapidDocumentSnapshot]
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.SubscriptionValue.EventID.name] as? String else {
            return nil
        }
        
        guard let subscriptionID = dict[RapidSerialization.SubscriptionUpdate.SubscriptionID.name] as? String else {
            return nil
        }
        
        guard let documents = dict[RapidSerialization.SubscriptionValue.Documents.name] as? [Any] else {
            return nil
        }
        
        self.eventID = eventID
        self.subscriptionID = subscriptionID
        self.documents = documents.flatMap({ RapidDocumentSnapshot(json: $0) })
    }
}

struct RapidSubscriptionUpdate: RapidResponse {
    
    let eventID: String
    let subscriptionID: String
    fileprivate(set) var documents: [RapidDocumentSnapshot]
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.SubscriptionUpdate.EventID.name] as? String else {
            return nil
        }
        
        guard let subscriptionID = dict[RapidSerialization.SubscriptionUpdate.SubscriptionID.name] as? String else {
            return nil
        }
        
        guard let document = dict[RapidSerialization.SubscriptionUpdate.Document.name] as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let snapshot = RapidDocumentSnapshot(json: document) else {
            return nil
        }
        
        self.eventID = eventID
        self.subscriptionID = subscriptionID
        self.documents = [snapshot]
    }

    mutating func merge(withUpdate update: RapidSubscriptionUpdate) {
        documents.append(contentsOf: update.documents)
    }
}
