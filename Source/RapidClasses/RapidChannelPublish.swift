//
//  RapidChannelPublish.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Request for publishing message to a channel
class RapidChannelPublish: NSObject {
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false
    
    /// Message dictionary
    let value: [AnyHashable: Any]
    
    /// Channel ID
    let channelID: String
    
    /// Publish completion
    let completion: RapidPublishCompletion?
    
    /// Timeout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Initialize publish request
    ///
    /// - Parameters:
    ///   - channelID: Channel ID
    ///   - value: JSON with message to be published
    ///   - completion: Publish completion
    init(channelID: String, value: [AnyHashable: Any], completion: RapidPublishCompletion?) {
        self.value = value
        self.channelID = channelID
        self.completion = completion
    }
    
}

extension RapidChannelPublish: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(publish: self, withIdentifiers: identifiers)
    }
}

extension RapidChannelPublish: RapidTimeoutRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid published message \(self.value) to channel \(self.channelID)", level: .info)
            
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid publish failed - channel \(self.channelID)", level: .info)
            
            self.completion?(.failure(error: error.error))
        }
    }
}
