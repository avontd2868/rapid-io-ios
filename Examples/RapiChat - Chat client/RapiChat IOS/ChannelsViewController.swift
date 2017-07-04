//
//  ChannelsViewController.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class ChannelsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTitle: UILabel!
    
    fileprivate var channelsManager: ChannelsManager!
    fileprivate var username: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }

}

fileprivate extension ChannelsViewController {
    
    func setupController() {
        channelsManager = ChannelsManager(withDelegate: self)
        
        UserDefaultsManager.generateUsername { [weak self] username in
            self?.username = username
            self?.configureView()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .appSeparator
        
        configureView()
    }
    
    func configureView() {
        headerView.backgroundColor = .appRed
        headerTitle.textColor = .white
        
        if let username = username {
            let normalText = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.systemFont(ofSize: 13)]
            let hightlightedText = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 13)]
            headerTitle.attributedText = "Your username is \(username)".highlight(string: username, textAttributes: normalText, highlightedAttributes: hightlightedText)
        }
        
        if channelsManager.channels == nil || username == nil {
            activityIndicator.startAnimating()
            tableView.isHidden = true
        }
        else {
            activityIndicator.stopAnimating()
            tableView.isHidden = false
        }
    }
    
    func presentMessages(forChannel channel: Channel) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        
        controller.channel = channel
        controller.username = username
        
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ChannelsViewController: ChannelsManagerDelegate {
    
    func channelsChanged(_ manager: ChannelsManager) {
        tableView.reloadData()
        
        configureView()
    }
}

// MARK: - Table view data source
extension ChannelsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelsManager.channels?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelCell
        
        if let channel = channelsManager.channels?[indexPath.row] {
            cell.configure(withChannel: channel)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let channel = channelsManager.channels?[indexPath.row] {
            presentMessages(forChannel: channel)
        }
    }

}
