//
//  DictionaryJSONExtension.swift
//  Rapid
//
//  Created by Jan Schwarz on 23/03/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

extension Dictionary {
    
    /// Create JSON string from `Self`
    ///
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` and `RapidError.invalidData` errors
    func jsonString() throws -> String {
        guard JSONSerialization.isValidJSONObject(self) else {
            throw RapidError.invalidData(reason: .serializationFailure(message: "Invalid JSON object"))
        }
        
        let data = try JSONSerialization.data(withJSONObject: self, options: [])
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension String {
    
    /// Create JSON dictionary from `Self`
    ///
    /// - Returns: JSON dictionary
    /// - Throws: `JSONSerialization` errors
    func json() throws -> [String: Any]? {
        return try self.data(using: .utf8)?.json()
    }
}

extension Data {
    
    /// Create JSON dictionary from `Self`
    ///
    /// - Returns: JSON dictionary
    /// - Throws: `JSONSerialization` errors
    func json() throws -> [String: Any]? {
        let object = try JSONSerialization.jsonObject(with: self, options: [])
        return object as? [String: Any]
    }
}
