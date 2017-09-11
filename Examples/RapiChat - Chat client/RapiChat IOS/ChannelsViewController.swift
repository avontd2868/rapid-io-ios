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
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTitle: UILabel!
    
    private var username = UserDefaultsManager.username
    
    private var channelsManager: ChannelsManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        
        if username == nil {
            enterUsername()
        }
    }

}

fileprivate extension ChannelsViewController {
    
    func setupController() {
        channelsManager = ChannelsManager(withDelegate: self)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .appSeparator
        
        headerView.backgroundColor = .appRed
        headerTitle.textColor = .white
        
        configureUsername()
    }
    
    func configureUsername() {
        if let username = username {
            headerTitle.text = "Your username is \(username)"
        }
    }
    
    func enterUsername() {
        let alert = UIAlertController(title: "Username", message: "You need to choose your username", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        let action = UIAlertAction(title: "Done", style: .default) { _ in
            UserDefaultsManager.username = alert.textFields?.first?.text ?? ""
            self.username = UserDefaultsManager.username
            self.configureUsername()
        }
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func presentMessages(forChannel channel: Channel) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        
        controller.channel = channel
        controller.username = username
        
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ChannelsViewController: ChannelsManagerDelegate {
    
    func channelsChanged() {
        tableView.reloadData()
    }
}

// MARK: - Table view data source
extension ChannelsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelsManager.channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelCell
        
        let channel = channelsManager.channels[indexPath.row]
        cell.configure(withChannel: channel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let channel = channelsManager.channels[indexPath.row]
        presentMessages(forChannel: channel)
    }

}
