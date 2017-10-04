//
//  Channel.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

struct Channel: Codable {
    
    let name: String
    var lastMessage: Message?
    
    enum CodingKeys : String, CodingKey {
        case name = "id"
        case lastMessage = "lastMessage"
    }
    
    init(name: String, lastMessage: Message?) {
        self.name = name
        self.lastMessage = lastMessage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        lastMessage = try container.decodeIfPresent(Message.self, forKey: .lastMessage)
        
    }

}
