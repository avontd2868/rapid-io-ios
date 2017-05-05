//
//  TaskCell.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

protocol TaskCellDelegate: class {
    func cellCheckmarkChanged(_ cell: TaskCell, value: Bool)
}

class TaskCell: UITableViewCell {
    
    weak var delegate: TaskCellDelegate?

    @IBOutlet weak var checkBox: BEMCheckBox!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var priorityStackView: UIStackView!
    
    func configure(withTask task: Task, delegate: TaskCellDelegate) {
        self.delegate = delegate
        checkBox.delegate = self
        
        titleLabel.text = task.title
        descriptionLabel.text = task.description
        configurePriorityStackView(forPriority: task.priority)
        configureTagsStackView(withTags: task.tags)
    }

}

fileprivate extension TaskCell {
    
    func configurePriorityStackView(forPriority priority: Priority) {
        for view in priorityStackView.arrangedSubviews {
            priorityStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for _ in 0..<priority.rawValue {
            let dot = UIView()
            dot.backgroundColor = .black
            dot.translatesAutoresizingMaskIntoConstraints = false
            let width = NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 10)
            let height = NSLayoutConstraint(item: dot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 10)
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
            let width = NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
            let height = NSLayoutConstraint(item: dot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
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
