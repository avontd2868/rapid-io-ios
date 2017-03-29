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
    
    init?(document: RapidDocumentSnapshot) {
        guard let dict = document.value else {
            return nil
        }
        
        appID = document.id
        name = dict["name"] as? String ?? ""
        description = dict["desc"] as? String ?? ""
    }
}
