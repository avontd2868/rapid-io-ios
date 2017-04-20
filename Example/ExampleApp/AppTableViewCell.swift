//
//  AppCellTableViewCell.swift
//  ExampleApp
//
//  Created by Jan on 29/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class AppTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var proceedsLabel: UILabel!
    @IBOutlet weak var downloadsLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    
    var app: AppObject?
    
    func configure(withApp app: AppObject) {
        self.app = app
        
        nameLabel.text = app.name
        descLabel.text = app.description
        downloadsLabel.text = app.downloads?.description
        proceedsLabel.text = app.proceeds?.description
        categoriesLabel.text = app.categories?.joined(separator: ",")
    }
}
