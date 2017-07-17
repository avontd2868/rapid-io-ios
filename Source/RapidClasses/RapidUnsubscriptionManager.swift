//
//  RapidUnsubscriptionManager.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Unsubscription manager

// Wrapper for `RapidSubscriptionManager` that handles unsubscription
class RapidUnsubscriptionManager: NSObject {
    
    let shouldSendOnReconnect = false
    
    let subscription: RapidSubscriptionManager
    
    init(subscription: RapidSubscriptionManager) {
        self.subscription = subscription
    }
    
}

extension RapidUnsubscriptionManager: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try subscription.serializeForUnsubscription(withIdentifiers: identifiers)
    }
}

extension RapidUnsubscriptionManager: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        subscription.didUnsubscribe()
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        subscription.retryUnsubscription(withHandler: self)
    }
}
