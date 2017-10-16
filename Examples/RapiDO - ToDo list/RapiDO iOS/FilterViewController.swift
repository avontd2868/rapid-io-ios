//
//  FilterViewController.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import UIKit
import Rapid

protocol FilterViewControllerDelegate: class {
    func filterViewControllerDidCancel(_ controller: FilterViewController)
    func filterViewControllerDidFinish(_ controller: FilterViewController, withFilter filter: RapidFilterDescriptor?)
}

class FilterViewController: UIViewController {
    
    weak var delegate: FilterViewControllerDelegate?
    var filter: RapidFilterDescriptor?
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.tintColor = .appRed
        }
    }
    @IBOutlet weak var tagsTableView: TagsTableView!
    @IBOutlet weak var doneButton: UIButton! {
        didSet {
            doneButton.setTitleColor(.white, for: .normal)
            doneButton.backgroundColor = .appRed
            doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        }
    }
    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.setTitleColor(.appRed, for: .normal)
            cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        }
    }
    @IBOutlet weak var separatorView: UIView! {
        didSet {
            separatorView.backgroundColor = .appRed
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    // MARK: Actions
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.filterViewControllerDidCancel(self)
    }
    
    @IBAction func done(_ sender: Any) {
        var operands = [RapidFilterDescriptor]()
        
        // Segmented control selected index equal to 1 means "show all tasks regardless completion state", so no filter is needed
        // Otherwise, create filter for either completed or incompleted tasks
        if segmentedControl.selectedSegmentIndex != 1 {
            let completed = segmentedControl.selectedSegmentIndex == 0
            operands.append(RapidFilter.equal(keyPath: Task.completedAttributeName, value: completed))
        }
        
        // Create filter for selected tags
        let selectedTags = tagsTableView.selectedTags
        if selectedTags.count > 0 {
            var tagFilters = [RapidFilterDescriptor]()
            
            for tag in selectedTags {
                tagFilters.append(RapidFilter.arrayContains(keyPath: Task.tagsAttributeName, value: tag.rawValue))
            }
            
            // Combine single tag filters with logical "OR" operator
            operands.append(RapidFilter.or(tagFilters))
        }
        
        // If there are any filters combine them with logical "AND"
        let filter: RapidFilterDescriptor?
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
    
    /// Setup UI according to filter
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
                    
                    var tags = [Tag]()
                    for case let tagFilter as RapidFilterSimple in tagOrFilter.operands {
                        switch tagFilter.value as? String {
                        case .some(Tag.home.rawValue):
                            tags.append(.home)
                            
                        case .some(Tag.work.rawValue):
                            tags.append(.work)

                        case .some(Tag.other.rawValue):
                            tags.append(.other)
                            
                        default:
                            break
                        }
                    }
                    tagsTableView.selectTags(tags)
                }
            }
            
            if !tagsSet {
                tagsTableView.selectTags([])
            }
            if !completionSet {
                segmentedControl.selectedSegmentIndex = 1
            }
        }
        else {
            segmentedControl.selectedSegmentIndex = 1
            tagsTableView.selectTags([])
        }
    }
}
