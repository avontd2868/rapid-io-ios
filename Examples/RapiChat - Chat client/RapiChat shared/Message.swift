//
//  Message.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

struct Message: Decodable {
    
    let id: String
    let channelID: String
    let text: String?
    let sender: String
    let sentDate: Date
    
    enum CodingKeys : String, CodingKey {
        case id = "$documentId"
        case channelID = "channelId"
        case text = "text"
        case sender = "senderName"
        case sentDate = "sentDate"
    }
    
    var isMyMessage: Bool {
        return sender == UserDefaultsManager.username
    }
    
    static func initialize(withDocument document: RapidDocument) -> Message? {
        guard let dict = document.value else {
            return nil
        }
        
        return Message(withID: document.id, dictionary: dict)
    }
    
    init?(withID id: String, dictionary: [String: Any]) {
        guard let channelID = dictionary[Message.channelID] as? String else {
            return nil
        }
        
        guard let sender = dictionary[Message.sender] as? String else {
            return nil
        }
        
        guard let sentDate = dictionary[Message.sentDate] as? TimeInterval else {
            return nil
        }
        
        self.id = id
        self.channelID = channelID
        self.sender = sender
        self.sentDate = Date(timeIntervalSince1970: sentDate/1000)
        self.text = dictionary[Message.text] as? String ?? ""
    }
}

extension Message {
    static let channelID = "channelId"
    static let sender = "senderName"
    static let sentDate = "sentDate"
    static let text = "text"
}
