//
//  FirebaseManager.swift
//  Grizzly
//
//  Created by Jan Schwarz on 01/12/2016.
//  Copyright © 2016 Surge Gay App s.r.o. All rights reserved.
//

import Foundation
import Rapid

class RapidManager: NSObject {
    
    static let shared = RapidManager()
    
    func unsubscribe<Subscriber: NSObject>(_ subscriber: Subscriber) where Subscriber: RapidSubscriber {
        for subscription in subscriber.rapidSubscriptions ?? [] {
            subscription.unsubscribe()
        }
    }
    
    // MARK: - Messages
    
    func messages<Subscriber: NSObject>(for subscriber: Subscriber, channelID: String, handler: @escaping ([RapidDocument]) -> Void) where Subscriber: RapidSubscriber {
        let collection = Rapid.collection(named: Constants.messagesCollection)
            .filter(by: RapidFilter.equal(keyPath: Message.channelID, value: channelID))
            .order(by: RapidOrdering(keyPath: Message.sentDate, ordering: .descending))
            .limit(to: 250)
        
        subscriber.subscribe(forCollection: collection, with: handler)
    }
    
    // MARK: - Channels
    
    func channels<Subscriber: NSObject>(for subscriber: Subscriber, handler: @escaping ([RapidDocument]) -> Void) where Subscriber: RapidSubscriber {
        let collection = Rapid.collection(named: Constants.channelsCollection)
            .order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
        
        subscriber.subscribe(forCollection: collection, with: handler)
    }
    
}
