//
//  TagsTableViewController.swift
//  ExampleApp
//
//  Created by Jan on 08/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class TagsTableView: UITableView {
    
    fileprivate var selectedRows = Set<Int>()

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    var selectedTags: [Tag] {
        var rows = [Tag]()
        
        for (row, tag) in Tag.allValues.enumerated() {
            if selectedRows.contains(row) {
                
                rows.append(tag)
            }
        }
        
        return rows
    }
    
    func selectTags(_ tags: [Tag]) {
        for (row, tag) in Tag.allValues.enumerated() {
            setCellSelected(tags.contains(tag), atIndexPath: IndexPath(row: row, section: 0))
        }
    }
    
    func selectAll() {
        for row in 0..<Tag.allValues.count {
            setCellSelected(true, atIndexPath: IndexPath(row: row, section: 0))
        }
    }
}

extension TagsTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Tag.allValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TagsTableViewCell
        
        let tag = Tag.allValues[indexPath.row]
        cell.configure(withTag: tag, selected: selectedRows.contains(indexPath.row))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleCell(atIndexPath: indexPath)
    }

}

fileprivate extension TagsTableView {
    
    func setupUI() {
        register(TagsTableViewCell.self, forCellReuseIdentifier: "Cell")
        delegate = self
        dataSource = self
        separatorColor = .appSeparator
        rowHeight = 60
        
        isScrollEnabled = false
        separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func toggleCell(atIndexPath indexPath: IndexPath) {
        guard let cell = cellForRow(at: indexPath) as? TagsTableViewCell else {
            return
        }
        
        setCellSelected(!cell.checkBox.on, atIndexPath: indexPath)
    }
    
    func setCellSelected(_ selected: Bool, atIndexPath indexPath: IndexPath) {
        if selected {
            selectedRows.insert(indexPath.row)
        }
        else {
            selectedRows.remove(indexPath.row)
        }
        
        if let cell = cellForRow(at: indexPath) as? TagsTableViewCell {
            cell.checkBoxSelected(selected)
        }
    }

}

class TagsTableViewCell: UITableViewCell {
    
    var checkBox: BEMCheckBox! {
        didSet {
             checkBox.isUserInteractionEnabled = false
        }
    }
    var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .appText
            titleLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    func configure(withTag tag: Tag, selected: Bool) {
        titleLabel.text = tag.title
        
        checkBox.setOn(selected, animated: false)
        checkBox.tintColor = tag.color.withAlphaComponent(0.5)
        checkBox.onFillColor = tag.color
        checkBox.onTintColor = tag.color
        checkBox.onCheckColor = .white
    }
    
    func checkBoxSelected(_ selected: Bool) {
        checkBox.setOn(selected, animated: true)
    }
    
    fileprivate func setupUI() {
        selectionStyle = .none
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        checkBox = BEMCheckBox()
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkBox)
        
        let titleLeading = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 20)
        let titleTrailing = NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: checkBox, attribute: .left, multiplier: 1, constant: 10)
        let titleCenter = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        
        let checkBoxTrailing = NSLayoutConstraint(item: contentView, attribute: .right, relatedBy: .equal, toItem: checkBox, attribute: .right, multiplier: 1, constant: 20)
        let checkBoxCenter = NSLayoutConstraint(item: checkBox, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        let checkBoxWidth = NSLayoutConstraint(item: checkBox, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        let checkBoxHeight = NSLayoutConstraint(item: checkBox, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        
        contentView.addConstraints([titleLeading, titleTrailing, titleCenter, checkBoxWidth, checkBoxHeight, checkBoxCenter, checkBoxTrailing])
    }
}
