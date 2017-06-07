//
//  RapidChannelRef.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public typealias RapidChanSubHandler = (_ result: RapidResult<RapidChannelMessage>) -> Void

public typealias RapidPublishCompletion = (_ result: RapidResult<Any?>) -> Void

open class RapidChannelRef {
    
    public enum ChannelIdentifier {
        case name(String)
        case prefix(String)
    }
    
    fileprivate weak var handler: RapidHandler?
    
    fileprivate var socketManager: RapidSocketManager {
        return try! getSocketManager()
    }
    
    /// Collection identifier
    public let channelID: ChannelIdentifier
    
    init(identifier: ChannelIdentifier, handler: RapidHandler!) {
        self.channelID = identifier
        self.handler = handler
    }
    
    open func publish(message: [AnyHashable: Any], completion: RapidPublishCompletion? = nil) {
        if case .name(let name) = channelID {
            let publish = RapidChannelPublish(channelID: name, value: message, completion: completion)
            
            socketManager.publish(publishRequest: publish)
        }
    }
    
    @discardableResult
    open func subscribe(block: @escaping RapidChanSubHandler) -> RapidSubscription {
        let subscription = RapidChannelSub(channelID: channelID, handler: block)
        
        socketManager.subscribe(toChannel: subscription)
        
        return subscription
    }
    
}

extension RapidChannelRef {
    
    func getSocketManager() throws -> RapidSocketManager {
        if let manager = handler?.socketManager {
            return manager
        }
        
        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, level: .critical)
        throw RapidInternalError.rapidInstanceNotInitialized
    }
    
}
