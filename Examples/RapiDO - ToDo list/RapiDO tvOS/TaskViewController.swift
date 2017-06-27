//
//  AddTaskViewController.swift
//  ExampleApp
//
//  Created by Jan on 08/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class TaskViewController: UITableViewController {

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextField!
    @IBOutlet weak var priorityControl: UISegmentedControl!
    @IBOutlet weak var tagsTableView: TagsTableView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var completedCheckbox: BEMCheckBox!
    
    var task: Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        let priority = Priority.allValues[priorityControl.selectedSegmentIndex].rawValue
        
        let tags = tagsTableView.selectedTags.map({$0.rawValue})
        
        let task: [AnyHashable: Any] = [
            Task.titleAttributeName: title,
            Task.descriptionAttributeName: description,
            Task.createdAttributeName: self.task?.createdAt.isoString ?? Date().isoString,
            Task.priorityAttributeName: priority,
            Task.tagsAttributeName: tags,
            Task.completedAttributeName: completedCheckbox.on
        ]
        
        if let existingTask = self.task {
            existingTask.update(withValue: task)
        }
        else {
            Task.create(withValue: task)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func cancel(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

fileprivate extension TaskViewController {
    
    func setupUI() {
        cancelButton.target = self
        cancelButton.action = #selector(self.cancel(_:))
        
        descriptionTextView.layer.borderColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1).cgColor
        descriptionTextView.layer.borderWidth = 0.5
        
        if let task = task {
            title = "Edit task"
            actionButton.setTitle("Save", for: .normal)
            completedCheckbox.isHidden = false
            
            completedCheckbox.on = task.completed
            titleTextField.text = task.title
            descriptionTextView.text = task.description
            priorityControl.selectedSegmentIndex = task.priority.rawValue
            tagsTableView.selectTags(task.tags)
        }
        else {
            title = "New task"
            actionButton.setTitle("Create", for: .normal)
            completedCheckbox.isHidden = true
            
            completedCheckbox.on = false
            tagsTableView.selectTags([])
        }
    }
}
