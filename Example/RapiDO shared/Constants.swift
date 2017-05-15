//
//  Constants.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

struct Constants {
    
    static var collectionName: String {
        let clientID = Bundle.main.infoDictionary?["ClientIdentifier"] as! String
        return "demoapp-\(clientID)"
    }
}
