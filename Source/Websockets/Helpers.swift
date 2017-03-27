//
//  Helpers.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

func runAfter(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

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
