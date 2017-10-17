//
//  MessageCell.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var senderLabel: UILabel! {
        didSet {
            senderLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            timeLabel.font = UIFont.systemFont(ofSize: 13)
        }
    }
    @IBOutlet weak var messageTextLabel: UILabel! {
        didSet {
            messageTextLabel.font = UIFont.systemFont(ofSize: 16)
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
    
    func configure(withMessage message: Message) {
        senderLabel.textColor = message.isMyMessage ? UIColor.red : .blue
        senderLabel.text = message.sender
        
        messageTextLabel.text = message.text
        
        updateDateFormatterStyleWithDate(message.sentDate)
        timeLabel.text = dateFormatter.string(from: message.sentDate)
    }
}
