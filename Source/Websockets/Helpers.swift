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
        return (URL(string: "ws://13.64.77.202:8080")!, "")
    }
}
