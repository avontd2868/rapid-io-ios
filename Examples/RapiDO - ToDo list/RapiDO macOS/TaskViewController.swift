//
//  UpsertTaskViewController.swift
//  RapiDO
//
//  Created by Jan on 16/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class TaskViewController: NSViewController {

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var descTextView: NSTextView!
    @IBOutlet weak var homeCheckBox: NSButton!
    @IBOutlet weak var homeBackgroundView: NSView!
    @IBOutlet weak var workCheckBox: NSButton!
    @IBOutlet weak var workBackgroundView: NSView!
    @IBOutlet weak var otherCheckBox: NSButton!
    @IBOutlet weak var otherBackgroundView: NSView!
    @IBOutlet weak var priorityPopUp: NSPopUpButton!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    
    var task: Task?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        setupUI()
        
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
    
    @IBAction func save(_ sender: Any) {
        let title: String
        if !titleTextField.stringValue.isEmpty {
            title = titleTextField.stringValue
        }
        else {
            title = "Task"
        }
        
        let description: Any
        if !descTextView.string.isEmpty {
            description = descTextView.string
        }
        else {
            description = NSNull()
        }
        
        let priority = Priority.allValues[priorityPopUp.index(of: priorityPopUp.selectedItem!)].rawValue
        
        var selectedTags = [Tag]()
        if homeCheckBox.state.rawValue > 0 {
            selectedTags.append(.home)
        }
        if workCheckBox.state.rawValue > 0 {
            selectedTags.append(.work)
        }
        if otherCheckBox.state.rawValue > 0 {
            selectedTags.append(.other)
        }
        let tags = selectedTags.map({$0.rawValue})
        
        // Create task dictionary
        let dict: [AnyHashable: Any] = [
            Task.titleAttributeName: title,
            Task.descriptionAttributeName: description,
            Task.createdAttributeName: self.task?.createdAt.isoString ?? Date().isoString,
            Task.priorityAttributeName: priority,
            Task.tagsAttributeName: tags,
            Task.completedAttributeName: task?.completed ?? false
        ]
        
        if let task = task {
            // Update an existing task
            task.update(withValue: dict)
        }
        else {
            // Create a new task
            Task.create(withValue: dict)
        }
        
        if let window = view.window {
            AppDelegate.closeWindow(window)
        }
    }
    
    @IBAction func delete(_ sender: Any) {
        task?.delete()
        
        if let window = view.window {
            AppDelegate.closeWindow(window)
        }
    }
}

fileprivate extension TaskViewController {
    
    func setupUI() {
        if let task = task {
            titleTextField.stringValue = task.title
            descTextView.string = task.description!
            priorityPopUp.selectItem(at: task.priority.rawValue)
            
            homeCheckBox.state = NSControl.StateValue(rawValue: task.tags.contains(.home) ? 1 : 0)
            workCheckBox.state = NSControl.StateValue(rawValue: task.tags.contains(.work) ? 1 : 0)
            otherCheckBox.state = NSControl.StateValue(rawValue: task.tags.contains(.other) ? 1 : 0)
            
            saveButton.title = "Save"
            deleteButton.isHidden = false
        }
        else {
            saveButton.title = "Create"
            deleteButton.isHidden = true
        }
    }
}
