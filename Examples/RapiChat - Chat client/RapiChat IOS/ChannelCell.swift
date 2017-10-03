//
//  ChannelCell.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class ChannelCell: UITableViewCell {

    func configure(withChannel channel: Channel) {
        let title = NSMutableAttributedString(string: channel.name, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15)])
        
        if let lastMessage = channel.lastMessage {
            let detail = NSAttributedString(string: " - \(lastMessage.sender): \(lastMessage.text ?? "")", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)])
            title.append(detail)
        }
        
        textLabel?.attributedText = title
        
        let unread = isUnread(channel: channel)
        backgroundColor = unread ? .yellow : .white
    }
    
    private func isUnread(channel: Channel) -> Bool {
        if let messageID = channel.lastMessage?.id {
            return messageID != UserDefaultsManager.lastReadMessage(inChannel: channel.name)
        }
        else {
            return false
        }
    }
}
