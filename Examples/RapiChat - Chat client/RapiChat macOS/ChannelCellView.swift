//
//  ChannelCell.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class ChannelCellView: NSTableCellView {

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var messageTextLabel: NSTextField!
    @IBOutlet weak var unreadView: NSView! {
        didSet {
            unreadView.wantsLayer = true
            unreadView.layer?.backgroundColor = NSColor.appRed.cgColor
            unreadView.layer?.cornerRadius = 7.5
        }
    }
    @IBOutlet weak var nameLeading: NSLayoutConstraint!
    
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
        unreadView.isHidden = !channel.unread
        nameLeading.constant = channel.unread ? 30 : 15
        
        nameLabel.textColor = selected ? NSColor.white : .textColor
        messageTextLabel.textColor = selected ? NSColor.white : .textColor
        timeLabel.textColor = selected ? NSColor.white : .textColor
        
        wantsLayer = true
        layer?.backgroundColor = selected ? NSColor.appRed.cgColor : NSColor.clear.cgColor
    }
    
}
