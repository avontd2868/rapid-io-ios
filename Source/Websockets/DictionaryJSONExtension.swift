//
//  DictionaryJSONExtension.swift
//  Rapid
//
//  Created by Jan on 23/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func jsonString() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self, options: [])
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension String {
    
    func json() throws -> [AnyHashable: Any]? {
        if let data = self.data(using: .utf8) {
            return try data.json()
        }
        else {
            return nil
        }
    }
}

extension Data {
    
    func json() throws -> [AnyHashable: Any]? {
        let object = try JSONSerialization.jsonObject(with: self, options: [])
        return object as? [AnyHashable: Any]
    }
}
