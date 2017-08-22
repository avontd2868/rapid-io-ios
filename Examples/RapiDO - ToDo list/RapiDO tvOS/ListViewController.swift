//
//  ViewController.swift
//  RapiDO tvOS
//
//  Created by Jan on 20/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class ListViewController: UIViewController {

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
        tableView.dataSource = self
        tableView.delegate = self
        
        orderButton.target = self
        orderButton.action = #selector(self.showOrderModal(_:))
        
        filterButton.target = self
        filterButton.action = #selector(self.showFilterModal(_:))
    }
    
    func subscribe() {
        // If there is a previous subscription then unsubscribe from it
        subscription?.unsubscribe()
        
        tasks.removeAll()
        tableView.reloadData()
        
        // Get Rapid.io collection reference with a given name
        let collection = Rapid.collection(named: Constants.collectionName)
        
        // If a filter is set, modify the collection reference with it
        if let filter = filter {
            collection.filtered(by: filter)
        }
        
        // Order the collection by a given ordering
        // Subscribe to the collection
        // Store a subscribtion reference to be able to unsubscribe from it
        subscription = collection.order(by: ordering).subscribe { result in
            switch result {
            case .success(let documents):
                self.tasks = documents.flatMap({ Task(withSnapshot: $0) })
                self.tableView.reloadData()
                
            case .failure:
                self.tasks = []
                self.tableView.reloadData()
            }
            
        }
    }
    
    func presentNewTaskController() {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "TaskViewController")
        
        present(controller, animated: true, completion: nil)
    }
    
    func presentOrderModal() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "OrderViewController") as! OrderViewController
        
        controller.delegate = self
        controller.ordering = ordering
        controller.modalTransitionStyle = .crossDissolve
        
        present(controller, animated: true, completion: nil)
    }
    
    func presentFilterModal() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "FilterViewController") as! FilterViewController
        
        controller.delegate = self
        controller.filter = filter
        controller.modalTransitionStyle = .crossDissolve
        
        present(controller, animated: true, completion: nil)
    }
    
    func presentEditTask(_ task: Task) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "TaskViewController") as! UINavigationController
        
        (controller.viewControllers.first as? TaskViewController)?.task = task
        
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
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension ListViewController: TaskCellDelegate {
    
    func cellCheckmarkChanged(_ cell: TaskCell, value: Bool) {
        if let indexPath = tableView.indexPath(for: cell) {
            let task = tasks[indexPath.row]
            task.updateCompleted(value)
        }
    }
    
    func editTask(_ cell: TaskCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let task = tasks[indexPath.row]
            presentEditTask(task)
        }
    }
    
    func deleteTask(_ cell: TaskCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let task = tasks[indexPath.row]
            task.delete()
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
