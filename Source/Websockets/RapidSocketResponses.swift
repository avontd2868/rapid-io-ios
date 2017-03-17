//
//  RapidSocketError.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

struct RapidSocketAcknowledgement: RapidResponse {
    
    let eventID: String
    let userInfo: Any?
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSocketParser.Acknowledgement.EventID.name] as? String else {
            return nil
        }

        self.eventID = eventID
        self.userInfo = nil
    }
}

enum RapidSocketError: Error, RapidResponse {
    
    case accessDenied(eventID: String, message: String?)
    case invalidData(eventID: String, message: String?)
    case `default`(eventID: String)
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSocketParser.Error.EventID.name] as? String else {
            return nil
        }
        
        let key = dict[RapidSocketParser.Error.ErrorType.name] as? String
        let message = dict[RapidSocketParser.Error.ErrorMessage.name] as? String
        
        switch key ?? "" {
        case "acc-den":
            self = .accessDenied(eventID: eventID, message: message)
            
        case "inv-data":
            self = .invalidData(eventID: eventID, message: message)
            
        default:
            self = .default(eventID: eventID)
        }
    }
    
    var eventID: String {
        switch self {
        case .accessDenied(let eventID, _):
            return eventID
            
        case .invalidData(let eventID, _):
            return eventID
            
        case .default(let eventID):
            return eventID
        }
    }
    
    var message: String? {
        switch self {
        case .accessDenied(_, let message):
            return message
            
        case .invalidData(_, let message):
            return message
            
        case .default:
            return "Database communication outage"
        }
    }
}
