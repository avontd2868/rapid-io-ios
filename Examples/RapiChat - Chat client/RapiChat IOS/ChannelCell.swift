//
//  ChannelCell.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class ChannelCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel! {
        didSet {
            nameLabel.textColor = .black
        }
    }
    @IBOutlet var lastMessageTextLabel: UILabel! {
        didSet {
            lastMessageTextLabel.textColor = .appText
        }
    }
    @IBOutlet var lastMessageDateLabel: UILabel! {
        didSet {
            lastMessageDateLabel.textColor = .appText
        }
    }
    @IBOutlet weak var highlightView: UIView! {
        didSet {
            highlightView.backgroundColor = .appRed
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        backgroundColor = highlighted ? UIColor.appRed.withAlphaComponent(0.1) : .clear
    }
    
    fileprivate let nameFont = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
    fileprivate let nameFontUnread = UIFont.boldSystemFont(ofSize: 18)
    fileprivate let textFont = UIFont.systemFont(ofSize: 14)
    fileprivate let textFontUnread = UIFont.boldSystemFont(ofSize: 14)
    fileprivate let dateFont = UIFont.systemFont(ofSize: 12)
    fileprivate let dateFontUnread = UIFont.boldSystemFont(ofSize: 12)

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
        highlightView.isHidden = !channel.unread
    }
}
