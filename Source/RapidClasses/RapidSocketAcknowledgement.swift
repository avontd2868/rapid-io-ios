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
/// This object represents either an acknowledgement from the server or an acknowledgement which is about to be sent to the server
class RapidSocketAcknowledgement: RapidResponse {
    
    let needsAcknowledgement = false
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

extension RapidSocketAcknowledgement: RapidSerializable, RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(acknowledgement: self, withIdentifiers: identifiers)
    }
}
