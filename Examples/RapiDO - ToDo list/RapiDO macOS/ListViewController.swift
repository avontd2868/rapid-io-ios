//
//  ViewController.swift
//  ExampleMacOSApp
//
//  Created by Jan on 15/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Cocoa
import Rapid

class ListViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var completionPopUp: NSPopUpButton!
    @IBOutlet weak var homeCheckBox: NSButton!
    @IBOutlet weak var homeBackgroundView: NSView!
    @IBOutlet weak var workCheckBox: NSButton!
    @IBOutlet weak var workBackgroundView: NSView!
    @IBOutlet weak var otherCheckBox: NSButton!
    @IBOutlet weak var otherBackgroundView: NSView!
    
    var tasks: [Task] = []
    
    fileprivate var subscription: RapidSubscription?
    fileprivate var ordering: RapidOrdering?
    fileprivate var filter: RapidFilterDescriptor?
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        formatter.timeStyle = .medium
        formatter.dateStyle = .medium
        
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRapid()
        setupUI()
        subscribe()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        homeBackgroundView.wantsLayer = true
        homeBackgroundView.layer?.backgroundColor = Tag.home.color.cgColor
        homeBackgroundView.layer?.cornerRadius = homeBackgroundView.frame.height/2
        
        workBackgroundView.wantsLayer = true
        workBackgroundView.layer?.backgroundColor = Tag.work.color.cgColor
        workBackgroundView.layer?.cornerRadius = workBackgroundView.frame.height/2
        
        otherBackgroundView.wantsLayer = true
        otherBackgroundView.layer?.backgroundColor = Tag.other.color.cgColor
        otherBackgroundView.layer?.cornerRadius = otherBackgroundView.frame.height/2
    }

    @IBAction func filter(_ sender: AnyObject) {
        var operands = [RapidFilterDescriptor]()
        
        if let item = completionPopUp.selectedItem {
            let index = completionPopUp.index(of: item)
            
            // Popup selected index equal to 0 means "show all tasks regardless completion state", so no filter is needed
            // Otherwise, create filter for either completed or incompleted tasks
            if index > 0 {
                let completed = index == 2
                operands.append(RapidFilter.equal(keyPath: Task.completedAttributeName, value: completed))
            }
        }
        
        // Create filter for selected tags
        var tags = [RapidFilterDescriptor]()
        if homeCheckBox.state.rawValue > 0 {
            tags.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: Tag.home.rawValue))
        }
        if workCheckBox.state.rawValue > 0 {
            tags.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: Tag.work.rawValue))
        }
        if otherCheckBox.state.rawValue > 0 {
            tags.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: Tag.other.rawValue))
        }
        // Combine single tag filters with logical "OR" operator
        if !tags.isEmpty {
            operands.append(RapidFilter.or(tags))
        }
        
        // If there are any filters combine them with logical "AND"
        if operands.isEmpty {
            filter = nil
        }
        else {
            filter = RapidFilter.and(operands)
        }
        
        subscribe()
    }
}

fileprivate extension ListViewController {
    
    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(self.tableViewDoubleClick(_:))
        
        for column in tableView.tableColumns {
            let columnID = ColumnIdentifier(rawValue: column.identifier.rawValue)
            
            switch columnID {
            case .some(.priority), .some(.title), .some(.completed), .some(.created):
                column.sortDescriptorPrototype = NSSortDescriptor(key: columnID?.rawValue ?? "", ascending: true)
                
            default:
                break
            }
        }
        
        homeCheckBox.title = Tag.home.title
        
        workCheckBox.title = Tag.work.title
        otherCheckBox.title = Tag.other.title
    }
    
    func setupRapid() {
        // Set log level
        Rapid.logLevel = .info
        
        // Configure shared singleton with API key
        Rapid.configure(withApiKey: "<YOUR API KEY>")
        
        // Enable data cache
        Rapid.isCacheEnabled = true
        
        // Set timeout for requests
        Rapid.timeout = 10
    }
    
    func subscribe() {
        // If there is a previous subscription then unsubscribe from it
        subscription?.unsubscribe()
        
        tasks.removeAll()
        tableView.reloadData()
        
        // Get Rapid collection reference with a given name
        var collection = Rapid.collection(named: Constants.collectionName)
        
        // If a filter is set, modify the collection reference with it
        if let filter = filter {
            collection.filtered(by: filter)
        }
        
        // If a ordering is set, modify the collection reference with it
        if let order = ordering {
            collection.ordered(by: order)
        }
        
        // Subscribe to the collection
        // Store a subscribtion reference to be able to unsubscribe from it
        subscription = collection.subscribe() { result in
            switch result {
            case .success(let documents):
                self.tasks = documents.flatMap({ Task(withSnapshot: $0) })
                
            case .failure:
                self.tasks = []
            }
            
            self.tableView.reloadData()
        }
    }
}

extension ListViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    enum ColumnIdentifier: String {
        case completed = "Done"
        case title = "Title"
        case description = "Desc"
        case created = "Created"
        case priority = "Priority"
        case tags = "Tags"
        
        var cellIdentifier: String {
            return "\(self.rawValue)CellID"
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let task = tasks[row]

        guard let id = tableColumn?.identifier, let column = ColumnIdentifier(rawValue: id.rawValue) else {
            return nil
        }

        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: column.cellIdentifier), owner: nil)
        
        if let cell = view as? NSTableCellView {
        switch column {
        case .completed:
            if let cell = view as? CheckBoxCellView {
                cell.delegate = self
                cell.textField?.stringValue = ""
                cell.checkBox.state = NSControl.StateValue(rawValue: task.completed ? 1 : 0)
            }
            
        case .title:
            cell.textField?.stringValue = task.title
            
        case .description:
            cell.textField?.stringValue = task.description ?? ""
            
        case .created:
            cell.textField?.stringValue = dateFormatter.string(from: task.createdAt)
            
        case .priority:
            cell.textField?.stringValue = task.priority.title
            
        case .tags:
            if let cell = view as? TagsCellView {
                cell.configure(withTags: task.tags)
            }
        }
        }
        
        return view
    }
    
    @objc func tableViewDoubleClick(_ sender: AnyObject) {
        let row = tableView.selectedRow
        
        guard row >= 0 else {
            return
        }
        
        let task = tasks[row]
        let delegate = NSApplication.shared.delegate as? AppDelegate
        delegate?.updateTask(task)
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        // If there is no sort descriptor, remove current ordering
        guard let descriptor = tableView.sortDescriptors.first else {
            ordering = nil
            subscribe()
            return
        }
        
        guard let identifier = descriptor.key, let column = ColumnIdentifier(rawValue: identifier) else {
            return
        }
        
        // Get an ordering type
        let order = descriptor.ascending ? RapidOrdering.Ordering.ascending : .descending
        
        // Create an ordering
        switch column {
        case .completed:
            ordering = RapidOrdering(keyPath: Task.completedAttributeName, ordering: order)
            
        case .title:
            ordering = RapidOrdering(keyPath: Task.titleAttributeName, ordering: order)
            
        case .priority:
            ordering = RapidOrdering(keyPath: Task.priorityAttributeName, ordering: order)
            
        case .created:
            ordering = RapidOrdering(keyPath: Task.createdAttributeName, ordering: order)
            
        default:
            break
        }
        
        subscribe()
    }
}

extension ListViewController: CheckBoxCellViewDelegate {
    
    func checkBoxCellChangedValue(_ cellView: CheckBoxCellView, value: Bool) {
        let row = tableView.row(for: cellView)
        
        if row >= 0 {
            let task = tasks[row]
            task.updateCompleted(value)
        }
    }
}
