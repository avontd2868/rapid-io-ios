//
//  RapidSubscriptionHandler.swift
//  Rapid
//
//  Created by Jan on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidSubscriptionHandler: NSObject {
    
    enum State {
        case unsubscribed
        case registering
        case subscribed
        case unsubscribing
    }
    
    var subscriptionHash: String {
        return subscriptions.first?.subscriptionHash ?? ""
    }
    
    let subscriptionID: String
    
    fileprivate let unsubscribeHandler: (RapidUnsubscriptionHandler) -> Void
    fileprivate var subscriptions: [RapidSubscriptionInstance] = []
    
    fileprivate var value: [RapidDocumentSnapshot]?
    
    fileprivate var state: State = .unsubscribed
    
    init(withSubscriptionID subscriptionID: String, subscription: RapidSubscriptionInstance, unsubscribeHandler: @escaping (RapidUnsubscriptionHandler) -> Void) {
        self.unsubscribeHandler = unsubscribeHandler
        self.subscriptionID = subscriptionID
        
        super.init()
        
        state = .registering
        appendSubscription(subscription)
    }
    
    func registerSubscription(subscription: RapidSubscriptionInstance) {
        appendSubscription(subscription)
        
        if state == .subscribed {
            subscription.receivedNewValue(value ?? [], oldValue: nil)
        }
    }
    
    func retryUnsubscription(withHandler handler: RapidUnsubscriptionHandler) {
        if state == .unsubscribing {
            unsubscribeHandler(handler)
        }
    }
    
    func didUnsubscribe() {
        state = .unsubscribed
    }
}

extension RapidSubscriptionHandler: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        if let subscription = subscriptions.first {
            var idef = identifiers
            
            idef[RapidSerialization.Subscription.SubscriptionID.name] = subscriptionID
            
            return try subscription.serialize(withIdentifiers: identifiers)
        }
        else {
            throw RapidError.invalidData
        }
    }
}

fileprivate extension RapidSubscriptionHandler {
    
    func appendSubscription(_ subscription: RapidSubscriptionInstance) {
        subscription.registerUnsubscribeCallback { [weak self] instance in
            self?.unsubscribe(instance: instance)
        }
        subscriptions.append(subscription)
    }
    
    func receivedNewValue(_ newValue: [RapidDocumentSnapshot]) {
        for subsription in subscriptions {
            subsription.receivedNewValue(newValue, oldValue: value)
        }
        
        value = newValue
    }
    
    func unsubscribe(instance: RapidSubscriptionInstance) {
        if subscriptions.count == 1 {
            state = .unsubscribing
            unsubscribeHandler(RapidUnsubscriptionHandler(subscription: self))
        }
        else if let index = subscriptions.index(where: { $0 === instance }) {
            subscriptions.remove(at: index)
        }
    }
}

extension RapidSubscriptionHandler: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        state = .subscribed
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        state = .unsubscribed
        
        for subscription in subscriptions {
            subscription.subscriptionFailed(withError: error.error)
        }
    }
    
    func receivedInitialValue(_ value: RapidSubscriptionInitialValue) {
        receivedNewValue(value.documents)
    }
    
    func receivedUpdate(_ update: RapidSubscriptionUpdate) {
        receivedNewValue(update.documents)
    }
}

class RapidUnsubscriptionHandler: NSObject {
    
    let subscription: RapidSubscriptionHandler
    
    init(subscription: RapidSubscriptionHandler) {
        self.subscription = subscription
    }
    
}

extension RapidUnsubscriptionHandler: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(unsubscription: self, withIdentifiers: identifiers)
    }
}

extension RapidUnsubscriptionHandler: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        subscription.didUnsubscribe()
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        subscription.retryUnsubscription(withHandler: self)
    }
}
