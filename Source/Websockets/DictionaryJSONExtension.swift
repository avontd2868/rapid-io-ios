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
