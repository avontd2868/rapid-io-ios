//
//  TagsCellView.swift
//  RapiDO
//
//  Created by Jan on 16/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

class TagsCellView: NSTableCellView {

    @IBOutlet weak var stackView: NSStackView!
    
    func configure(withTags tags: [Tag]) {
        textField?.stringValue = ""
        
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for tag in tags {
            let dot = NSView()
            dot.wantsLayer = true
            dot.layer?.backgroundColor = tag.color.cgColor
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer?.cornerRadius = 7.5
            let width = NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
            let height = NSLayoutConstraint(item: dot, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
            dot.addConstraints([width, height])
            
            stackView.addArrangedSubview(dot)
        }
    }
}
