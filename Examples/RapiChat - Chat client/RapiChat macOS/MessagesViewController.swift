//
//  MessagesViewController.swift
//  RapiChat
//
//  Created by Jan Schwarz on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa
import Rapid

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
    
    private var subscription: RapidSubscription?
    
    private(set) var messages: [Message]?

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
        if let channel = channel {
            sendMessage(textView.string, toChannel: channel)
            textView.string = ""
        }
    }

    @objc func channelSelected(_ notification: Notification) {
        if let channel = notification.object as? Channel {
            self.channel = channel
        }
    }
}

private extension MessagesViewController {
    
    func setupController() {
        textView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        setupUI()
        
        subscription?.unsubscribe()
        messages = nil
        
        if let channel = channel {
            subscribeToMessages(inChannel: channel)
        }
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
        if messages == nil {
            activityIndicator.isHidden = false
            activityIndicator.startAnimation(nil)
        }
        else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimation(nil)
        }
    }
    
    func configureSendButton(withText text: String?) {
        let messagesLoaded = messages != nil
        let empty = text?.isEmpty ?? true
        
        self.sendButton.isEnabled = !empty && messagesLoaded
    }
    
    func configureTextViewPlacholder(withText text: String?) {
        placeholderLabel.isHidden = !(text?.isEmpty ?? true)
    }
    
    func configureInputBarHeight(withText text: String?) {
        let maxHeigth: CGFloat = 115
        
        let newTextViewSize = textView.string.sizeWithFont(textView.font!, constraintWidth: textView.frame.width - 10)
        
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
        if let count = messages?.count, count > 0 {
            tableView.scrollRowToVisible(count - 1)
        }
    }
    
    func sendMessage(_ text: String, toChannel channel: Channel) {
        // Compose a dictionary with a message
        var message: [AnyHashable: Any] = [
            Message.channelID: channel.name,
            Message.sender: UserDefaultsManager.username,
            Message.sentDate: Rapid.serverTimestamp,
            Message.text: text
        ]
        
        // Get a new rapid.io document reference from the messages collection
        let messageRef = Rapid.collection(named: "messages")
            .newDocument()
        
        // Write the message to database
        messageRef.mutate(value: message)
        
        // Write last message to the channel
        message[Channel.lastMessageID] = messageRef.documentID
        Rapid.collection(named: "channels").document(withID: channel.name).merge(value: [Channel.lastMessage: message])
    }
    
    func subscribeToMessages(inChannel channel: Channel) {
        // Get rapid.io collection reference
        // Filter it according to channel ID
        // Order it according to sent date
        // Limit number of messages to 250
        // Subscribe
        let collection = Rapid.collection(named: "messages")
            .filter(by: RapidFilter.equal(keyPath: Message.channelID, value: channel.name))
            .order(by: RapidOrdering(keyPath: Message.sentDate, ordering: .descending))
            .limit(to: 250)
        
        subscription = collection.subscribe { [weak self] result in
            switch result {
            case .success(let documents):
                self?.messages = documents.flatMap({ Message.initialize(withDocument: $0) }).reversed()
                
            case .failure:
                self?.messages = []
            }
            
            self?.messagesChanged(inChannel: channel)
        }
    }

    func messagesChanged(inChannel channel: Channel) {
        tableView.reloadData()
        
        if let currentChannel = self.channel, currentChannel.name == channel.name {
            let previous = isUnread(channel: currentChannel)
            UserDefaultsManager.readMessage(withID: messages?.last?.id ?? "", inChannel: currentChannel.name)
            let current = isUnread(channel: currentChannel)
            if previous != current {
                NotificationCenter.default.post(name: Notification.Name("ReadMessagesUpdated"), object: nil)
            }
        }
        
        configureView()
        scrollToBottom(animated: true)
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

extension MessagesViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return messages?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let message = messages?[row] else {
            return nil
        }
        
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageCellID"), owner: nil)
        
        if let cell = view as? MessageCellView {
            cell.configure(withMessage: message)
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let message = messages?[row] else {
            return 55
        }
        
        let size = message.text.sizeWithFont(MessageCellView.textFont, constraintWidth: tableView.frame.width - 170)
        
        return max(55, size.height + 38)
    }
    
}

extension MessagesViewController: NSTextViewDelegate {
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let text = (textView.string as NSString).replacingCharacters(in: affectedCharRange, with: replacementString ?? "")
        
        configureSendButton(withText: text)
        configureTextViewPlacholder(withText: text)
        configureInputBarHeight(withText: text)
        
        return true
    }
}
