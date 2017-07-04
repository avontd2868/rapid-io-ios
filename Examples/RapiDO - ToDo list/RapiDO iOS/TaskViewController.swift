//
//  AddTaskViewController.swift
//  ExampleApp
//
//  Created by Jan on 08/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class TaskViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var titleTextView: TitleTextView!
    @IBOutlet weak var descriptionTextView: DescriptionTextView!
    @IBOutlet weak var tagsTableView: TagsTableView!
    @IBOutlet weak var priorityView: PriorityView!
    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            actionButton.clipsToBounds = true
            actionButton.backgroundColor = .appRed
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            actionButton.layer.cornerRadius = 4
        }
    }
    @IBOutlet weak var completedCheckbox: BEMCheckBox! {
        didSet {
            completedCheckbox.tintColor = .appSeparator
            completedCheckbox.onTintColor = .appRed
            completedCheckbox.onCheckColor = .appRed
        }
    }
    
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
        if let text = titleTextView.text, !text.isEmpty {
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
        
        let priority = priorityView.priority.rawValue
        
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
        priorityView.collapse()
        view.endEditing(true)
    }
}

fileprivate extension TaskViewController {
    
    func setupUI() {
        cancelButton.target = self
        cancelButton.action = #selector(self.cancel(_:))
        
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
            titleTextView.text = task.title
            descriptionTextView.text = task.description
            priorityView.setPriority(task.priority)
            tagsTableView.selectTags(task.tags)
        }
        else {
            title = "New task"
            actionButton.setTitle("Create", for: .normal)
            titleTextFieldTop.constant = 20
            completedCheckbox.isHidden = true
            
            completedCheckbox.on = false
            titleTextView.text = ""
            descriptionTextView.text = ""
            priorityView.setPriority(Priority.low)
            tagsTableView.selectTags([])
        }
    }
}

// MARK: - Adjust to keyboard
extension TaskViewController: AdjustsToKeyboard {
    
    func animateWithKeyboard(height: CGFloat) {
        bottomMarginConstraint.constant = height
    }
}

class PriorityView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .appPlaceholderText
            titleLabel.font = UIFont.systemFont(ofSize: 12)
            titleLabel.text = "PRIORITY"
        }
    }
    @IBOutlet weak var valueLabel: UILabel! {
        didSet {
            valueLabel.textColor = .appText
            valueLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    @IBOutlet weak var priorityPicker: UIPickerView! {
        didSet {
            priorityPicker.delegate = self
            priorityPicker.dataSource = self
            priorityPicker.alpha = 0
            priorityPicker.isUserInteractionEnabled = false
        }
    }
    @IBOutlet weak var heightConstraint: NSLayoutConstraint! {
        didSet {
            heightConstraint.constant = 60
        }
    }
    
    fileprivate(set) var priority: Priority = .low
    fileprivate var selected: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    func setPriority(_ priority: Priority) {
        self.priority = priority
        
        priorityPicker.selectRow(priority.rawValue, inComponent: 0, animated: false)
        valueLabel.text = priority.title
    }
    
    fileprivate func setupUI() {
        clipsToBounds = true
        isUserInteractionEnabled = true
        
        layer.borderColor = UIColor.appSeparator.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
    
    func collapse() {
        selected = false
        
        animateChange()
    }
    
    func didTap(_ sender: Any) {
        selected = !selected
        
        animateChange()
    }
    
    func animateChange() {
        isUserInteractionEnabled = false
        superview?.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.heightConstraint.constant = self.selected ? 120 : 60
            self.valueLabel.alpha = self.selected ? 0 : 1
            self.priorityPicker.alpha = self.selected ? 1 : 0
            self.superview?.layoutIfNeeded()
        }) { _ in
            self.isUserInteractionEnabled = true
            self.priorityPicker.isUserInteractionEnabled = self.selected
        }
    }
    
    // MARK: Picker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Priority.allValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Priority.allValues[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        priority = Priority.allValues[row]
        valueLabel.text = priority.title
    }
}

class TextView: UIView, UITextViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .appPlaceholderText
            titleLabel.font = UIFont.systemFont(ofSize: 12)
        }
    }
    @IBOutlet private weak var textView: UITextView! {
        didSet {
            textView.textColor = .appText
            textView.font = UIFont.systemFont(ofSize: 15)
            textView.tintColor = .appRed
            textView.isScrollEnabled = false
            textView.delegate = self
        }
    }
    @IBOutlet weak var heightConstraint: NSLayoutConstraint! {
        didSet {
            heightConstraint.constant = 51
        }
    }
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    
    var text: String! {
        get {
            return textView.text
        }
        
        set {
            textView.text = newValue
            updateHeight(collapse: !textView.isFirstResponder)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    func updateHeight(collapse: Bool) {
        superview?.layoutIfNeeded()
        
        let height: CGFloat
        if collapse && textView.text?.isEmpty ?? true {
            height = 50
        }
        else {
            let textViewSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            height = textViewSize.height + 30
        }
        
        guard height != frame.height else {
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.heightConstraint.constant = height
            self.titleTopConstraint.constant = height <= 50 ? 18 : 9
            self.superview?.layoutIfNeeded()
        })
    }
    
    fileprivate func setupUI() {
        clipsToBounds = true
        isUserInteractionEnabled = true
        
        layer.borderColor = UIColor.appSeparator.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
    
    func didTap(_ sender: Any) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
        else {
            textView.becomeFirstResponder()
        }
    }
    
    // MARK: Text view delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            updateHeight(collapse: false)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            updateHeight(collapse: true)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateHeight(collapse: false)
    }
}

class TitleTextView: TextView {
    
    override weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = "TITLE"
        }
    }

}

class DescriptionTextView: TextView {
    
    override weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = "DESCRIPTION"
        }
    }
    
}
