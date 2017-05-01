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
    @IBOutlet weak var downloadsTextField: UITextField!
    @IBOutlet weak var proceedsTextField: UITextField!
    @IBOutlet weak var categoriesTextField: UITextField!
    
    var filterString: String?
    var orderKey: String?
    var ordering = RapidOrdering.Ordering.ascending
    
    var subscription: RapidSubscription?
    
    var apps: [AppObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func addApp(_ sender: Any) {
        let value: [AnyHashable: Any] = [
            "name": nameTextField.text ?? "Name",
            "desc": descTextField.text ?? "Description",
            "downloads": Int(downloadsTextField.text ?? "") ?? 0,
            "proceeds": Float(proceedsTextField.text ?? "") ?? 0,
            "categories": categoriesTextField.text?.components(separatedBy: ",") ?? []
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
        proceedsTextField.text = nil
        downloadsTextField.text = nil
        categoriesTextField.text = nil
    }
    
    @IBAction func subscribe(_ sender: Any) {
        updateSubscription()
    }

    @IBAction func unsubscribe(_ sender: Any) {
        unsubscribe()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? QueryViewController {
            controller.delegate = self
            controller.filterString = self.filterString
            controller.orderKey = self.orderKey
            controller.ordering = self.ordering
        }
    }
}

fileprivate extension ViewController {
    
    func subscribe() {
        let collection = Rapid.collection(named: "iosapps")
        
        if let filter = filter(fromString: filterString) {
            collection.filtered(by: filter)
        }
        
        if let ordering = ordering(forKey: orderKey, type: ordering) {
            collection.ordered(by: ordering)
        }
        
        subscription = collection.subscribe { (error, documents, insert, update, delete) in
            if let error = error as? RapidError {
                switch error {
                case .permissionDenied(let message):
                    print("Permission denied: \(String(describing: message))")
                    
                default:
                    print("Other error")
                }
            }
            else {
                print("\(insert.map({ $0.id })) - \(update.map({ $0.id })) - \(delete.map({ $0.id }))")
                self.apps = documents.flatMap({ AppObject(document: $0) })
                self.tableView.reloadData()
            }
        }
    }
    
    func unsubscribe() {
        subscription?.unsubscribe()
    }
    
    func updateSubscription() {
        unsubscribe()
        subscribe()
    }
    
    func filter(fromString filterString: String?) -> RapidFilter? {
        if let optionalDict = try? filterString?.json(), let json = optionalDict {
            return parseFilterJSON(json)
        }
        else {
            return nil
        }
    }
    
    func parseFilterJSON(_ json: [AnyHashable: Any]) -> RapidFilter? {
        if let andArray = json["and"] as? [[AnyHashable: Any]] {
            let filterArray = andArray.flatMap({ parseFilterJSON($0) })
            if filterArray.count > 0 {
                return RapidFilter.and(filterArray)
            }
            else {
                return nil
            }
            
        }
        else if let orArray = json["or"] as? [[AnyHashable: Any]] {
            let filterArray = orArray.flatMap({ parseFilterJSON($0) })
            if filterArray.count > 0 {
                return RapidFilter.or(filterArray)
            }
            else {
                return nil
            }
        }
        else if let not = json["not"] as? [AnyHashable: Any] {
            if let filter = parseFilterJSON(not) {
                return RapidFilter.not(filter)
            }
            else {
                return nil
            }
        }
        else if json.keys.count == 1, let key = json.keys.first as? String {
            if let relationObject = json[key] as? [AnyHashable: Any] {
                if let value = relationObject["gt"], let comparable = castToComparable(value: value) {
                    return RapidFilter.greaterThan(keyPath: key, value: comparable)
                }
                else if let value = relationObject["gte"], let comparable = castToComparable(value: value) {
                    return RapidFilter.greaterThanOrEqual(keyPath: key, value: comparable)
                }
                else if let value = relationObject["lt"], let comparable = castToComparable(value: value) {
                    return RapidFilter.lessThan(keyPath: key, value: comparable)
                }
                else if let value = relationObject["lte"], let comparable = castToComparable(value: value) {
                    return RapidFilter.lessThanOrEqual(keyPath: key, value: comparable)
                }
                else if let value = relationObject["cnt"], let subStr = value as? String {
                    return RapidFilter.contains(keyPath: key, subString: subStr)
                }
                else if let value = relationObject["pref"], let subStr = value as? String {
                    return RapidFilter.startsWith(keyPath: key, subString: subStr)
                }
                else if let value = relationObject["suf"], let subStr = value as? String {
                    return RapidFilter.endsWith(keyPath: key, subString: subStr)
                }
                else if let value = relationObject["arr-cnt"], let comparable = castToComparable(value: value) {
                    return RapidFilter.arrayContains(keyPath: key, value: comparable)
                }
                else {
                    return nil
                }
            }
            else if let value = json[key], let comparable = castToComparable(value: value) {
                return RapidFilter.equal(keyPath: key, value: comparable)
            }
            else if json[key] is NSNull {
                return RapidFilter.isNull(keyPath: key)
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    func castToComparable(value: Any) -> RapidComparable? {
        if let value = value as? String {
            return value
        }
        else if let value = value as? Int {
            return value
        }
        else if let value = value as? Double {
            return value
        }
        else if let value = value as? Bool {
            return value
        }
        else {
            return nil
        }
    }
    
    func ordering(forKey key: String?, type: RapidOrdering.Ordering) -> RapidOrdering? {
        if let key = key {
            return RapidOrdering(keyPath: key, ordering: type)
        }
        else {
            return nil
        }
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let app = apps[indexPath.row]
            
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UpdateAppViewController") as! UpdateAppViewController
        
        controller.delegate = self
        controller.app = apps[indexPath.row]
        
        present(controller, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ViewController: QueryViewControllerDelegate {
    
    func controllerDidCancel(_ controller: QueryViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func controllerDidFinish(_ controller: QueryViewController, withFilterString filter: String?, key: String?, ordering: RapidOrdering.Ordering) {
        self.filterString = (filter?.isEmpty ?? true) ? nil : filter
        self.orderKey = (key?.isEmpty ?? true) ? nil : key
        self.ordering = ordering
        
        updateSubscription()
        
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UpdateAppViewControllerDelegate {
    
    func updateAppControllerDidCancel(_ controller: UpdateAppViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func updateAppControllerDidFinish(_ controller: UpdateAppViewController, withApp app: AppObject) {
        var value: [AnyHashable: Any] = [
            "name": app.name,
            "desc": app.description]
        
        value["downloads"] = app.downloads
        value["proceeds"] = app.proceeds
        value["categories"] = app.categories
        
        Rapid.collection(named: "iosapps").document(withID: app.appID).mutate(value: value, completion: { (error, value) in
            if let error = error {
                print("Mutation error \(error)")
            }
            else {
                print("App mutated \(String(describing: value))")
            }
        })
        
        controller.dismiss(animated: true, completion: nil)
    }
}

extension String {
    
    func json() throws -> [AnyHashable: Any]? {
        return try self.data(using: .utf8)?.json()
    }
}

extension Data {
    
    func json() throws -> [AnyHashable: Any]? {
        let object = try JSONSerialization.jsonObject(with: self, options: [])
        return object as? [AnyHashable: Any]
    }
}
