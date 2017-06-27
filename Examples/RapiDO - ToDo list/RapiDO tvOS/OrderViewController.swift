//
//  OrderViewController.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

protocol OrderViewControllerDelegate: class {
    func orderViewControllerDidCancel(_ controller: OrderViewController)
    func orderViewControllerDidFinish(_ controller: OrderViewController, withOrdering ordering: RapidOrdering)
}

enum OrderingAttribute {
    case priority
    case date
    case title
    case done
    
    static let allValues: [OrderingAttribute] = [.date, .priority, .done, .title]
    
    var attributeName: String {
        switch self {
        case .priority:
            return Task.priorityAttributeName
            
        case .date:
            return Task.createdAttributeName
            
        case .title:
            return Task.titleAttributeName
            
        case .done:
            return Task.completedAttributeName
        }
    }
    
    var title: String {
        switch self {
        case .priority:
            return "Priority"
            
        case .date:
            return "Date Created"
            
        case .title:
            return "Title"
            
        case .done:
            return "Completed"
        }
    }
}

class OrderViewController: UIViewController {
    
    weak var delegate: OrderViewControllerDelegate?
    var ordering: RapidOrdering?

    @IBOutlet weak var attributeControl: UISegmentedControl!
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    // MARK: Actions
    
    @IBAction func done(_ sender: Any) {
        // Get an attribute according to which a collection should be ordered
        let keyPath = OrderingAttribute.allValues[attributeControl.selectedSegmentIndex].attributeName
        // Get an ordering type
        let type: RapidOrdering.Ordering = typeControl.selectedSegmentIndex == 0 ? .ascending : .descending
        // Create Rapid.io ordering instance
        let ordering = RapidOrdering(keyPath: keyPath, ordering: type)
        
        delegate?.orderViewControllerDidFinish(self, withOrdering: ordering)
    }
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.orderViewControllerDidCancel(self)
    }
}

fileprivate extension OrderViewController {
    
    // Setup UI according to a given ordering
    func setupUI() {
        
        if let ordering = ordering {
            let row = OrderingAttribute.allValues.index(where: { $0.attributeName == ordering.keyPath }) ?? 0
            let segment = ordering.ordering == .ascending ? 0 : 1
            
            typeControl.selectedSegmentIndex = segment
            attributeControl.selectedSegmentIndex = row
        }
        else {
            typeControl.selectedSegmentIndex = 0
            attributeControl.selectedSegmentIndex = 0
        }
        
        setupFocusGuide()
    }
    
    func setupFocusGuide() {
        let doneGuide = UIFocusGuide()
        doneGuide.preferredFocusEnvironments = [doneButton]
        view.addLayoutGuide(doneGuide)
        
        view.addConstraint(NSLayoutConstraint(item: doneGuide, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1))
        view.addConstraint(NSLayoutConstraint(item: doneGuide, attribute: .bottom, relatedBy: .equal, toItem: doneButton, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: doneGuide, attribute: .left, relatedBy: .equal, toItem: cancelButton, attribute: .right, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: doneGuide, attribute: .right, relatedBy: .equal, toItem: doneButton, attribute: .left, multiplier: 1, constant: 0))
        
        let segmentGuide = UIFocusGuide()
        segmentGuide.preferredFocusEnvironments = [typeControl]
        view.addLayoutGuide(segmentGuide)
        
        view.addConstraint(NSLayoutConstraint(item: segmentGuide, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1))
        view.addConstraint(NSLayoutConstraint(item: segmentGuide, attribute: .centerY, relatedBy: .equal, toItem: typeControl, attribute: .centerY, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: segmentGuide, attribute: .left, relatedBy: .equal, toItem: cancelButton, attribute: .left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: segmentGuide, attribute: .right, relatedBy: .equal, toItem: doneButton, attribute: .right, multiplier: 1, constant: 0))
    }

}
