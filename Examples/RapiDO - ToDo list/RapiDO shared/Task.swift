//
//  Task.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation
import Rapid
#if os(OSX)
import AppKit
#elseif os(tvOS)
import UIKit
#elseif os(iOS)
import UIKit
#endif

enum Priority: Int {
    case low
    case medium
    case high
    
    static let allValues: [Priority] = [.low, .medium, .high]
    
    var title: String {
        switch self {
        case .low:
            return "Low"
            
        case .medium:
            return "Medium"
            
        case .high:
            return "High"
        }
    }
}

enum Tag: String {
    case home
    case work
    case other
    
    static let allValues: [Tag] = [.home, .work, .other]
    
    #if os(OSX)
    var color: NSColor {
        switch self {
        case .home:
            return NSColor(red: 116/255.0, green: 204/255.0, blue: 244/255.0, alpha: 1)
            
        case .work:
            return NSColor(red: 237/255.0, green: 80/255.0, blue: 114/255.0, alpha: 1)
            
        case .other:
            return NSColor(red: 191/255.0, green: 245/255.0, blue: 171/255.0, alpha: 1)
        }
    }
    #elseif os(iOS)
    var color: UIColor {
        switch self {
        case .home:
            return .appBlue
    
        case .work:
            return .appRed
    
        case .other:
            return .appGreen
        }
    }
    #elseif os(tvOS)
    var color: UIColor {
        switch self {
        case .home:
            return UIColor(red: 116/255.0, green: 204/255.0, blue: 244/255.0, alpha: 1)
            
        case .work:
            return UIColor(red: 237/255.0, green: 80/255.0, blue: 114/255.0, alpha: 1)
            
        case .other:
            return UIColor(red: 191/255.0, green: 245/255.0, blue: 171/255.0, alpha: 1)
        }
    }
    #endif
    
    var title: String {
        switch self {
        case .home:
            return "Home"
            
        case .work:
            return "Work"
            
        case .other:
            return "Other"
        }
    }
}

struct Task {
    let taskID: String
    let title: String
    let description: String?
    let createdAt: Date
    let completed: Bool
    let priority: Priority
    let tags: [Tag]
    
    init?(withSnapshot snapshot: RapidDocument) {
        guard let dict = snapshot.value,
            let title = dict[Task.titleAttributeName] as? String,
            let isoString = dict[Task.createdAttributeName] as? String,
            let priority = dict[Task.priorityAttributeName] as? Int else {
                
            return nil
        }
        
        let tags = dict[Task.tagsAttributeName] as? [String] ?? []
        
        self.taskID = snapshot.id
        self.title = title
        self.description = dict[Task.descriptionAttributeName] as? String
        self.createdAt = Date.dateFromString(isoString)
        self.completed = dict[Task.completedAttributeName] as? Bool ?? false
        self.priority = Priority(rawValue: priority) ?? .low
        self.tags = tags.flatMap({ Tag(rawValue: $0) })
    }
    
    func updateCompleted(_ completed: Bool) {
        // Update just one attribute on an existing task
        // Merge an existing task with a dictionary containing attributes that should be updated
        Rapid.collection(named: Constants.collectionName).document(withID: self.taskID).merge(value: [Task.completedAttributeName: completed])
    }
    
    func update(withValue value: [String: Any]) {
        // Update whole task, overwrite the existing one
        Rapid.collection(named: Constants.collectionName).document(withID: self.taskID).mutate(value: value)
    }
    
    func delete() {
        // Delete a task
        Rapid.collection(named: Constants.collectionName).document(withID: self.taskID).delete()
    }
    
    static func create(withValue value: [String: Any]) {
        // Create a task
        // Get a reference to a new document with a random unique identifier and mutate it with a new value
        Rapid.collection(named: Constants.collectionName).newDocument().mutate(value: value)
    }
}

extension Task {
    
    static let titleAttributeName = "title"
    static let descriptionAttributeName = "description"
    static let createdAttributeName = "createdAt"
    static let priorityAttributeName = "priority"
    static let tagsAttributeName = "tags"
    static let completedAttributeName = "done"

}
