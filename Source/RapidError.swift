//
//  RapidError.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

enum RapidInternalError: Error {
    case rapidInstanceNotInitialized
    
    var message: String {
        switch self {
        case .rapidInstanceNotInitialized:
            return "Rapid instance not initialized"
        }
    }
}

struct RapidErrorInstance: RapidResponse {
    
    let eventID: String
    let error: RapidError
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.Error.EventID.name] as? String else {
            return nil
        }
        
        let key = dict[RapidSerialization.Error.ErrorType.name] as? String
        let message = dict[RapidSerialization.Error.ErrorMessage.name] as? String
        
        let error: RapidError
        switch key ?? "" {
        case RapidSerialization.Error.ErrorType.PermissionDenied.name:
            error = .permissionDenied(message: message)
            
        case RapidSerialization.Error.ErrorType.Internal.name:
            error = .server(message: message)
            
        case RapidSerialization.Error.ErrorType.ConnectionTerminated.name:
            error = .connectionTerminated(message: message)
            
        default:
            error = .default
        }
        
        self.eventID = eventID
        self.error = error
    }
    
    init(eventID: String, error: RapidError) {
        self.eventID = eventID
        self.error = error
    }
}

public enum RapidError: Error {
    
    case permissionDenied(message: String?)
    case server(message: String?)
    case connectionTerminated(message: String?)
    case invalidData
    case timeout
    case `default`
    
}
