//
//  RapidChannelMessage.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

open class RapidChannelMessage: RapidServerEvent {
    
    internal var eventIDsToAcknowledge: [String]
    let subscriptionID: String
    
    public let channelID: String
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
        self.channelID = channelID
        self.message = message
    }
    
}
