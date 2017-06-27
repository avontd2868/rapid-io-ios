//
//  FirebaseObserver.swift
//  Grizzly
//
//  Created by Jan Schwarz on 01/12/2016.
//  Copyright © 2016 Surge Gay App s.r.o. All rights reserved.
//

import Foundation
import Rapid

protocol RapidSubscriber: class {
    var rapidSubscriptions: [RapidSubscription]? { get set }
}

extension RapidSubscriber {
    
    func subscribe(forCollection collection: RapidCollectionRef, with completion: @escaping ([RapidDocument]) -> Void) {
        let subscription = collection.subscribe(block: { result in
            switch result {
            case .success(let documents):
                completion(documents)
                
            case .failure:
                completion([])
            }
        })
        
        if let index = rapidSubscriptions?.index(where: { $0.subscriptionHash == subscription.subscriptionHash }) {
            let sub = rapidSubscriptions?.remove(at: index)
            sub?.unsubscribe()
        }
        
        var subscriptions = rapidSubscriptions ?? []
        subscriptions.append(subscription)
        rapidSubscriptions = subscriptions
    }
    
}
