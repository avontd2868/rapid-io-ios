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
        downloadsTextField.text = app.downloads?.description
        proceedsTextField.text = app.proceeds?.description
        categoriesTextField.text = app.categories?.joined(separator: ",")
    }
    
    @IBAction func done(_ sender: Any) {
        let categories = categoriesTextField.text?.components(separatedBy: ",") ?? []
        
        let app = AppObject(
            id: self.app.appID,
            name: nameTextField.text ?? "Name",
            description: descTextField.text ?? "Description",
            downloads: Int(downloadsTextField.text ?? ""),
            proceeds: Float(proceedsTextField.text ?? ""),
            categories: (categories.count > 1 || !(categories.first?.isEmpty ?? true)) ? categories : nil)
        
        delegate?.updateAppControllerDidFinish(self, withApp: app)
    }

    @IBAction func cancel(_ sender: Any) {
        delegate?.updateAppControllerDidCancel(self)
    }
}
