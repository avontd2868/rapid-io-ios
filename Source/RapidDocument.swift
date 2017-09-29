//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan on 30/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Compare two docuements
///
/// Compera ids, etags and dictionaries
///
/// - Parameters:
///   - lhs: Left operand
///   - rhs: Right operand
/// - Returns: `true` if operands are equal
public func == (lhs: RapidDocument, rhs: RapidDocument) -> Bool {
    if lhs.id == rhs.id && lhs.collectionName == rhs.collectionName && lhs.etag == rhs.etag {
        if let lValue = lhs.value, let rValue = rhs.value {
            return NSDictionary(dictionary: lValue).isEqual(to: rValue)
        }
        else if lhs.value == nil && rhs.value == nil {
            return true
        }
    }
    
    return false
}

/// Class representing Rapid.io document
public struct RapidDocument: Codable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case collectionName = "col-id"
        case createdAt = "crt-ts"
        case modifiedAt = "mod-ts"
        case etag = "etag"
        case sortValue = "crt"
        case sortKeys = "skey"
        case value = "body"
    }
    
    /// Document ID
    public let id: String
    
    /// Name of a collection to which the document belongs
    public let collectionName: String
    
    /// Document content
    public let value: [String: Any]?
    
    /// Etag identifier
    public let etag: String?
    
    /// Time of document creation
    public let createdAt: Date?
    
    /// Time of document modification
    public let modifiedAt: Date?
    
    /// Document creation sort identifier
    let sortValue: String
    
    /// Value that serves to order documents
    ///
    /// Value is computed by Rapid.io database based on sort descriptors in a subscription
    let sortKeys: [String]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        collectionName = try container.decode(String.self, forKey: .collectionName)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt)
        etag = try container.decodeIfPresent(String.self, forKey: .etag)
        sortKeys = try container.decodeIfPresent([String].self, forKey: .sortKeys) ?? []
        sortValue = try container.decode(String.self, forKey: .sortValue)
        value = try container.decodeIfPresent([String: Any].self, forKey: .value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(collectionName, forKey: .collectionName)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(modifiedAt, forKey: .modifiedAt)
        try container.encodeIfPresent(etag, forKey: .etag)
        try container.encode(sortValue, forKey: .sortValue)
        try container.encode(sortKeys, forKey: .sortKeys)
        try container.encodeIfPresent(value, forKey: .value)
    }

    init?(existingDocJson json: Any?, collectionID: String) {
        guard let dict = json as? [String: Any] else {
            return nil
        }
        
        guard let id = dict[RapidSerialization.Document.DocumentID.name] as? String else {
            return nil
        }
        
        guard let etag = dict[RapidSerialization.Document.Etag.name] as? String else {
            return nil
        }
        
        guard let sortValue = dict[RapidSerialization.Document.SortValue.name] as? String else {
            return nil
        }
        
        guard let createdAt = dict[RapidSerialization.Document.CreatedAt.name] as? TimeInterval else {
            return nil
        }
        
        guard let modifiedAt = dict[RapidSerialization.Document.ModifiedAt.name] as? TimeInterval else {
            return nil
        }
        
        let body = dict[RapidSerialization.Document.Body.name] as? [String: Any]
        let sortKeys = dict[RapidSerialization.Document.SortKeys.name] as? [String]
        
        self.id = id
        self.collectionName = collectionID
        self.value = body
        self.etag = etag
        self.createdAt = Date(timeIntervalSince1970: createdAt)
        self.modifiedAt = Date(timeIntervalSince1970: modifiedAt)
        self.sortKeys = sortKeys ?? []
        self.sortValue = sortValue
    }
    
    init?(removedDocJson json: Any?, collectionID: String) {
        guard let dict = json as? [String: Any] else {
            return nil
        }
        
        guard let id = dict[RapidSerialization.Document.DocumentID.name] as? String else {
            return nil
        }
        
        let body = dict[RapidSerialization.Document.Body.name] as? [String: Any]
        let sortKeys = dict[RapidSerialization.Document.SortKeys.name] as? [String]
        
        self.id = id
        self.collectionName = collectionID
        self.value = body
        self.etag = nil
        self.createdAt = nil
        self.modifiedAt = nil
        self.sortKeys = sortKeys ?? []
        self.sortValue = ""
    }
    
    init(removedDocId id: String, collectionID: String) {
        self.id = id
        self.collectionName = collectionID
        self.value = nil
        self.etag = nil
        self.createdAt = nil
        self.modifiedAt = nil
        self.sortKeys = []
        self.sortValue = ""
    }
    
    init?(document: RapidDocument, newValue: [String: Any]) {
        self.id = document.id
        self.collectionName = document.collectionName
        self.etag = document.etag
        self.createdAt = document.createdAt
        self.modifiedAt = document.modifiedAt
        self.sortKeys = document.sortKeys
        self.sortValue = document.sortValue
        self.value = newValue
    }
    
    public func decode<T>(toType type: T.Type) throws -> T where T : Decodable {
        var enrichedDict = value ?? [:]
        
        enrichedDict["$documentId"] = self.id
        enrichedDict["$collectionName"] = self.collectionName
        enrichedDict["$createdAt"] = self.createdAt?.timeIntervalSince1970
        enrichedDict["$modifiedAt"] = self.modifiedAt?.timeIntervalSince1970
        enrichedDict["$etag"] = self.etag
        
        let data = try (enrichedDict).jsonString().data(using: .utf8)
        return try JSONDecoder().decode(type, from: data ?? Data())
    }
}

