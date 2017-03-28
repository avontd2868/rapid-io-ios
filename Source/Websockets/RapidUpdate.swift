//
//  RapidUpdate.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Protocol for a server event informing about a subscription
protocol RapidSubscriptionEvent: RapidResponse {
    var eventID: String { get }
    var subscriptionID: String { get }
    var documents: [RapidDocumentSnapshot] { get set }
}

extension RapidSubscriptionEvent {
    
    /// In case of a batch update, append relevant snapshots to the previous ones
    ///
    /// - Parameter update: Updated document snapshot
    mutating func merge(withUpdate update: RapidSubscriptionEvent) {
        documents.append(contentsOf: update.documents)
    }
    
}

/// Response from server after subscription was succesfully registered
///
/// Class contains all documents that meet the subscription specification
class RapidSubscriptionInitialValue: RapidSubscriptionEvent {
    
    let eventID: String
    let subscriptionID: String
    internal(set) var documents: [RapidDocumentSnapshot]
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
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

/// Event sent by server when set of documents thet meet the subscription specification changes
///
/// Class contains just those documents that have been added, updated or removed
/// When server sends a single update `documents` array contains just one snapshot.
/// When server sends a batch update `documents` array contains all snapshots that are relevant to the subscription
class RapidSubscriptionUpdate: RapidSubscriptionEvent {
    
    let eventID: String
    let subscriptionID: String
    internal(set) var documents: [RapidDocumentSnapshot]
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
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
}
