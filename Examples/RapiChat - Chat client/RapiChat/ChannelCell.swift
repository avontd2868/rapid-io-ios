//
//  ChannelCell.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class ChannelCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var lastMessageTextLabel: UILabel!
    @IBOutlet var lastMessageDateLabel: UILabel!
    
    fileprivate let nameFont = UIFont.systemFont(ofSize: 17)
    fileprivate let nameFontUnread = UIFont.boldSystemFont(ofSize: 17)
    fileprivate let textFont = UIFont.systemFont(ofSize: 15)
    fileprivate let textFontUnread = UIFont.boldSystemFont(ofSize: 15)
    fileprivate let dateFont = UIFont.systemFont(ofSize: 13)
    fileprivate let dateFontUnread = UIFont.boldSystemFont(ofSize: 13)

    func configure(withChannel channel: Channel) {
        nameLabel.text = channel.name
        
        if let lastMessage = channel.lastMessage {
            lastMessageTextLabel.text = "\(lastMessage.sender): \(lastMessage.text)"
            let nsDate = NSDate(timeIntervalSince1970: lastMessage.sentDate.timeIntervalSince1970)
            lastMessageDateLabel.text = nsDate.timeAgoSinceNow()
        }
        else {
            lastMessageTextLabel.text = nil
            lastMessageDateLabel.text = nil
        }
        
        nameLabel.font = channel.unread ? nameFontUnread : nameFont
        lastMessageTextLabel.font = channel.unread ? textFontUnread : textFont
        lastMessageDateLabel.font = channel.unread ? dateFontUnread : dateFont
        backgroundColor = channel.unread ? .lightGray : .white
    }
}
