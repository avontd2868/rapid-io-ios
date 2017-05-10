//
//  UITableViewExtension.swift
//  ExampleApp
//
//  Created by Jan on 10/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

extension UITableView {
    
    func animateChanges(previousData: [Task], data: [Task], new: [RapidDocumentSnapshot], updated: [RapidDocumentSnapshot], deleted: [RapidDocumentSnapshot]) {
        let deleteIndexPaths = deleted.map({ task in IndexPath(row: previousData.index(where: { task.id == $0.taskID })!, section: 0) })
        let insertIndexPaths = new.map({ task in IndexPath(row: data.index(where: { task.id == $0.taskID })!, section: 0) })
        
        var moveIndexPaths = [(from: IndexPath, to: IndexPath)]()
        var reloadIndexPaths = [IndexPath]()
        for document in updated {
            let prev = previousData.index(where: { document.id == $0.taskID })!
            let index = data.index(where: { document.id == $0.taskID })!
            let insertsBefore = insertIndexPaths.filter({ $0.row <= index }).count
            let deletesBefore = deleteIndexPaths.filter({ $0.row < prev}).count
            
            if prev + insertsBefore - deletesBefore != index {
                moveIndexPaths.append((IndexPath(row: prev, section: 0), IndexPath(row: index, section: 0)))
            }
            else {
                reloadIndexPaths.append(IndexPath(row: index, section: 0))
            }
        }
        
        self.beginUpdates()
        self.deleteRows(at: deleteIndexPaths, with: .automatic)
        self.insertRows(at: insertIndexPaths, with: .automatic)
        self.reloadRows(at: reloadIndexPaths, with: .automatic)
        
        for (from, to) in moveIndexPaths {
            self.moveRow(at: from, to: to)
        }
        
        self.endUpdates()
        
        self.reloadRows(at: moveIndexPaths.map({ $0.to }), with: .none)
    }
}
