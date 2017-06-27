//
//  MessagesViewController.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class MessagesViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var bottomMarginConstraint: NSLayoutConstraint!
    
    var channel: Channel!
    
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
        textView.text = ""
    }
    
}

fileprivate extension MessagesViewController {
    
    func setupController() {
        manager = MessagesManager(forChannel: channel.name, withDelegate: self)
        
        setupUI()
    }
    
    func setupUI() {
        navigationItem.title = channel.name
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
}

extension MessagesViewController: MessagesManagerDelegate {
    
    func messagesChanged(_ manager: MessagesManager) {
        tableView.reloadData()
        
        UserDefaultsManager.readMessage(withID: manager.messages?.last?.id ?? "", inChannel: channel.name)
        channel.updateRead()
    }
}

extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.messages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        if let message = manager.messages?[indexPath.row] {
            cell.configure(withMessage: message)
        }
        
        return cell
    }
}

// MARK: - Adjust to keyboard
extension MessagesViewController: AdjustsToKeyboard {
    
    func animateWithKeyboard(height: CGFloat) {
        bottomMarginConstraint.constant = height
    }
}
