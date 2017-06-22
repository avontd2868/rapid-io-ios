//
//  TaskCell.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

extension BEMCheckBox {
    override open var canBecomeFocused: Bool {
        return true
    }
    
    override open func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self {
            coordinator.addCoordinatedAnimations({ () -> Void in
                self.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2)
                self.layer.shadowColor = UIColor.lightGray.cgColor
                self.layer.shadowOffset = CGSize(width: 3, height: 3)
                self.layer.shadowOpacity = 1
            }, completion: nil)
            
        } else if context.previouslyFocusedView == self {
            coordinator.addCoordinatedAnimations({ () -> Void in
                self.layer.transform = CATransform3DIdentity
                self.layer.shadowColor = nil
                self.layer.shadowOffset = CGSize.zero
                self.layer.shadowOpacity = 0
            }, completion: nil)
        }
    }
}

protocol TaskCellDelegate: class {
    func cellCheckmarkChanged(_ cell: TaskCell, value: Bool)
    func editTask(_ cell: TaskCell)
    func deleteTask(_ cell: TaskCell)
}

class TaskCell: UITableViewCell {
    
    weak var delegate: TaskCellDelegate?

    @IBOutlet weak var checkBox: BEMCheckBox!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var priorityStackView: UIStackView!
    
    func configure(withTask task: Task, delegate: TaskCellDelegate) {
        self.delegate = delegate
        checkBox.delegate = self
        
        titleLabel.text = task.title
        descriptionLabel.text = task.description
        checkBox.on = task.completed
        configurePriorityStackView(forPriority: task.priority)
        configureTagsStackView(withTags: task.tags)
    }

    @IBAction func editTask(_ sender: AnyObject) {
        delegate?.editTask(self)
    }
    
    @IBAction func deleteTask(_ sender: AnyObject) {
        delegate?.deleteTask(self)
    }
}

fileprivate extension TaskCell {
    
    func configurePriorityStackView(forPriority priority: Priority) {
        for view in priorityStackView.arrangedSubviews {
            priorityStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for _ in 0...priority.rawValue {
            let dot = UIView()
            dot.backgroundColor = .black
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 7.5
            let width = NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
            let height = NSLayoutConstraint(item: dot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
            dot.addConstraints([width, height])
            
            priorityStackView.addArrangedSubview(dot)
       }
    }
    
    func configureTagsStackView(withTags tags: [Tag]) {
        for view in tagsStackView.arrangedSubviews {
            tagsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for tag in tags {
            let dot = UIView()
            dot.backgroundColor = tag.color
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 7.5
            let width = NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
            let height = NSLayoutConstraint(item: dot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
            dot.addConstraints([width, height])
            
            tagsStackView.addArrangedSubview(dot)
        }
    }
}

extension TaskCell: BEMCheckBoxDelegate {
    
    func animationDidStop(for checkBox: BEMCheckBox) {
        delegate?.cellCheckmarkChanged(self, value: checkBox.on)
    }
}
