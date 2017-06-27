//
//  AddTaskViewController.swift
//  ExampleApp
//
//  Created by Jan on 08/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class UpsertTaskViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var priorityPicker: UIPickerView!
    @IBOutlet weak var tagsTableView: TagsTableView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var completedCheckbox: BEMCheckBox!
    
    @IBOutlet weak var titleTextFieldTop: NSLayoutConstraint!
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint!
    
    var task: Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        registerForKeyboardFrameChangeNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Actions
    
    @IBAction func saveTask(_ sender: Any) {
        let title: String
        if let text = titleTextField.text, !text.isEmpty {
            title = text
        }
        else {
            title = "Task"
        }
        
        let description: Any
        if let text = descriptionTextView.text, !text.isEmpty {
            description = text
        }
        else {
            description = NSNull()
        }
        
        let priority = Priority.allValues[priorityPicker.selectedRow(inComponent: 0)].rawValue
        
        let tags = tagsTableView.selectedTags.map({$0.rawValue})
        
        // Create task dictionary
        let task: [AnyHashable: Any] = [
            Task.titleAttributeName: title,
            Task.descriptionAttributeName: description,
            Task.createdAttributeName: self.task?.createdAt.isoString ?? Date().isoString,
            Task.priorityAttributeName: priority,
            Task.tagsAttributeName: tags,
            Task.completedAttributeName: completedCheckbox.on
        ]
        
        if let existingTask = self.task {
            // Update an existing task
            existingTask.update(withValue: task)
        }
        else {
            // Create a new task
            Task.create(withValue: task)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func cancel(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    func hideKeyboard(_ sender: AnyObject) {
        view.endEditing(true)
    }
}

fileprivate extension UpsertTaskViewController {
    
    func setupUI() {
        cancelButton.target = self
        cancelButton.action = #selector(self.cancel(_:))
        
        priorityPicker.delegate = self
        priorityPicker.dataSource = self
        
        descriptionTextView.layer.borderColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1).cgColor
        descriptionTextView.layer.borderWidth = 0.5
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard(_:)))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)

        if let task = task {
            title = "Edit task"
            actionButton.setTitle("Save", for: .normal)
            titleTextFieldTop.constant = 102
            completedCheckbox.isHidden = false
            
            completedCheckbox.on = task.completed
            titleTextField.text = task.title
            descriptionTextView.text = task.description
            priorityPicker.selectRow(task.priority.rawValue, inComponent: 0, animated: false)
            tagsTableView.selectTags(task.tags)
        }
        else {
            title = "New task"
            actionButton.setTitle("Create", for: .normal)
            titleTextFieldTop.constant = 20
            completedCheckbox.isHidden = true
            
            completedCheckbox.on = false
            tagsTableView.selectTags([])
        }
    }
}

extension UpsertTaskViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Priority.allValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Priority.allValues[row].title
    }
}

// MARK: - Adjust to keyboard
extension UpsertTaskViewController: AdjustsToKeyboard {
    
    func animateWithKeyboard(height: CGFloat) {
        bottomMarginConstraint.constant = height
    }
}

fileprivate var registeredForObject: UIView?

@objc protocol AdjustsToKeyboard: class {
    func animateWithKeyboard(height: CGFloat)
    @objc optional func completeKeyboardAnimation(height: CGFloat)
}

extension UIViewController {
    
    func registerForKeyboardFrameChangeNotifications(object: UIView? = nil) {
        if registeredForObject != nil {
            registeredForObject = object
            return
        }
        
        registeredForObject = object
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func unregisterKeyboardFrameChangeNotifications(object: UIView? = nil) {
        if registeredForObject == nil || registeredForObject == object {
            NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
            
            registeredForObject = nil
        }
    }
    
    @objc fileprivate func keyboardWillChangeFrame(_ notification: NSNotification) {
        
        if let delegate = self as? AdjustsToKeyboard,
            let userInfo = notification.userInfo,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let endFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let options = UIViewAnimationOptions(rawValue: UInt(curve << 16))
            let height = UIScreen.main.bounds.height - endFrame.origin.y
            
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: { () -> Void in
                delegate.animateWithKeyboard(height: height)
                self.view.layoutIfNeeded()
            }, completion: { (_) -> Void in
                delegate.completeKeyboardAnimation?(height: height)
            })
        }
    }
    
}
