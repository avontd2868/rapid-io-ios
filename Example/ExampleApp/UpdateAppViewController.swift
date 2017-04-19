//
//  UpdateAppViewController.swift
//  ExampleApp
//
//  Created by Jan on 19/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

protocol UpdateAppViewControllerDelegate: class {
    func updateAppControllerDidCancel(_ controller: UpdateAppViewController)
    func updateAppControllerDidFinish(_ controller: UpdateAppViewController, withApp app: AppObject)
}

class UpdateAppViewController: UIViewController {
    
    var app: AppObject!
    weak var delegate: UpdateAppViewControllerDelegate?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descTextField: UITextField!
    @IBOutlet weak var downloadsTextField: UITextField!
    @IBOutlet weak var proceedsTextField: UITextField!
    @IBOutlet weak var categoriesTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.text = app.name
        descTextField.text = app.description
        downloadsTextField.text = "\(app.downloads)"
        proceedsTextField.text = "\(app.proceeds)"
        categoriesTextField.text = app.categories.joined(separator: ",")
    }
    
    @IBAction func done(_ sender: Any) {
        let app = AppObject(
            id: self.app.appID,
            name: nameTextField.text ?? "Name",
            description: descTextField.text ?? "Description",
            downloads: Int(downloadsTextField.text ?? "") ?? 0,
            proceeds: Float(proceedsTextField.text ?? "") ?? 0,
            categories: categoriesTextField.text?.components(separatedBy: ",") ?? [])
        
        delegate?.updateAppControllerDidFinish(self, withApp: app)
    }

    @IBAction func cancel(_ sender: Any) {
        delegate?.updateAppControllerDidCancel(self)
    }
}
