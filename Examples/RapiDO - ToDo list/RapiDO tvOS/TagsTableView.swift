//
//  TagsTableViewController.swift
//  ExampleApp
//
//  Created by Jan on 08/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

extension UIImage {
    
    class func imageWithColor(_ color: UIColor, size: CGSize = CGSize(width:1, height: 1)) -> UIImage {
        
        let rect = CGRect(x: 0.0, y:  0.0, width:  size.width, height:  size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
        
    }

}

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let tag = Tag.allValues[indexPath.row]
        
        cell.selectionStyle = .none
        cell.textLabel?.text = tag.title
        cell.imageView?.image = UIImage.imageWithColor(tag.color, size: CGSize(width: 15, height: 15))
        cell.accessoryType = selectedRows.contains(indexPath.row) ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleCell(atIndexPath: indexPath)
    }

}

fileprivate extension TagsTableView {
    
    func setupUI() {
        register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        delegate = self
        dataSource = self
        
        isScrollEnabled = false
        separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
    
    func toggleCell(atIndexPath indexPath: IndexPath) {
        guard let cell = cellForRow(at: indexPath) else {
            return
        }
        
        setCellSelected(cell.accessoryType == .none, atIndexPath: indexPath)
    }
    
    func setCellSelected(_ selected: Bool, atIndexPath indexPath: IndexPath) {
        if selected {
            selectedRows.insert(indexPath.row)
        }
        else {
            selectedRows.remove(indexPath.row)
        }
        
        if let cell = cellForRow(at: indexPath) {
            cell.accessoryType = selected ? .checkmark : .none
        }
    }

}
