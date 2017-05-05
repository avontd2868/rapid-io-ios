//
//  Task.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

enum Priority: Int {
    case low
    case medium
    case high
}

enum Tag: String {
    case home
    case work
    case other
    
    var color: UIColor {
        switch self {
        case .home:
            return .blue
            
        case .work:
            return .red
            
        case .other:
            return .green
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
    
    init?(withSnapshot snapshot: RapidDocumentSnapshot) {
        guard let dict = snapshot.value,
            let title = dict[Task.titleAttributeName] as? String,
            let timestamp = dict[Task.createdAttributeName] as? TimeInterval,
            let priority = dict[Task.priorityAttributeName] as? Int else {
                
            return nil
        }
        
        let tags = dict[Task.tagsAttributeName] as? [String] ?? []
        
        self.taskID = snapshot.id
        self.title = title
        self.description = dict[Task.descriptionAttributeName] as? String
        self.createdAt = Date(timeIntervalSince1970: timestamp)
        self.completed = dict[Task.completedAttributeName] as? Bool ?? false
        self.priority = Priority(rawValue: priority) ?? .low
        self.tags = tags.flatMap({ Tag(rawValue: $0) })
    }
}

extension Task {
    
    static let titleAttributeName = "title"
    static let descriptionAttributeName = "title"
    static let createdAttributeName = "created"
    static let priorityAttributeName = "priority"
    static let tagsAttributeName = "tags"
    static let completedAttributeName = "done"

}
