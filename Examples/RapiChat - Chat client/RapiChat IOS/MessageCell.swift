//
//  MessageCell.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    
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
            
            dateFormatter.timeStyle = .none
        }
    }
    
    func configure(withMessage message: Message) {
        senderLabel.text = message.sender
        messageTextLabel.text = message.text
        
        updateDateFormatterStyleWithDate(message.sentDate)
        timeLabel.text = dateFormatter.string(from: message.sentDate)
    }
}
