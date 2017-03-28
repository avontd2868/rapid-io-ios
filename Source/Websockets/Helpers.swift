//
//  Helpers.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Helper method which runs a block of code on the main thread after specified number of seconds
///
/// - Parameters:
///   - delay: Run a block of code after `delay`
///   - closure: Block of code to be run
func runAfter(_ delay: TimeInterval, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

class Generator {
    
    /// Unique ID which can serve as a document or collection ID
    class var uniqueID: String {
        return NSUUID().uuidString
    }
}

class Decoder {
    
    /// Decode API key
    ///
    /// - Parameter apiKey: API key
    /// - Returns: Tuple of decoded values
    class func decode(apiKey: String) -> (hostURL: URL, appSecret: String)? {
        if let url = URL(string: apiKey) {
            return (url, "")
        }
        else {
            return nil
        }
    }
}
