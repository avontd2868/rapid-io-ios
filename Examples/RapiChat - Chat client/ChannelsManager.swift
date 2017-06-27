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
    func channelsChanged(_ manager: ChannelsManager)
}

class ChannelsManager: NSObject, RapidSubscriber {
    
    var rapidSubscriptions: [RapidSubscription]?
    
    fileprivate weak var delegate: ChannelsManagerDelegate?
    fileprivate(set) var channels: [Channel]?
    
    init(withDelegate delegate: ChannelsManagerDelegate) {
        super.init()
        
        self.delegate = delegate
        
        subscribeToChannels()
    }
    
    deinit {
        RapidManager.shared.unsubscribe(self)
    }
}

fileprivate extension ChannelsManager {
    
    func subscribeToChannels() {
        RapidManager.shared.channels(for: self) { [weak self] documents in
            self?.channels = documents.flatMap({ Channel(withDocument: $0) })
            if let strongSelf = self {
                self?.delegate?.channelsChanged(strongSelf)
            }
        }
    }
}
