//
//  ChannelsViewController.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa
import Rapid

class ChannelsViewController: NSViewController {

    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var headerTitle: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    private var subscription: RapidSubscription?
    
    private(set) var channels: [Channel] = []
    
    private var selectedIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable), name: Notification.Name("ReadMessagesUpdated"), object: nil)
        
        setupRapid()
        setupController()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        subscription?.unsubscribe()
    }
    
}

private extension ChannelsViewController {
    
    func setupRapid() {
        // Set log level
        Rapid.logLevel = .info
        
        // Configure shared singleton with API key
        Rapid.configure(withApiKey: "<YOUR API KEY>")
        
        // Enable data cache
        Rapid.isCacheEnabled = true
        
        Rapid.decoder.rapidDocumentDecodingKeys.documentIdKey = "id"
        Rapid.decoder.dateDecodingStrategy = .millisecondsSince1970
        Rapid.encoder.dateEncodingStrategy = .millisecondsSince1970
    }
    
    func setupController() {
        UserDefaultsManager.username = "Jan Schwarz"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.gridColor = .appSeparator
        tableView.selectionHighlightStyle = .none
        
        subscribeToChannels()
    }
    
    func subscribeToChannels() {
        // Get rapid.io collection reference
        // Order it according to document ID
        // Subscribe
        let collection = Rapid.collection(named: "channels")
            .order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
        
        subscription = collection.subscribe(decodableType: Channel.self) { [weak self] result in
            switch result {
            case .success(let channels):
                self?.channels = channels
                
            case .failure:
                self?.channels = []
            }
            
            self?.reloadTable()
        }
    }

    func configureView() {
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.white.cgColor
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        headerTitle.stringValue = "Your username is\n\(UserDefaultsManager.username)"

        activityIndicator.stopAnimation(self)
        tableView.isHidden = false
        
        if let index = selectedIndex {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        else if channels.count > 0 {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    @objc func reloadTable() {
        tableView.reloadData()
        
        configureView()
    }
    
    func presentChannel(_ channel: Channel) {
        NotificationCenter.default.post(name: Notification.Name("ChannelSelectedNotification"), object: channel, userInfo: ["username": UserDefaultsManager.username])
    }
}

extension ChannelsViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let channel = channels[row]
        
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChannelCellID"), owner: nil)
        
        if let cell = view as? ChannelCellView {
            cell.configure(withChannel: channel, selected: tableView.selectedRow == row)
        }
        
        return view
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        
        guard row >= 0 else {
            tableView.selectRowIndexes(IndexSet(integer: selectedIndex ?? 0), byExtendingSelection: false)
            return
        }
        
        if let index = selectedIndex {
            tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
            selectedIndex = nil
        }
        
        selectedIndex = row
        tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        
        let channel = channels[row]
        presentChannel(channel)
    }
    
}
