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
func runAfter(_ delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main, closure: @escaping () -> Void) {
    queue.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

class Generator {
    
    /// Unique ID which can serve as a document or collection ID
    class var uniqueID: String {
        let shortID = base64(fromGuid: NSUUID())
        return shortID
    }
    
    /// Array of 64 characters for GUID representation
    static let byteCharArray = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-".characters)
    
    /// Get string representation of GUID
    ///
    /// Standard GUID string representation uses only hexadecimal characters (0123456789ABCDEF).
    /// This method uses 64 characters so the 128-bit GUID can be encoded to 22 characters in comparison with 32 characters of standard GUID representation.
    ///
    /// - Parameter guid: `NSUUID` instance
    /// - Returns: GUID string representation
    class func base64(fromGuid guid: NSUUID) -> String {
        // Get binary representation of GUID (it has 16 bytes)
        var bytes = [UInt8](repeating: 0, count: 16)
        guid.getBytes(&bytes)
        let data = Data(bytes: bytes)
        
        var numberOfBitsCarried: UInt8 = 0
        var carry: UInt8 = 0
        var resultString = ""
        
        for byte in data.enumerated() {
            numberOfBitsCarried += 2
            
            // Get 64-based number
            // Take first `8 - numberOfBitsCarried` bits from the byte and prepend it with bits carried from last iteration
            let shifted = (byte.element >> numberOfBitsCarried) + (carry << (8 - numberOfBitsCarried))
            
            // Append character to string
            resultString += String(byteCharArray[Int(shifted)])
            
            // Carry those bits which were not used for the 64-based number computation
            // It is last `numberOfBitsCarried` bits from the byte
            carry = byte.element & (255 >> (8 - numberOfBitsCarried))
            
            // 6 bits are enough to get next 64-based number.
            // So if 6 bits should be carried to a next iteration get 64-based number from it and do not carry anything
            if numberOfBitsCarried == 6 {
                resultString += String(byteCharArray[Int(carry)])
                
                carry = 0
                numberOfBitsCarried = 0
            }
        }
        
        // Deal with last two bits
        if numberOfBitsCarried > 0 {
            let shifted = carry << (6 - numberOfBitsCarried)
            resultString += String(byteCharArray[Int(shifted)])
        }
        
        return resultString
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
