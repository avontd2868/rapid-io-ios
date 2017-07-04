//
//  MessagesViewController.swift
//  RapiChat
//
//  Created by Jan Schwarz on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class PlaceholderTextField: NSTextField {
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class MessagesViewController: NSViewController {
    
    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var headerTitle: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var accessoryView: NSView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var placeholderLabel: PlaceholderTextField!
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
    
    override func viewDidAppear() {
        super.viewWillAppear()
        
        configureActivityIndicator()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        manager?.sendMessage(textView.string ?? "")
        textView.string = ""
    }

    @objc func channelSelected(_ notification: Notification) {
        if let channel = notification.object as? Channel {
            self.channel = channel
        }
        if let username = notification.userInfo?["username"] as? String {
            self.username = username
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
        
        accessoryView.wantsLayer = true
        accessoryView.layer?.backgroundColor = NSColor.white.cgColor
        
        tableView.gridColor = .appSeparator
        tableView.selectionHighlightStyle = .none
        
        textView.font = NSFont.systemFont(ofSize: 15)
        textView.textColor = .appText
        
        activityIndicator.isIndeterminate = true
        activityIndicator.usesThreadedAnimation = true
        
        placeholderLabel.stringValue = "Write your message"
        placeholderLabel.font = NSFont.systemFont(ofSize: 15)
        placeholderLabel.textColor = NSColor.appText.withAlphaComponent(0.7)
        
        sendButton.attributedTitle = NSAttributedString(string: "SEND", attributes: [NSAttributedStringKey.foregroundColor: NSColor.appRed, NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 15)])
        
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
            activityIndicator.isHidden = false
            activityIndicator.startAnimation(nil)
        }
        else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimation(nil)
        }
    }
    
    func configureSendButton(withText text: String?) {
        let messagesLoaded = self.manager?.messages != nil
        let empty = text?.isEmpty ?? true
        
        self.sendButton.isEnabled = !empty && messagesLoaded
    }
    
    func configureTextViewPlacholder(withText text: String?) {
        placeholderLabel.isHidden = !(text?.isEmpty ?? true)
    }
    
    func configureInputBarHeight(withText text: String?) {
        let maxHeigth: CGFloat = 115
        
        let newTextViewSize = textView.string.sizeWithFont(textView.font!, constraintWidth: textView.frame.width - 10) ?? CGSize.zero
        
        let newInputBarHeight = newTextViewSize.height + 20
        
        let newHeight = max(min(newInputBarHeight, floor(maxHeigth)), 30)
        
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
            let previous = channel?.unread ?? false
            channel?.updateRead()
            let current = channel?.unread ?? false
            if previous != current {
                NotificationCenter.default.post(name: Notification.Name("ReadMessagesUpdated"), object: nil)
            }
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
        
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageCellID"), owner: nil)
        
        if let cell = view as? MessageCellView {
            cell.configure(withMessage: message, myUsername: username)
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let message = manager?.messages?[row] else {
            return 55
        }
        
        let size = message.text.sizeWithFont(MessageCellView.textFont, constraintWidth: tableView.frame.width - 170)
        
        return max(55, size.height + 38)
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
