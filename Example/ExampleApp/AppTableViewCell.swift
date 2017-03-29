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
    
    var app: AppObject?
    
    @IBAction func mutate(_ sender: Any) {
        if let app = app {
            let value = [
                "name": app.name,
                "desc": app.description + "$"
            ]
            
            Rapid.collection(named: "iosapps").document(withID: app.appID).mutate(value: value, completion: { (error, value) in
                if let error = error {
                    print("Mutation error \(error)")
                }
                else {
                    print("App mutated \(String(describing: value))")
                }
            })
        }
    }
    
    @IBAction func remove(_ sender: Any) {
        if let app = app {
            Rapid.collection(named: "iosapps").document(withID: app.appID).delete(completion: { error in
                if let error = error {
                    print("App wasn't deleted \(error)")
                }
                else {
                    print("App deleted")
                }
            })
        }
    }

    func configure(withApp app: AppObject) {
        self.app = app
        
        nameLabel.text = app.name
        descLabel.text = app.description
    }
}
