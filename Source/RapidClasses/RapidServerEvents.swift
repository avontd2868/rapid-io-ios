//
//  RapidSocketError.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Acknowledgement event object
///
/// This acknowledgement is sent by server as a response to a client request
class RapidServerAcknowledgement: RapidServerResponse {
    
    let eventID: String
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
            return nil
        }

        self.eventID = eventID
    }
    
    init(eventID: String) {
        self.eventID = eventID
    }
}

extension RapidServerAcknowledgement: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(acknowledgement: self)
    }
}

/// Acknowledgement event object
///
/// This acknowledgement is sent to server as a response to a server event
class RapidClientAcknowledgement: RapidClientEvent {
    
    let shouldSendOnReconnect = false
    
    let eventID: String
    
    init(eventID: String) {
        self.eventID = eventID
    }
}

extension RapidClientAcknowledgement: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(acknowledgement: self)
    }
}

// MARK: Subscription cancel

/// Subscription cancel event object
///
/// Subscription cancel is a sever event which occurs 
/// when a client has no longer permissions to read collection after reauthorization/deauthorization
class RapidSubscriptionCancelled: RapidServerEvent {
    
    let eventIDsToAcknowledge: [String]
    let subscriptionID: String
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
            return nil
        }
        
        guard let subID = dict[RapidSerialization.CollectionSubscriptionCancelled.SubscriptionID.name] as? String else {
            return nil
        }
        
        self.eventIDsToAcknowledge = [eventID]
        self.subscriptionID = subID
    }
}

// MARK: Server timestamp

/// Server timestamp event object
/// `RapidServerTimestamp` is a response for a server timestamp request
class RapidServerTimestamp: RapidServerEvent {
    
    let eventIDsToAcknowledge: [String]
    let timestamp: TimeInterval

    init?(withJSON json: [AnyHashable: Any]) {
        guard let eventID = json[RapidSerialization.EventID.name] as? String else {
            return nil
        }
        
        guard let timestamp = json[RapidSerialization.Timestamp.Timestamp.name] as? TimeInterval else {
            return nil
        }
        
        self.eventIDsToAcknowledge = [eventID]
        self.timestamp = timestamp/1000
    }
}
