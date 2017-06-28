//
//  MessagesViewController.swift
//  RapiChat
//
//  Created by Jan Schwarz on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class MessagesViewController: NSViewController {
    
    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var headerTitle: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var accessoryView: NSView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var placeholderLabel: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var accessoryViewHeight: NSLayoutConstraint!

    var channel: Channel? {
        didSet {
            setupController()
        }
    }
    var username: String?
    
    fileprivate var manager: MessagesManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.channelSelected(_:)), name: Notification.Name("ChannelSelectedNotification"), object: nil)
        
        setupController()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func channelSelected(_ notification: Notification) {
        if let channel = notification.object as? Channel {
            self.channel = channel
        }
    }
}

fileprivate extension MessagesViewController {
    
    func setupController() {
        if let channel = channel {
            manager = MessagesManager(forChannel: channel.name, withDelegate: self)
        }
        textView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        setupUI()
    }
    
    func setupUI() {
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.white.cgColor
        headerTitle.font = NSFont.boldSystemFont(ofSize: 15)
        
        tableView.gridColor = .appSeparator
        tableView.selectionHighlightStyle = .none
        
        sendButton.attributedTitle = NSAttributedString(string: "SEND", attributes: [NSForegroundColorAttributeName: NSColor.appRed, NSFontAttributeName: NSFont.boldSystemFont(ofSize: 15)])
        
        configureView()
    }
    
    func configureView() {
        headerTitle.stringValue = channel?.name ?? ""
        
        configureActivityIndicator()
        configureSendButton(withText: textView.string)
        configureTextViewPlacholder(withText: textView.string)
        configureInputBarHeight(withText: textView.string)
    }
    
    func configureActivityIndicator() {
        if manager?.messages == nil {
            activityIndicator.startAnimation(self)
        }
        else {
            activityIndicator.stopAnimation(self)
        }
    }
    
    func configureSendButton(withText text: String?) {
        let messagesLoaded = self.manager?.messages != nil
        let empty = text?.isEmpty ?? true
        
        self.sendButton.isEnabled = !empty && messagesLoaded
    }
    
    func configureTextViewPlacholder(withText text: String?) {
        //placeholderLabel.isHidden = (textView.string?.characters.count ?? 0) > 0
    }
    
    func configureInputBarHeight(withText text: String?) {
        let maxHeigth: CGFloat = 300
        
        let newTextViewSize = textView.fittingSize
        
        let newInputBarHeight = newTextViewSize.height + 16
        
        let newHeight = max(min(newInputBarHeight, floor(maxHeigth)), 50)
        
        if newHeight != accessoryViewHeight.constant {
            accessoryViewHeight.constant = newHeight
            
            if self.isScrolledTopBottom(within: 20) {
                self.scrollToBottom(animated: false)
            }
        }
    }
    
    func isScrolledTopBottom(within delta: CGFloat = 1.0) -> Bool {
        return false
    }
    
    func scrollToBottom(animated: Bool) {
        if let count = manager?.messages?.count {
            tableView.scrollRowToVisible(count - 1)
        }
    }

}

extension MessagesViewController: MessagesManagerDelegate {
    
    func messagesChanged(_ manager: MessagesManager) {
        tableView.reloadData()
        
        if manager.channelID == channel?.name {
            UserDefaultsManager.readMessage(withID: manager.messages?.last?.id ?? "", inChannel: manager.channelID)
            channel?.updateRead()
        }
        
        configureView()
        scrollToBottom(animated: true)
    }
}

extension MessagesViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return manager?.messages?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let message = manager?.messages?[row] else {
            return nil
        }
        
        let view = tableView.make(withIdentifier: "MessageCellID", owner: nil)
        
        if let cell = view as? NSTableCellView {
            cell.textField?.stringValue = "\(message.sender): \(message.text)"
        }
        
        return view
    }
    
}

extension MessagesViewController: NSTextViewDelegate {
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let text = ((textView.string ?? "") as NSString).replacingCharacters(in: affectedCharRange, with: replacementString ?? "")
        
        configureSendButton(withText: text)
        configureTextViewPlacholder(withText: text)
        configureInputBarHeight(withText: text)
        
        return true
    }
}
