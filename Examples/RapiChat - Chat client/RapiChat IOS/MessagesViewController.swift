//
//  MessagesViewController.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class MessagesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var accessoryViewHeight: NSLayoutConstraint!
    
    var channel: Channel!
    
    private var subscription: RapidSubscription?

    private(set) var messages: [Message] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
        
        registerForKeyboardFrameChangeNotifications()
    }
    
    deinit {
        unregisterKeyboardFrameChangeNotifications()
        
        subscription?.unsubscribe()
    }

    // MARK: Actions
    @IBAction func sendMessage(_ sender: Any) {
        send(textView.text)
        textView.text = ""
    }
    
}

private extension MessagesViewController {
    
    func setupController() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)

        navigationItem.title = channel.name
        
        textView.delegate = self
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        configureView()
        
        subscribeToMessages()
    }
    
    func configureView() {
        self.sendButton.isEnabled = !self.textView.text.isEmpty

        let maxHeigth = (view.frame.height - additionalSafeAreaInsets.bottom) / 2
        
        let newTextViewSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let newInputBarHeight = newTextViewSize.height + 16
        
        let newHeight = max(min(newInputBarHeight, floor(maxHeigth)), 50)
        
        if newHeight != accessoryViewHeight.constant {
            accessoryViewHeight.constant = newHeight
            
            if self.isScrolledTopBottom(within: 20) {
                self.view.layoutIfNeeded()
                self.scrollToBottom(animated: false)
            }
        }
        
        textView.isScrollEnabled = (newInputBarHeight > maxHeigth)
    }

    func isScrolledTopBottom(within delta: CGFloat = 1.0) -> Bool {
        return abs(tableView.bounds.maxY - tableView.contentSize.height) < delta
    }
    
    func scrollToBottom(animated: Bool) {
        if messages.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .top, animated: animated)
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func send(_ text: String) {
        // Compose a dictionary with a message
        var message: [String: Any] = [
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
    
    func subscribeToMessages() {
        // Get rapid.io collection reference
        // Filter it according to channel ID
        // Order it according to sent date
        // Limit number of messages to 250
        // Subscribe
        let collection = Rapid.collection(named: "messages")
            .filter(by: RapidFilter.equal(keyPath: Message.channelID, value: channel.name))
            .order(by: RapidOrdering(keyPath: Message.sentDate, ordering: .descending))
            .limit(to: 250)
        
        subscription = collection.subscribe(decodableType: Message.self, block: { [weak self] result in
            switch result {
            case .success(let messages):
                self?.messages = messages.reversed()
                
            case .failure:
                self?.messages = []
            }
            
            self?.messagesChanged()
        })
    }
    
    func messagesChanged() {
        tableView.reloadData()
        
        UserDefaultsManager.readMessage(withID: messages.last?.id ?? "", inChannel: channel.name)
        
        configureView()
        scrollToBottom(animated: true)
    }

}

extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        let message = messages[indexPath.row]
        cell.configure(withMessage: message)
        
        return cell
    }
}

extension MessagesViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        configureView()
    }
    
}

// MARK: - Adjust to keyboard
private extension MessagesViewController {
    
    func registerForKeyboardFrameChangeNotifications(object: UIView? = nil) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func unregisterKeyboardFrameChangeNotifications(object: UIView? = nil) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: NSNotification) {
        
        if let userInfo = notification.userInfo,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let endFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let options = UIViewAnimationOptions(rawValue: UInt(curve << 16))
            let height = UIScreen.main.bounds.height - endFrame.origin.y
            
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: { () -> Void in
                self.animateWithKeyboard(height: height)
                self.view.layoutIfNeeded()
            }, completion: { (_) -> Void in
                self.completeKeyboardAnimation(height: height)
            })
        }
    }
    
    func animateWithKeyboard(height: CGFloat) {
        additionalSafeAreaInsets.bottom = height
    }
    
    func completeKeyboardAnimation(height: CGFloat) {
        if !isScrolledTopBottom() {
            scrollToBottom(animated: true)
        }
    }

}
