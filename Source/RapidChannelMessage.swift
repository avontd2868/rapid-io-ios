//
//  RapidChannelMessage.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Class representing Rapid.io channel message that is returned from a subscription handler
open class RapidChannelMessage: RapidServerEvent {
    
    internal var eventIDsToAcknowledge: [String]
    internal let subscriptionID: String
    
    /// Channel name
    public let channelName: String
    
    /// Received message
    public let message: [AnyHashable: Any]
    
    init?(withJSON dict: [AnyHashable: Any]) {
        guard let eventID = dict[RapidSerialization.EventID.name] as? String else {
            return nil
        }
        
        guard let subscriptionID = dict[RapidSerialization.ChannelMessage.SubscriptionID.name] as? String else {
            return nil
        }
        
        guard let channelID = dict[RapidSerialization.ChannelMessage.ChannelID.name] as? String else {
            return nil
        }
        
        guard let message = dict[RapidSerialization.ChannelMessage.Body.name] as? [AnyHashable: Any] else {
            return nil
        }
        
        self.eventIDsToAcknowledge = [eventID]
        self.subscriptionID = subscriptionID
        self.channelName = channelID
        self.message = message
    }
    
}
