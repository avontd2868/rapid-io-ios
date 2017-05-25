//
//  Helpers.swift
//  RapiDO
//
//  Created by Jan on 25/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class Validator {
    
    class func isValid(collectionName name: String) -> Bool {
        var components = name.components(separatedBy: "-")
        
        guard components.count > 0 else {
            return false
        }
        
        let first = components.removeFirst()
        
        if first != "rapido" {
            return false
        }
        
        let uuid = NSUUID(uuidString: components.joined(separator: "-"))
        
        return uuid != nil
    }
}
