//
//  MessageCellView.swift
//  RapiChat
//
//  Created by Jan on 29/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class MessageCellView: NSTableCellView {
    
    static let textFont = NSFont.systemFont(ofSize: 14)
    
    @IBOutlet weak var senderLabel: NSTextField! {
        didSet {
            senderLabel.font = NSFont.boldSystemFont(ofSize: 12)
        }
    }
    @IBOutlet weak var messageTextLabel: NSTextField! {
        didSet {
            messageTextLabel.font = MessageCellView.textFont
            messageTextLabel.textColor = .appText
            messageTextLabel.usesSingleLineMode = false
        }
    }
    @IBOutlet weak var timeLabel: NSTextField! {
        didSet {
            timeLabel.font = NSFont.systemFont(ofSize: 12)
            timeLabel.textColor = .appText
        }
    }

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        return formatter
    }()
    
    func updateDateFormatterStyleWithDate(_ date: Date) {
        if (date as NSDate).isToday() {
            dateFormatter.dateStyle = .none
            
            dateFormatter.timeStyle = .short
        }
        else {
            dateFormatter.dateStyle = .short
            
            dateFormatter.timeStyle = .short
        }
    }
    
    func configure(withMessage message: Message, myUsername: String?) {
        senderLabel.textColor = message.sender == myUsername ? NSColor.appRed : .appBlue
        senderLabel.stringValue = message.sender

        messageTextLabel.stringValue = message.text
        
        updateDateFormatterStyleWithDate(message.sentDate)
        timeLabel.stringValue = dateFormatter.string(from: message.sentDate)
    }
    
}
