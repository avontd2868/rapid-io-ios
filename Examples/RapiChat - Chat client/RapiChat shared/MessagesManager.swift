//
//  MessagesManager.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

protocol MessagesManagerDelegate: class {
    func messagesChanged(_ manager: MessagesManager)
}

class MessagesManager: NSObject, RapidSubscriber {
    
    var rapidSubscriptions: [RapidSubscription]?

    fileprivate weak var delegate: MessagesManagerDelegate?
    fileprivate(set) var messages: [Message]?
    let channelID: String
    
    init(forChannel channelID: String, withDelegate delegate: MessagesManagerDelegate) {
        self.channelID = channelID
        
        super.init()
        
        self.delegate = delegate
        
        subscribeToMessages()
    }
    
    deinit {
        RapidManager.shared.unsubscribe(self)
    }
    
    func sendMessage(_ text: String) {
        UserDefaultsManager.generateUsername { [weak self] username in
            guard let strongSelf = self else {
                return
            }
            
            var message: [AnyHashable: Any] = [
                Message.channelID: strongSelf.channelID,
                Message.sender: username,
                Message.sentDate: Rapid.serverTimestamp,
                Message.text: text
            ]
            
            let messageRef = Rapid.collection(named: Constants.messagesCollection)
                .newDocument()
                
            messageRef.mutate(value: message)
            
            Rapid.collection(named: Constants.channelsCollection).document(withID: strongSelf.channelID).execute(block: { document -> RapidExecutionResult in
                var value = document.value ?? [:]
                
                message[Channel.lastMessageID] = messageRef.documentID
                value[Channel.lastMessage] = message
                
                return .write(value: value)
            })
        }
    }
}

fileprivate extension MessagesManager {
    
    func subscribeToMessages() {
        RapidManager.shared.messages(for: self, channelID: channelID) { [weak self] documents in
            self?.messages = documents.flatMap({ Message.initialize(withDocument: $0) }).reversed()
            if let strongSelf = self {
                self?.delegate?.messagesChanged(strongSelf)
            }
        }
    }
}
