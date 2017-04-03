//
//  ViewController.swift
//  ExampleApp
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descTextField: UITextField!
    
    var subscription: RapidSubscription?
    
    var apps: [AppObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func addApp(_ sender: Any) {
        let value = [
            "name": nameTextField.text ?? "Name",
            "desc": descTextField.text ?? "Description"
        ]
        
        Rapid.collection(named: "iosapps").newDocument().mutate(value: value) { (error, _) in
            if let error = error {
                print("App creation error \(error)")
            }
            else {
                print("App created")
            }
        }
        
        nameTextField.text = nil
        descTextField.text = nil
    }
    
    @IBAction func subscribe(_ sender: Any) {
        subscription = Rapid.collection(named: "iosapps").subscribe { (error, documents, insert, update, delete) in
            if let error = error as? RapidError {
                switch error {
                case .permissionDenied(let message):
                    print("Permission denied: \(String(describing: message))")
                    
                default:
                    print("Other error")
                }
            }
            else {
                print("\(insert) - \(update) - \(delete)")
                self.apps = documents.flatMap({ AppObject(document: $0) })
                self.tableView.reloadData()
            }
        }
    }

    @IBAction func unsubscribe(_ sender: Any) {
        subscription?.unsubscribe()
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppCell", for: indexPath) as! AppTableViewCell
        
        cell.configure(withApp: apps[indexPath.row])
        
        return cell
    }
}

