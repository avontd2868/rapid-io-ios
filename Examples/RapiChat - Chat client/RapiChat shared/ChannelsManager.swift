//
//  ChannelManager.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

protocol ChannelsManagerDelegate: class {
    func channelsChanged()
}

class ChannelsManager {
    
    private var subscription: RapidSubscription?
    
    private weak var delegate: ChannelsManagerDelegate?
    private(set) var channels: [Channel] = []
    
    init(withDelegate delegate: ChannelsManagerDelegate) {
        self.delegate = delegate
        
        subscribeToChannels()
    }
    
    deinit {
        subscription?.unsubscribe()
    }
}

fileprivate extension ChannelsManager {
    
    func subscribeToChannels() {
        // Get rapid.io collection reference
        // Order it according to document ID
        // Subscribe
        let collection = Rapid.collection(named: "channels")
            .order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
        
        subscription = collection.subscribe { [weak self] result in
            switch result {
            case .success(let documents):
                self?.channels = documents.flatMap({ Channel(withDocument: $0) })
                
            case .failure:
                self?.channels = []
            }
            
            PNManager.shared.listenToChannels(withNames: self?.channels.map({ $0.name }) ?? [])
            self?.delegate?.channelsChanged()
        }
    }
}
