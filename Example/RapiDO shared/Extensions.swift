//
//  Extensions.swift
//  RapiDO
//
//  Created by Jan on 25/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

extension Rapid {
    
    class func collection(withName name: String) -> RapidCollection {
        assert(Validator.isValid(collectionName: name), "App uses different collection name than it is supposed to. Make sure that you pasted correct identifier to Info.plist key `RapidDemoIdentifier` and that you didn't modify default Rapid collection name.")
        
        return collection(named: name)
    }
}

extension Date {
    
    var isoString: String {
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return formatter.string(from: self)
    }
    
    static func dateFromString(_ str: String) -> Date {
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: str) {
            return date
        }
        else {
            return Date()
        }
    }
    
}
