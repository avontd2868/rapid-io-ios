//
//  RapidRequest.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Protocol ensuring serialization to JSON string
protocol RapidSerializable {
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String
}

/// Protocol describing events that can be sent to the server
protocol RapidRequest: class {
    /// Request waits to be acknowledged by the server
    var needsAcknowledgement: Bool { get }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement)
    func eventFailed(withError error: RapidErrorInstance)
}

/// Protocol inheriting from `RapidRequest`.
///
/// `RapidClientEvent` informs the server about an event and doesn't wait for an acknowledgement.
protocol RapidClientEvent: RapidRequest {}

extension RapidClientEvent {
    
    var needsAcknowledgement: Bool { return false }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {}
    
    func eventFailed(withError error: RapidErrorInstance) {}
}

extension RapidClientEvent where Self: RapidSerializable {
    
    func serialize() throws -> String {
        return try self.serialize(withIdentifiers: [:])
    }
}

/// `RapidRequest` that implements timeout
protocol RapidTimeoutRequest: RapidRequest {
    /// Request should timeout even if `Rapid.timeout` is `nil`
    var alwaysTimeout: Bool { get }
    
    /// Request was enqued an timeout countdown should begin
    ///
    /// - Parameters:
    ///   - timeout: Number of seconds before timeout occurs
    ///   - delegate: Timeout delegate
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate)
    
    /// Stop countdown because request is no more valid
    func invalidateTimer()
}

/// Delegate for informing about timout
protocol RapidTimeoutRequestDelegate: class {
    func requestTimeout(_ request: RapidTimeoutRequest)
}
