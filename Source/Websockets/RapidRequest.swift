//
//  RapidRequest.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidSerializable {
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String
}

protocol RapidRequest {
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement)
    func eventFailed(withError error: RapidSocketError)
}

class RapidSubscriptionHandler<Subscription: RapidSubscription>: NSObject {
    
    var subscriptionHash: String {
        return subscriptions.first?.hash ?? ""
    }
    
    let subscriptionID: String
    fileprivate let unsubscribeHandler: (RapidSubscriptionHandler<Subscription>) -> Void
    fileprivate var subscriptions: [Subscription] = []
    
    init(withSubscriptionID subscriptionID: String, subscription: Subscription, unsubscribeHandler: @escaping (RapidSubscriptionHandler<Subscription>) -> Void) {
        self.unsubscribeHandler = unsubscribeHandler
        self.subscriptionID = subscriptionID
        
        super.init()
        
        subscriptions.append(subscription)
    }
    
    func registerSubscription(subscription: Subscription) {
        subscriptions.append(subscription)
    }
}

extension RapidSubscriptionHandler: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        
    }
    
    func eventFailed(withError error: RapidSocketError) {
        
    }
}
