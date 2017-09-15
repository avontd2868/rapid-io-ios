//
//  ChannelsViewController.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class ChannelsViewController: UITableViewController {
    
    private var subscription: RapidSubscription?
    
    private(set) var channels: [Channel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    deinit {
        subscription?.unsubscribe()
    }

}

private extension ChannelsViewController {
    
    func setupController() {
        UserDefaultsManager.username = "Jan Schwarz"
        
        navigationItem.title = "Channels"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        subscribeToChannels()
    }
    
    func presentMessages(forChannel channel: Channel) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        
        controller.channel = channel
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func subscribeToChannels() {
        // Get rapid.io collection reference
        // Order it according to document ID
        // Subscribe
        let collection = Rapid.collection(named: "channels")
            .order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
        
        subscription = collection.subscribe { [weak self] result in
            switch result {
            case .success(let documents):
                self?.channels = documents.flatMap({ Channel(withDocument: $0) })
                
            case .failure:
                self?.channels = []
            }
            
            self?.tableView.reloadData()
        }
    }
}

// MARK: - Table view data source
extension ChannelsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelCell
        
        let channel = channels[indexPath.row]
        cell.configure(withChannel: channel)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = channels[indexPath.row]
        presentMessages(forChannel: channel)
    }

}
