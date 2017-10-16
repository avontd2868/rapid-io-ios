//
//  RapidSocketError.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid. All rights reserved.
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

// MARK: Subscription cancelled

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

// MARK: On-disconnect action cancelled

/// On-disconnect action cancelled event object
///
/// On-disconnect action cancelled is a server event which occurs
/// when a client has no longer permissions to modify a document after reauthorization/deauthorization
class RapidOnDisconnectActionCancelled: RapidServerEvent {
    
    let eventIDsToAcknowledge: [String]
    let actionID: String
    
    init?(json: [AnyHashable: Any]) {
        guard let eventID = json[RapidSerialization.EventID.name] as? String else {
            return nil
        }
        
        guard let actionID = json[RapidSerialization.DisconnectActionCancelled.ActionID.name] as? String else {
            return nil
        }
        
        self.eventIDsToAcknowledge = [eventID]
        self.actionID = actionID
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
