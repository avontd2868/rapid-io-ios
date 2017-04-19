//
//  QueryViewController.swift
//  ExampleApp
//
//  Created by Jan on 19/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

protocol QueryViewControllerDelegate: class {
    func controllerDidCancel(_ controller: QueryViewController)
    func controllerDidFinish(_ controller: QueryViewController, withFilterString filter: String?, key: String?, ordering: RapidOrdering.Ordering)
}

class QueryViewController: UIViewController {
    
    var filterString: String?
    var orderKey: String?
    var ordering = RapidOrdering.Ordering.ascending
    weak var delegate: QueryViewControllerDelegate?

    @IBOutlet weak var filterTextView: UITextView!
    @IBOutlet weak var orderKeyTextField: UITextField!
    @IBOutlet weak var orderingPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        orderingPicker.dataSource = self
        orderingPicker.delegate = self

        filterTextView.text = filterString
        orderKeyTextField.text = orderKey
        orderingPicker.selectRow(ordering == .ascending ? 0 : 1, inComponent: 0, animated: false)
    }

    // MARK: Actions
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.controllerDidCancel(self)
    }
    
    @IBAction func done(_ sender: Any) {
        delegate?.controllerDidFinish(self, withFilterString: filterTextView.text, key: orderKeyTextField.text, ordering: orderingPicker.selectedRow(inComponent: 0) == 0 ? .ascending : .descending)
    }
}

extension QueryViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case 0:
            return "Ascending"
            
        case 1:
            return "Descending"
            
        default:
            return nil
        }
    }
}