extension RapidDocument: RapidCachableObject {
    
    var objectID: String {
        return id
    }
    
    var groupID: String {
        return collectionName
    }
    
}

// MARK: Document opearaion

func == (lhs: RapidDocumentOperation, rhs: RapidDocumentOperation) -> Bool {
    return lhs.document.id == rhs.document.id
}

/// Struct describing what happened with a document since previous subscription update
struct RapidDocumentOperation: Hashable {
    enum Operation {
        case add
        case update
        case remove
        case none
    }
    
    let document: RapidDocument
    let operation: Operation
    
    var hashValue: Int {
        return document.id.hashValue
    }
}

/// Wrapper for a set of `RapidDocumentOperation`
///
/// Set updates are treated specially because operations have different priority
struct RapidDocumentOperationSet: Sequence {
    
    internal var set = Set<RapidDocumentOperation>()
    
    /// Inserts or updates the given element into the set
    ///
    /// - Parameter operation: An element to insert into the set.
    mutating func insertOrUpdate(_ operation: RapidDocumentOperation) {
        if let index = set.index(of: operation) {
            let previousOperation = set[index]
            
            switch (previousOperation.operation, operation.operation) {
            case (.none, .add), (.none, .update), (.none, .remove), (.update, .remove):
                set.update(with: operation)
                
            case (.add, .add), (.add, .update), (.update, .add), (.update, .update), (.remove, .update), (.remove, .remove), (.add, .none), (.update, .none), (.remove, .none), (.none, .none):
                break
                
            case (.add, .remove):
                set.remove(at: index)
                
            case (.remove, .add):
                set.update(with: RapidDocumentOperation(document: operation.document, operation: .update))
            }
        }
        else {
            set.insert(operation)
        }
    }
    
    /// Inserts the given element into the set unconditionally
    ///
    /// - Parameter operation: An element to insert into the set
    mutating func update(_ operation: RapidDocumentOperation) {
        set.update(with: operation)
    }
    
    /// Adds the elements of the given array to the set
    ///
    /// - Parameter other: An array of document operations
    mutating func formUnion(_ other: [RapidDocumentOperation]) {
        set.formUnion(other)
    }
    
    /// Returns an iterator over the elements of this sequence
    ///
    /// - Returns: Iterator
    func makeIterator() -> SetIterator<RapidDocumentOperation> {
        return set.makeIterator()
    }
}

extension Array where Element == RapidDocument {
    
    public func decode<T>(toType type: T.Type) throws -> [T] where T : Decodable {
        return try self.map({ try $0.decode(toType: type) })
    }
    
    public func flatDecode<T>(toType type: T.Type) -> [T] where T : Decodable {
        return self.flatMap({ try? $0.decode(toType: type) })
    }
    
}
