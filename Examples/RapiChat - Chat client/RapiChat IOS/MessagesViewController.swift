//
//  MessagesViewController.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class MessagesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var accessoryViewHeight: NSLayoutConstraint!
    
    var channel: Channel!
    var username: String!
    
    fileprivate var manager: MessagesManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
        
        registerForKeyboardFrameChangeNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Actions
    @IBAction func sendMessage(_ sender: Any) {
        manager.sendMessage(textView.text)
        PNManager.shared.sendNotification(toChannel: channel.name, withText: textView.text)
        textView.text = ""
    }
    
}

fileprivate extension MessagesViewController {
    
    func setupController() {
        manager = MessagesManager(forChannel: channel.name, withDelegate: self)
        textView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        setupUI()
    }
    
    func setupUI() {
        navigationItem.title = channel.name
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorColor = .appSeparator
        
        sendButton.setTitleColor(.appRed, for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        
        configureView()
    }
    
    func configureView() {
        configureSendButton()
        configureInputBarHeight()
    }
    
    func configureSendButton() {
        UIView.animate(withDuration: 0.2, animations: {
            self.sendButton.alpha = self.textView.text.isEmpty ? 0.5 : 1
        }, completion: { _ in
            self.sendButton.isEnabled = !self.textView.text.isEmpty
        })
    }
    
    func configureInputBarHeight() {
        let maxHeigth: CGFloat
        if #available(iOS 11.0, *) {
            maxHeigth = (view.frame.height - additionalSafeAreaInsets.bottom) / 2
        } else {
            maxHeigth = view.frame.height
        }
        
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
        if manager.messages.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: manager.messages.count - 1, section: 0), at: .top, animated: animated)
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

}

extension MessagesViewController: MessagesManagerDelegate {
    
    func messagesChanged() {
        tableView.reloadData()
        
        UserDefaultsManager.readMessage(withID: manager.messages.last?.id ?? "", inChannel: channel.name)
        channel.updateRead()
        
        configureView()
        scrollToBottom(animated: true)
    }
}

extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        let message = manager.messages[indexPath.row]
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
extension MessagesViewController: AdjustsToKeyboard {
    
    func animateWithKeyboard(height: CGFloat) {
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets.bottom = height
        } else {
            // Fallback on earlier versions
        }
    }
    
    func completeKeyboardAnimation(height: CGFloat) {
        if !isScrolledTopBottom() {
            scrollToBottom(animated: true)
        }
    }
}
