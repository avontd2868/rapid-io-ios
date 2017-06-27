//
//  ChannelsViewController.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class ChannelsViewController: UITableViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    fileprivate var channelsManager: ChannelsManager!

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
        
        setupUI()
    }
    
    func setupUI() {
        if channelsManager.channels == nil {
            activityIndicator.startAnimating()
        }
        else {
            activityIndicator.stopAnimating()
        }
    }
    
    func presentMessages(forChannel channel: Channel) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        
        controller.channel = channel
        
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ChannelsViewController: ChannelsManagerDelegate {
    
    func channelsChanged(_ manager: ChannelsManager) {
        tableView.reloadData()
        
        setupUI()
    }
}

// MARK: - Table view data source
extension ChannelsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelsManager.channels?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelCell
        
        if let channel = channelsManager.channels?[indexPath.row] {
            cell.configure(withChannel: channel)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let channel = channelsManager.channels?[indexPath.row] {
            presentMessages(forChannel: channel)
        }
    }

}
