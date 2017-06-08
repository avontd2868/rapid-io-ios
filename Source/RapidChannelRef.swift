//
//  RapidChannelRef.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Channel subscription handler which provides a client either with an error or with a message
public typealias RapidChanSubHandler = (_ result: RapidResult<RapidChannelMessage>) -> Void

/// Publish completion handler which informs a client about the operation result
public typealias RapidPublishCompletion = (_ result: RapidResult<Any?>) -> Void

/// Common protocol for channel references
public protocol RapidChannelRefProtocol {
    func subscribe(block: @escaping RapidChanSubHandler) -> RapidSubscription
}

/// Reference to a single channel identified by its full channel name
open class RapidChannelRef: RapidInstanceWithSocketManager, RapidChannelRefProtocol {
    
    /// Channel name
    public let channelName: String

    weak var handler: RapidHandler?

    init(name: String, handler: RapidHandler!) {
        self.channelName = name
        self.handler = handler
    }
    
    /// Publish message to the channel
    ///
    /// - Parameters:
    ///   - message: Message dictionary that should be published
    ///   - completion: Publish completion handler which provides a client with an error if any error occurs
    open func publish(message: [AnyHashable: Any], completion: RapidPublishCompletion? = nil) {
        let publish = RapidChannelPublish(channelID: channelName, value: message, completion: completion)
        
        socketManager.publish(publishRequest: publish)
    }
    
    /// Subscribe for listening to messages in the channel
    ///
    /// - Parameter block: Subscription handler which provides a client either with an error or with a message
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    open func subscribe(block: @escaping RapidChanSubHandler) -> RapidSubscription {
        let subscription = RapidChannelSub(channelID: .name(channelName), handler: block)
        
        socketManager.subscribe(toChannel: subscription)
        
        return subscription
    }
    
}

/// Reference to multiple channels identified by their channel name prefix
open class RapidChannelsRef: RapidInstanceWithSocketManager, RapidChannelRefProtocol {
    
    /// Channel prefix
    public let channelPrefix: String
    
    weak var handler: RapidHandler?
    
    init(prefix: String, handler: RapidHandler!) {
        self.channelPrefix = prefix
        self.handler = handler
    }
    
    /// Subscribe for listening to messages in the channel
    ///
    /// - Parameter block: Subscription handler which provides a client either with an error or with a message
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    open func subscribe(block: @escaping RapidChanSubHandler) -> RapidSubscription {
        let subscription = RapidChannelSub(channelID: .prefix(channelPrefix), handler: block)
        
        socketManager.subscribe(toChannel: subscription)
        
        return subscription
    }
    
}
