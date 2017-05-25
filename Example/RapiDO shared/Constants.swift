//
//  Constants.swift
//  ExampleApp
//
//  Created by Jan on 05/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

struct Constants {
    
    static var apiKey: String {
        assert(!(Bundle.main.infoDictionary?["RapidApiKey"] as? String ?? "").isEmpty, "Rapid API key not defined")
        
        let apiKey = Bundle.main.infoDictionary?["RapidApiKey"] as! String
        return apiKey
    }
    
    static var collectionName: String {
        assert(!(Bundle.main.infoDictionary?["RapidDemoIdentifier"] as? String ?? "").isEmpty, "Rapid Demo App Identifier not defined")
        
        let clientID = Bundle.main.infoDictionary?["RapidDemoIdentifier"] as! String
        return "rapido-\(clientID)"
    }
}
