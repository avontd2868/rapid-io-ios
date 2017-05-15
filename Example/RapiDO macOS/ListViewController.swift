//
//  ViewController.swift
//  ExampleMacOSApp
//
//  Created by Jan on 15/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa
import Rapid

class ListViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    
    var tasks: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Rapid.timeout = 10
        Rapid.logLevel = .debug
        Rapid.configure(withAPIKey: "MTMuNjQuNzcuMjAyOjgwODA=")
        Rapid.authorize(withAccessToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJydWxlcyI6W3siY29sbGVjdGlvbiI6ImRlbW9hcHAtLioiLCJyZWFkIjp0cnVlLCJjcmVhdGUiOnRydWUsInVwZGF0ZSI6dHJ1ZSwiZGVsZXRlIjp0cnVlfV19.9e1b1eT1cfoxz7QqydF0eiFRiFP6qvHRHsqHxJ_ymuo")
        Rapid.isCacheEnabled = true
        
        tableView.dataSource = self
        tableView.delegate = self
        
        Rapid.collection(named: "demoapp-eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9").subscribe { (_, documents) in
            self.tasks = documents.flatMap({ Task(withSnapshot: $0) })
            self.tableView.reloadData()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension ListViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    enum ColumnIdentifier: String {
        case completed = "Done"
        case title = "Title"
        case description = "Desc"
        case priority = "Priority"
        case tags = "Tags"
        
        var cellIdentifier: String {
            return "\(self.rawValue)CellID"
        }
    }
    
    enum CellIdentifiers {
        case completed
        case title
        case description
        case priority
        case tags
        
        var rawValue: String {
            let columnID: String
            
            switch self {
            case .completed:
                columnID = ColumnIdentifier.completed.rawValue
                
            case .title:
                columnID = ColumnIdentifier.title.rawValue
                
            case .description:
                columnID = ColumnIdentifier.description.rawValue
                
            case .priority:
                columnID = ColumnIdentifier.priority.rawValue
                
            case .tags:
                columnID = ColumnIdentifier.tags.rawValue
            }
            
            return "\(columnID)CellID"
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let task = tasks[row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        guard let id = tableColumn?.identifier, let column = ColumnIdentifier(rawValue: id) else {
            return nil
        }

        let view = tableView.make(withIdentifier: column.cellIdentifier, owner: nil)
        
        if let cell = view as? NSTableCellView {
        switch column {
        case .completed:
            if let cell = view as? CheckBoxCellView {
                cell.delegate = self
                cell.textField?.stringValue = ""
                cell.checkBox.state = task.completed ? 1 : 0
            }
            
        case .title:
            cell.textField?.stringValue = task.title
            
        case .description:
            cell.textField?.stringValue = task.description ?? ""
            
        case .priority:
            cell.textField?.stringValue = task.priority.title
            
        case .tags:
            cell.textField?.stringValue = task.tags.map({ $0.title }).joined(separator: ",")
        }
        }
        
        return view
    }
}

extension ListViewController: CheckBoxCellViewDelegate {
    
    func checkBoxCellChangedValue(_ cellView: CheckBoxCellView, value: Bool) {
        let row = tableView.row(for: cellView)
    }
}
