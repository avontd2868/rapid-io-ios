//
//  TaskCell.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import UIKit

protocol TaskCellDelegate: class {
    func cellCheckmarkChanged(_ cell: TaskCell, value: Bool)
}

class TaskCell: UITableViewCell {
    
    weak var delegate: TaskCellDelegate?

    @IBOutlet weak var checkBox: BEMCheckBox! {
        didSet {
            checkBox.tintColor = .appSeparator
            checkBox.onTintColor = .appRed
            checkBox.onCheckColor = .appRed
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .appText
            titleLabel.font = UIFont.systemFont(ofSize: 16)
        }
    }
    @IBOutlet var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.textColor = .appText
            descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        }
    }
    @IBOutlet weak var labelsStackView: UIStackView!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var priorityStackView: UIStackView!
    
    func configure(withTask task: Task, delegate: TaskCellDelegate) {
        self.delegate = delegate
        checkBox.delegate = self
        
        titleLabel.text = task.title
        descriptionLabel.text = task.description
        checkBox.on = task.completed
        
        configureLabelsStackView(forTask: task)
        configurePriorityStackView(forPriority: task.priority)
        configureTagsStackView(withTags: task.tags)
    }

}

fileprivate extension TaskCell {
    
    func configureLabelsStackView(forTask task: Task) {
        if task.description == nil && labelsStackView.arrangedSubviews.contains(descriptionLabel) {
            labelsStackView.removeArrangedSubview(descriptionLabel)
            descriptionLabel.removeFromSuperview()
        }
        else if task.description != nil && !labelsStackView.arrangedSubviews.contains(descriptionLabel) {
            labelsStackView.addArrangedSubview(descriptionLabel)
        }
    }
    
    func configurePriorityStackView(forPriority priority: Priority) {
        for view in priorityStackView.arrangedSubviews {
            priorityStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for _ in 0...priority.rawValue {
            let dot = UIView()
            dot.backgroundColor = .black
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 4
            let width = NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 8)
            let height = NSLayoutConstraint(item: dot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 8)
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
            let rect = UIView()
            rect.backgroundColor = tag.color
            rect.translatesAutoresizingMaskIntoConstraints = false
            let width = NSLayoutConstraint(item: rect, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 4)
            let top = NSLayoutConstraint(item: rect, attribute: .top, relatedBy: .equal, toItem: tagsStackView, attribute: .top, multiplier: 1, constant: 0)
            let bottom = NSLayoutConstraint(item: rect, attribute: .bottom, relatedBy: .equal, toItem: tagsStackView, attribute: .bottom, multiplier: 1, constant: 0)
            rect.addConstraints([width])
            
            tagsStackView.addArrangedSubview(rect)
            tagsStackView.addConstraints([top, bottom])
        }
    }
}

extension TaskCell: BEMCheckBoxDelegate {
    
    func animationDidStop(for checkBox: BEMCheckBox) {
        delegate?.cellCheckmarkChanged(self, value: checkBox.on)
    }
}
