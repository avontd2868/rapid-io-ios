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
    func messagesChanged()
}

class MessagesManager {
    
    let channelID: String

    private var subscription: RapidSubscription?

    private weak var delegate: MessagesManagerDelegate?
    private(set) var messages: [Message] = []
    
    private let username = UserDefaultsManager.username
    
    init(forChannel channelID: String, withDelegate delegate: MessagesManagerDelegate) {
        self.channelID = channelID
        
        self.delegate = delegate
        
        subscribeToMessages()
    }
    
    deinit {
        subscription?.unsubscribe()
    }
    
    func sendMessage(_ text: String) {
        // Compose a dictionary with a message
        var message: [AnyHashable: Any] = [
            Message.channelID: self.channelID,
            Message.sender: username ?? "",
            Message.sentDate: Rapid.serverTimestamp,
            Message.text: text
        ]
        
        // Get a new rapid.io document reference from the messages collection
        let messageRef = Rapid.collection(named: "messages")
            .newDocument()
        
        // Write the message to database
        messageRef.mutate(value: message)
        
        // Write last message to the channel
        message[Channel.lastMessageID] = messageRef.documentID
        Rapid.collection(named: "channels").document(withID: channelID).merge(value: message)
        
    }
}

fileprivate extension MessagesManager {
    
    func subscribeToMessages() {
        // Get rapid.io collection reference
        // Filter it according to channel ID
        // Order it according to sent date
        // Limit number of messages to 250
        // Subscribe
        let collection = Rapid.collection(named: "messages")
            .filter(by: RapidFilter.equal(keyPath: Message.channelID, value: channelID))
            .order(by: RapidOrdering(keyPath: Message.sentDate, ordering: .descending))
            .limit(to: 250)
        
        subscription = collection.subscribe { [weak self] result in
            switch result {
            case .success(let documents):
                self?.messages = documents.flatMap({ Message.initialize(withDocument: $0) }).reversed()
                
            case .failure:
                self?.messages = []
            }
            
            self?.delegate?.messagesChanged()
        }
    }
}
