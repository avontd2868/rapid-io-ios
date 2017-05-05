//
//  FilterViewController.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

protocol FilterViewControllerDelegate: class {
    func filterViewControllerDidCancel(_ controller: FilterViewController)
    func filterViewControllerDidFinish(_ controller: FilterViewController, withFilter filter: RapidFilter?)
}

class FilterViewController: UIViewController {
    
    weak var delegate: FilterViewControllerDelegate?
    var filter: RapidFilter?
    
    var tagsTableViewControler: TagsTableViewController!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedTagsSegue" {
            tagsTableViewControler = segue.destination as! TagsTableViewController
        }
    }

    // MARK: Actions
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.filterViewControllerDidCancel(self)
    }
    
    @IBAction func done(_ sender: Any) {
        var operands = [RapidFilter]()
        
        if segmentedControl.selectedSegmentIndex != 1 {
            let completed = segmentedControl.selectedSegmentIndex == 0
            operands.append(RapidFilter.equal(keyPath: Task.completedAttributeName, value: completed))
        }
        
        let selectedRows = tagsTableViewControler.selectedRows
        if selectedRows.count < tagsTableViewControler.numberOfRows {
            var tagFilters = [RapidFilter]()
            
            for row in selectedRows {
                switch row {
                case 0:
                    tagFilters.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: Tag.home.rawValue))
                    
                case 1:
                    tagFilters.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: Tag.work.rawValue))
                    
                case 2:
                    tagFilters.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: Tag.other.rawValue))
                    
                default:
                    break
                }
            }
            
            operands.append(RapidFilter.or(tagFilters))
        }
        
        let filter: RapidFilter?
        if operands.count > 0 {
            filter = RapidFilter.and(operands)
        }
        else {
            filter = nil
        }
        
        delegate?.filterViewControllerDidFinish(self, withFilter: filter)
    }
}

fileprivate extension FilterViewController {
    
    func setupUI() {
        
        if let filter = filter as? RapidFilterCompound {
            var tagsSet = false
            var completionSet = false
            
            for operand in filter.operands {
                if let doneFilter = operand as? RapidFilterSimple {
                    completionSet = true
                    
                    let done = doneFilter.value as? Bool ?? false
                    let index = done ? 0 : 2
                    segmentedControl.selectedSegmentIndex = index
                }
                else if let tagOrFilter = operand as? RapidFilterCompound {
                    tagsSet = true
                    
                    var rows = [Int]()
                    for case let tagFilter as RapidFilterSimple in tagOrFilter.operands {
                        switch tagFilter.value as? String {
                        case .some(Tag.home.rawValue):
                            rows.append(0)
                            
                        case .some(Tag.work.rawValue):
                            rows.append(1)

                        case .some(Tag.other.rawValue):
                            rows.append(2)
                            
                        default:
                            break
                        }
                    }
                    tagsTableViewControler.selectRows(rows)
                }
            }
            
            if !tagsSet {
                tagsTableViewControler.selectAll()
            }
            if !completionSet {
                segmentedControl.selectedSegmentIndex = 1
            }
        }
        else {
            segmentedControl.selectedSegmentIndex = 1
            tagsTableViewControler.selectAll()
        }
    }
}

class TagsTableViewController: UITableViewController {
    
    let numberOfRows = 3
    
    var selectedRows: [Int] {
        var rows = [Int]()
        
        for row in 0..<numberOfRows {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)),
                cell.accessoryType == .checkmark {
                
                rows.append(row)
            }
        }
        
        return rows
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        if cell.accessoryType == .checkmark && selectedRows.count > 1 {
            cell.accessoryType = .none
        }
        else {
            cell.accessoryType = .checkmark
        }
    }
    
    func selectRows(_ rows: [Int]) {
        for row in 0..<numberOfRows {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = rows.contains(row) ? .checkmark : .none
        }
    }
    
    func selectAll() {
        for row in 0..<numberOfRows {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = .checkmark
        }
    }
}
