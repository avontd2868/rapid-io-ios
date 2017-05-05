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
            collection.filtered(by: filter)
        }
        
        subscription = collection.order(by: ordering).subscribe(completion: { (error, documents) in
            
        })
    }
    
    func presentNewTaskController() {
        
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
