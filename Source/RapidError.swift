//
//  RapidError.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Internal errors
enum RapidInternalError: Error {
    case rapidInstanceNotInitialized
    
    var message: String {
        switch self {
        case .rapidInstanceNotInitialized:
            return "Rapid instance not initialized"
        }
    }
}

/// Wrapper structure for `RapidError`
struct RapidErrorInstance: RapidResponse {
    
    let eventID: String
    let error: RapidError
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
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

/// Errors which can be thrown by Rapid SDK
///
/// - permissionDenied: Client doesn't have permisson to read or write specified data
/// - server: Internal Rapid server error
/// - connectionTerminated: Websocket connection expired and needs to be reestablished
/// - invalidData: Data are in an invalid format
/// - timeout: Request timout
/// - `default`: General error
public enum RapidError: Error {
    
    case permissionDenied(message: String?)
    case server(message: String?)
    case connectionTerminated(message: String?)
    case invalidData(reason: InvalidDataReason)
    case timeout
    case `default`
    
    public enum InvalidDataReason {
        case serializationFailure
        case invalidFilter(filter: RapidFilter)
        case invalidParameterName(name: Any)
    }
}
