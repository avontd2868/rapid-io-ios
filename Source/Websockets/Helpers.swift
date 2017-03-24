//
//  Helpers.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class Generator {
    
    class var uniqueID: String {
        return NSUUID().uuidString
    }
}

class Decoder {
    
    class func decode(apiKey: String) -> (hostURL: URL, appSecret: String)? {
        if let url = URL(string: apiKey) {
            return (url, "")
        }
        else {
            return nil
        }
    }
}
