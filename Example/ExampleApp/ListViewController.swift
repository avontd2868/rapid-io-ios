//
//  ListViewController.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class ListViewController: UIViewController {
    
    var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var orderButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    fileprivate var tasks: [Task] = []
    
    fileprivate var subscription: RapidSubscription?
    fileprivate var ordering = RapidOrdering(keyPath: Task.createdAttributeName, ordering: .descending)
    fileprivate var filter: RapidFilter?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        subscribe()
    }

    // MARK: Actions
    
    @IBAction func addTask(_ sender: Any) {
        presentNewTaskController()
    }
    
    func showOrderModal(_ sender: Any) {
        presentOrderModal()
    }
    
    func showFilterModal(_ sender: Any) {
        presentFilterModal()
    }
}

fileprivate extension ListViewController {
    
    func setupUI() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.enablesReturnKeyAutomatically = false
        navigationItem.titleView = searchBar
        
        tableView.dataSource = self
        tableView.delegate = self
        
        orderButton.target = self
        orderButton.action = #selector(self.showOrderModal(_:))
        
        filterButton.target = self
        filterButton.action = #selector(self.showFilterModal(_:))
    }
    
    func subscribe() {
        subscription?.unsubscribe()
        
        let collection = Rapid.collection(named: Constants.collectionName)
        
        if let filter = filter {
            if let text = searchBar.text, !text.isEmpty {
                let combinedFilter = RapidFilter.or([
                    RapidFilter.contains(keyPath: Task.titleAttributeName, subString: text),
                    RapidFilter.contains(keyPath: Task.descriptionAttributeName, subString: text)
                    ])
                collection.filtered(by: RapidFilter.and([filter, combinedFilter]))
            }
            else {
                collection.filtered(by: filter)
            }
        }
        else if let text = searchBar.text, !text.isEmpty {
            let combinedFilter = RapidFilter.or([
                RapidFilter.contains(keyPath: Task.titleAttributeName, subString: text),
                RapidFilter.contains(keyPath: Task.descriptionAttributeName, subString: text)
                ])
            collection.filtered(by: combinedFilter)
        }
        
        subscription = collection.order(by: ordering).subscribe(completion: { (error, documents) in
            self.tasks = documents.flatMap({ Task(withSnapshot: $0) })
            self.tableView.reloadData()
        })
    }
    
    func presentNewTaskController() {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "UpsertTaskViewController")
        
        present(controller, animated: true, completion: nil)
    }
    
    func presentOrderModal() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "OrderViewController") as! OrderViewController
        
        controller.delegate = self
        controller.ordering = ordering
        controller.modalPresentationStyle = .custom
        controller.modalTransitionStyle = .crossDissolve
        
        present(controller, animated: true, completion: nil)
    }
    
    func presentFilterModal() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "FilterViewController") as! FilterViewController
        
        controller.delegate = self
        controller.filter = filter
        controller.modalPresentationStyle = .custom
        controller.modalTransitionStyle = .crossDissolve
        
        present(controller, animated: true, completion: nil)
    }
    
    func presentEditTask(_ task: Task) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "UpsertTaskViewController") as! UINavigationController
        
        (controller.viewControllers.first as? UpsertTaskViewController)?.task = task
        
        present(controller, animated: true, completion: nil)
    }
}

// MARK: Table view
extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        
        let task = tasks[indexPath.row]
        cell.configure(withTask: task, delegate: self)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let task = tasks[indexPath.row]
        presentEditTask(task)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = tasks[indexPath.row]
            
            Rapid.collection(named: Constants.collectionName).document(withID: task.taskID).delete()
        }
    }
}

extension ListViewController: TaskCellDelegate {
    
    func cellCheckmarkChanged(_ cell: TaskCell, value: Bool) {
        if let indexPath = tableView.indexPath(for: cell) {
            let task = tasks[indexPath.row]
            
            Rapid.collection(named: Constants.collectionName).document(withID: task.taskID).merge(value: [Task.completedAttributeName: value])
        }
    }
}

// MARK: Search bar delegate
extension ListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        subscribe()
    }
}

// MARK: Ordering delegate
extension ListViewController: OrderViewControllerDelegate {
    
    func orderViewControllerDidCancel(_ controller: OrderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func orderViewControllerDidFinish(_ controller: OrderViewController, withOrdering ordering: RapidOrdering) {
        self.ordering = ordering
        subscribe()
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: Filter delegate
extension ListViewController: FilterViewControllerDelegate {
    
    func filterViewControllerDidCancel(_ controller: FilterViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func filterViewControllerDidFinish(_ controller: FilterViewController, withFilter filter: RapidFilter?) {
        self.filter = filter
        subscribe()
        controller.dismiss(animated: true, completion: nil)
    }
}
