//
//  ChannelCell.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class ChannelCell: NSTableCellView {

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var messageTextLabel: NSTextField!
    
    fileprivate let nameFont = NSFont.boldSystemFont(ofSize: 16)
    fileprivate let nameFontUnread = NSFont.boldSystemFont(ofSize: 16)
    fileprivate let textFont = NSFont.systemFont(ofSize: 12)
    fileprivate let textFontUnread = NSFont.boldSystemFont(ofSize: 12)
    fileprivate let dateFont = NSFont.systemFont(ofSize: 10)
    fileprivate let dateFontUnread = NSFont.boldSystemFont(ofSize: 10)
    
    func configure(withChannel channel: Channel, selected: Bool) {
        nameLabel.stringValue = channel.name
        
        if let lastMessage = channel.lastMessage {
            messageTextLabel.stringValue = "\(lastMessage.sender): \(lastMessage.text)"
            let nsDate = NSDate(timeIntervalSince1970: lastMessage.sentDate.timeIntervalSince1970)
            timeLabel.stringValue = nsDate.timeAgoSinceNow()
        }
        else {
            messageTextLabel.stringValue = ""
            timeLabel.stringValue = ""
        }
        
        nameLabel.font = channel.unread ? nameFontUnread : nameFont
        messageTextLabel.font = channel.unread ? textFontUnread : textFont
        timeLabel.font = channel.unread ? dateFontUnread : dateFont
        nameLabel.textColor = selected ? NSColor.white : .textColor
        messageTextLabel.textColor = selected ? NSColor.white : .textColor
        timeLabel.textColor = selected ? NSColor.white : .textColor
        
        wantsLayer = true
        layer?.backgroundColor = selected ? NSColor.appRed.withAlphaComponent(0.5).cgColor : NSColor.clear.cgColor
    }
    
}
