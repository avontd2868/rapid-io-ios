//
//  Channel.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

class Channel {
    
    let name: String
    let lastMessage: Message?
    
    init(withDocument document: RapidDocument) {
        self.name = document.id
        
        if let dict = document.value?[Channel.lastMessage] as? [AnyHashable: Any], let id = dict[Channel.lastMessageID] as? String {
            self.lastMessage = Message(withID: id, dictionary: dict)
        }
        else {
            self.lastMessage = nil
        }
    }
}

extension Channel {
    static let lastMessageID = "id"
    static let lastMessage = "lastMessage"
}
