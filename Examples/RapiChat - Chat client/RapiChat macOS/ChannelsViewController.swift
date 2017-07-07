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

    fileprivate var channelsManager: ChannelsManager!
    fileprivate var username: String?
    fileprivate var selectedIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable), name: Notification.Name("ReadMessagesUpdated"), object: nil)
        
        setupRapid()
        setupController()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

fileprivate extension ChannelsViewController {
    
    func setupRapid() {
        // Set log level
        Rapid.logLevel = .debug
        // Configure shared singleton with API key
        Rapid.configure(withApiKey: Constants.apiKey)
        // Enable data cache
        Rapid.isCacheEnabled = true
        // Set timeout for requests
        Rapid.timeout = 10
        
        TimeManager.shared.initialize()
    }
    
    func setupController() {
        channelsManager = ChannelsManager(withDelegate: self)
        
        UserDefaultsManager.generateUsername { [weak self] username in
            self?.username = username
            self?.configureView()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.gridColor = .appSeparator
        tableView.selectionHighlightStyle = .none
        
        configureView()
    }
    
    func configureView() {
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.white.cgColor
        
        if let username = username {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let normalText = [NSAttributedStringKey.foregroundColor: NSColor.appText, NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13), NSAttributedStringKey.paragraphStyle: paragraphStyle]
            let hightlightedText = [NSAttributedStringKey.foregroundColor: NSColor.appText, NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 13), NSAttributedStringKey.paragraphStyle: paragraphStyle]
            headerTitle.attributedStringValue = "Your username is\n\(username)".highlight(string: username, textAttributes: normalText, highlightedAttributes: hightlightedText)
        }
        
        if channelsManager.channels == nil || username == nil {
            activityIndicator.startAnimation(self)
            tableView.isHidden = true
        }
        else {
            activityIndicator.stopAnimation(self)
            tableView.isHidden = false
        }
        
        if let index = selectedIndex {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        else if username != nil && (channelsManager.channels?.count ?? 0) > 0 {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    @objc func reloadTable() {
        tableView.reloadData()
        
        configureView()
    }
    
    func presentChannel(_ channel: Channel) {
        NotificationCenter.default.post(name: Notification.Name("ChannelSelectedNotification"), object: channel, userInfo: ["username": username ?? ""])
    }
}

extension ChannelsViewController: ChannelsManagerDelegate {
    
    func channelsChanged(_ manager: ChannelsManager) {
        reloadTable()
    }
}

extension ChannelsViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return channelsManager.channels?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let channel = channelsManager.channels?[row] else {
            return nil
        }
        
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
        
        if let channel = channelsManager.channels?[row] {
            presentChannel(channel)
        }
    }
    
}
