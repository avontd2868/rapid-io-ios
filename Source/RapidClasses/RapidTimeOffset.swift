//
//  RapidTimeOffset.swift
//  Rapid
//
//  Created by Jan on 30/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Server time offset object
class RapidTimeOffset: NSObject {
    
    /// Completion handler
    let completion: RapidTimeOffsetHandler
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false
    
    /// Timout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    internal var requestTimeoutTimer: Timer?
    
    /// Initialize server time offset object
    ///
    /// - Parameters:
    ///   - completion: Completion handler
    init(completion: @escaping RapidTimeOffsetHandler) {
        self.completion = completion
    }
    
}

extension RapidTimeOffset: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(timeRequest: self, withIdentifiers: identifiers)
    }
}

extension RapidTimeOffset: RapidTimeoutRequest {
    
    func receivedTimestamp(_ timestamp: RapidServerTimestamp) {
        let offset = Date().timeIntervalSince1970 - timestamp.timestamp
        DispatchQueue.main.async {
            self.completion(RapidResult.success(value: offset))
        }
    }
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            self.completion(RapidResult.failure(error: error.error))
        }
    }
}
