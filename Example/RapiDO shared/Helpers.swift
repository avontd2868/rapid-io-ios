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
        let uuid = NSUUID(uuidString: name)
        
        return uuid != nil
    }
}
