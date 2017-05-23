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
struct RapidErrorInstance: RapidServerResponse {
    
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
        switch key {
        case .some(let type) where type == RapidSerialization.Error.ErrorType.PermissionDenied.name:
            error = .permissionDenied(message: message)
            
        case .some(let type) where type == RapidSerialization.Error.ErrorType.Internal.name:
            error = .server(message: message)
            
        case .some(let type) where type == RapidSerialization.Error.ErrorType.ConnectionTerminated.name:
            error = .connectionTerminated(message: message)
            
        case .some(let type) where type == RapidSerialization.Error.ErrorType.InvalidAuthToken.name:
            error = .invalidAuthToken(message: message)
            
        case .some(let type) where type == RapidSerialization.Error.ErrorType.ClientSide.name:
            error = .invalidRequest(message: message)
            
        case .some(let type) where type == RapidSerialization.Error.ErrorType.WriteConflict.name:
            error = .concurrencyWriteFailed(reason: .writeConflict(message: message))
            
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
/// - invalidRequest: Client sent invalid request to the server. Please update Rapid SDK framework. If your framework is up to date, please report an issue at https://github.com/Rapid-SDK/ios
/// - connectionTerminated: Websocket connection expired and needs to be reestablished
/// - invalidData: Data are in an invalid format
/// - timeout: Request timout
/// - invalidAuthToken: Authorization token is invalid
/// - concurrencyWriteFailed: Optimistic concurrency write failed
/// - `default`: General error
public enum RapidError: Error {
    
    case permissionDenied(message: String?)
    case server(message: String?)
    case invalidRequest(message: String?)
    case connectionTerminated(message: String?)
    case invalidData(reason: InvalidDataReason)
    case timeout
    case invalidAuthToken(message: String?)
    case concurrencyWriteFailed(reason: ConcurrencyWriteError)
    case `default`
    
    /// Reason of `invalidData` error
    ///
    /// - serializationFailure: Serialization failed because data were in a wrong format
    /// - invalidFilter: Invalid subscription filter
    /// - invalidDocument: Invalid document JSON when mutating or merging
    /// - invalidIdentifierFormat: Invalid identifier format - all identifiers e.g. collection ID, document ID must be strings consiting only of alphanumeric characters, dashes and underscores
    /// - invalidKeyPath: Invalid key path format
    public enum InvalidDataReason {
        case serializationFailure
        case invalidFilter(filter: RapidFilter)
        case invalidDocument(document: [AnyHashable: Any])
        case invalidIdentifierFormat(identifier: Any?)
        case invalidKeyPath(keyPath: String)
    }
    
    //FIXME: Better name
    /// Reason of `concurrencyWriteFailed`
    ///
    /// - writeConflict: Server wasn't able to fulfill concurrency optimistic write to database
    /// - invalidResult: Unexpected result of `RapidConcurrencyOptimisticBlock`
    /// - aborted: Client aborted an optimistic concurrency flow
    public enum ConcurrencyWriteError {
        case writeConflict(message: String?)
        case invalidResult(message: String)
        case aborted
    }
}
