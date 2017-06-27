//
//  CheckBoxCellView.swift
//  ExampleMacOSApp
//
//  Created by Jan on 15/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa

protocol CheckBoxCellViewDelegate: class {
    func checkBoxCellChangedValue(_ cellView: CheckBoxCellView, value: Bool)
}

class CheckBoxCellView: NSTableCellView {

    @IBOutlet weak var checkBox: NSButton!
    
    weak var delegate: CheckBoxCellViewDelegate?
    
    @IBAction func valueChanged(_ sender: Any) {
        delegate?.checkBoxCellChangedValue(self, value: checkBox.state > 0)
    }
    
}
