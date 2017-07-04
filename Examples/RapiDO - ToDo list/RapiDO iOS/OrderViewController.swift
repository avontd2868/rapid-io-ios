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

    @IBOutlet weak var attributePicker: UIPickerView!
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.tintColor = .appRed
        }
    }
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
    
    @IBAction func done(_ sender: Any) {
        // Get an attribute according to which a collection should be ordered
        let keyPath = OrderingAttribute.allValues[attributePicker.selectedRow(inComponent: 0)].attributeName
        // Get an ordering type
        let type: RapidOrdering.Ordering = segmentedControl.selectedSegmentIndex == 0 ? .ascending : .descending
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
        attributePicker.delegate = self
        attributePicker.dataSource = self
        
        if let ordering = ordering {
            let row = OrderingAttribute.allValues.index(where: { $0.attributeName == ordering.keyPath }) ?? 0
            let segment = ordering.ordering == .ascending ? 0 : 1
            
            attributePicker.selectRow(row, inComponent: 0, animated: false)
            segmentedControl.selectedSegmentIndex = segment
        }
        else {
            attributePicker.selectRow(0, inComponent: 0, animated: false)
            segmentedControl.selectedSegmentIndex = 0
        }
    }
}

extension OrderViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return OrderingAttribute.allValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: OrderingAttribute.allValues[row].title, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13), NSAttributedStringKey.foregroundColor: UIColor.appText])
    }
}
