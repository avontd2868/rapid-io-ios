//
//  AppObject.swift
//  ExampleApp
//
//  Created by Jan on 29/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

class AppObject {
    
    let appID: String
    let name: String
    let description: String
    let downloads: Int?
    let proceeds: Float?
    let categories: [String]?
    
    init?(document: RapidDocumentSnapshot) {
        guard let dict = document.value else {
            return nil
        }
        
        appID = document.id
        name = dict["name"] as? String ?? ""
        description = dict["desc"] as? String ?? ""
        downloads = dict["downloads"] as? Int
        proceeds = dict["proceeds"] as? Float
        categories = dict["categories"] as? [String]
    }
    
    init(id: String, name: String, description: String, downloads: Int?, proceeds: Float?, categories: [String]?) {
        self.appID = id
        self.name = name
        self.description = description
        self.downloads = downloads
        self.proceeds = proceeds
        self.categories = categories
    }
}
