//
//  CodingExtension.swift
//  Rapid
//
//  Created by Jan on 27/09/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedEncodingContainer where K == JSONCodingKeys {
    
    mutating func encode(json: [String: Any]) throws {
        for (key, value) in json {
            guard let codingKey = JSONCodingKeys(stringValue: key) else {
                continue
            }
            
            if let boolValue = value as? Bool {
                try self.encode(boolValue, forKey: codingKey)
            }
            else if let intValue = value as? Int {
                try self.encode(intValue, forKey: codingKey)
            }
            else if let stringValue = value as? String {
                try self.encode(stringValue, forKey: codingKey)
            }
            else if let doubleValue = value as? Double {
                try self.encode(doubleValue, forKey: codingKey)
            }
            else if let nestedDictionary = value as? [String: Any] {
                try self.encode(nestedDictionary, forKey: codingKey)
            }
            else if let nestedArray = value as? [Any] {
                try self.encode(nestedArray, forKey: codingKey)
            }
            else {
                try self.encodeNil(forKey: codingKey)
            }
        }
    }
    
}

extension KeyedEncodingContainer {
    
    mutating func encode(_ value: [String: Any], forKey key: K) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        try container.encode(json: value)
    }
    
    mutating func encodeIfPresent(_ value: [String: Any]?, forKey key: K) throws {
        if let value = value {
            try encode(value, forKey: key)
        }
    }
    
    mutating func encode(_ value: [Any], forKey key: K) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encodeIfPresent(_ value: [Any]?, forKey key: K) throws {
        if let value = value {
            try encode(value, forKey: key)
        }
    }
}

extension KeyedDecodingContainer {
    
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            }
            else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            }
            else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            }
            else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            }
            else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            }
            else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
            else if try decodeNil(forKey: key) {
                dictionary[key.stringValue] = true
            }
        }
        return dictionary
    }
}

extension UnkeyedEncodingContainer {
    
    mutating func encode(_ value: [String: Any]) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKeys.self)
        try container.encode(json: value)
    }
    
    mutating func encode(_ value: [Any]) throws {
        for subValue in value {
            if let intValue = subValue as? Int {
                try encode(intValue)
            }
            else if let stringValue = subValue as? String {
                try encode(stringValue)
            }
            else if let boolValue = subValue as? Bool {
                try encode(boolValue)
            }
            else if let doubleValue = subValue as? Double {
                try encode(doubleValue)
            }
            else if let nestedDictionary = subValue as? [String: Any] {
                try encode(nestedDictionary)
            }
            else if let nestedArray = subValue as? [Any] {
                var container = self.nestedUnkeyedContainer()
                try container.encode(nestedArray)
            }
        }
    }
    
}

extension UnkeyedDecodingContainer {
    
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            }
            else if let value = try? decode(Double.self) {
                array.append(value)
            }
            else if let value = try? decode(String.self) {
                array.append(value)
            }
            else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            }
            else if var nestedContainer = try? nestedUnkeyedContainer(), let nestedArray = try? nestedContainer.decode([Any].self) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
