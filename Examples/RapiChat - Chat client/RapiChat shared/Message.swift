//
//  Message.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

struct Message: Codable {
    
    let id: String
    let channelID: String
    let text: String?
    let sender: String
    let sentDate: Date
    
    enum CodingKeys : String, CodingKey {
        case id = "id"
        case channelID = "channelId"
        case text = "text"
        case sender = "senderName"
        case sentDate = "sentDate"
    }
    
    var isMyMessage: Bool {
        return sender == UserDefaultsManager.username
    }
}
