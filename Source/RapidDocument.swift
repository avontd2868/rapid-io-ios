//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan on 30/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

/// Compare two documents
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

/// Class representing Rapid document
open class RapidDocument: NSObject, NSCoding {
    
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
    /// Value is computed by Rapid database based on sort descriptors in a subscription
    let sortKeys: [String]
    
    init?(existingDocJson json: Any?, collectionID: String) {
        guard let dict = json as? [AnyHashable: Any] else {
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
        guard let dict = json as? [AnyHashable: Any] else {
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
    
    /// Returns an object initialized from data in a given unarchiver
    ///
    /// - Parameter aDecoder: An unarchiver object
    required public init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: "id") as? String else {
            return nil
        }
        
        guard let collectionID = aDecoder.decodeObject(forKey: "collectionID") as? String else {
            return nil
        }
        
        guard let sortKeys = aDecoder.decodeObject(forKey: "sortKeys") as? [String] else {
            return nil
        }
        
        guard let sortValue = aDecoder.decodeObject(forKey: "sortValue") as? String else {
            return nil
        }
        
        self.id = id
        self.collectionName = collectionID
        self.sortKeys = sortKeys
        self.sortValue = sortValue
        do {
            self.value = try (aDecoder.decodeObject(forKey: "value") as? String)?.json()
        }
        catch {
            self.value = nil
        }
        
        if let etag = aDecoder.decodeObject(forKey: "etag") as? String {
            self.etag = etag
        }
        else {
            self.etag = nil
        }
        
        if let createdAt = aDecoder.decodeObject(forKey: "createdAt") as? Date {
            self.createdAt = createdAt
        }
        else {
            self.createdAt = nil
        }
        
        if let modifiedAt = aDecoder.decodeObject(forKey: "modifiedAt") as? Date {
            self.modifiedAt = modifiedAt
        }
        else {
            self.modifiedAt = nil
        }
    }
    
    /// Encode the document using a given archiver
    ///
    /// - Parameter aCoder: An archiver object
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(collectionName, forKey: "collectionID")
        aCoder.encode(etag, forKey: "etag")
        aCoder.encode(sortKeys, forKey: "sortKeys")
        aCoder.encode(sortValue, forKey: "sortValue")
        aCoder.encode(createdAt, forKey: "createdAt")
        aCoder.encode(modifiedAt, forKey: "modifiedAt")
        do {
            aCoder.encode(try value?.jsonString(), forKey: "value")
        }
        catch {}
    }
    
    /// Determine whether the document is equal to a given object
    ///
    /// - Parameter object: An object for comparison
    /// - Returns: `true` if the document is equal to the object
    override open func isEqual(_ object: Any?) -> Bool {
        if let document = object as? RapidDocument {
            return self == document
        }
        
        return false
    }
    
    /// Document description
    override open var description: String {
        var dict: [AnyHashable: Any] = [
            "id": id,
            "etag": String(describing: etag),
            "collectionID": collectionName,
            "value": String(describing: value)
        ]
        
        if let created = createdAt {
            dict["createdAt"] = created
        }
        
        if let modified = modifiedAt {
            dict["modifiedAt"] = modified
        }
        
        return dict.description
    }
    
    /// Decode `RapidDocument` into a specified type that conforms to `Decodable`
    ///
    /// JSON that is used for decoding is `RapidDocument` `value`.
    /// This dictionary is, just for sake of decoding, enriched with attributes
    /// that contain document ID, collection name, timestamp of creation, timestamp of modification and etag.
    /// Keys of these attributes are defined by `RapidJSONDecoder.RapidDocumentDecodingKeys`.
    /// When you provide this method with a decoder that is an instance of `RapidJSONDecoder`
    /// then the keys are taken from `rapidDocumentDecodingKeys` property of the decoder.
    /// Otherwise, default keys of `RapidJSONDecoder.RapidDocumentDecodingKeys` are used.
    ///
    /// - Parameters:
    ///   - type: Data type that conforms to `Decodable`
    ///   - decoder: `JSONDecoder` that should be used for decoding. If `nil` a default `JSONDecoder()` is used
    /// - Returns: Decoded instance of the specified type
    /// - Throws: Errors thrown by `JSONDecoder`
    open func decode<T>(toType type: T.Type, decoder: JSONDecoder? = nil) throws -> T where T : Decodable {
        var enrichedDict = value ?? [:]
        
        let keys: RapidJSONDecoder.RapidDocumentDecodingKeys
        if let dec = decoder as? RapidJSONDecoder {
            keys = dec.rapidDocumentDecodingKeys
        }
        else {
            keys = RapidJSONDecoder.RapidDocumentDecodingKeys()
        }
        
        enrichedDict[keys.documentIdKey] = self.id
        enrichedDict[keys.collectionNameKey] = self.collectionName
        enrichedDict[keys.createdAtKey] = self.createdAt?.timeIntervalSince1970
        enrichedDict[keys.modifiedAtKey] = self.modifiedAt?.timeIntervalSince1970
        enrichedDict[keys.etagKey] = self.etag
        
        let dec = decoder ?? JSONDecoder()
        let data = try (enrichedDict).jsonString().data(using: .utf8)
        return try dec.decode(type, from: data ?? Data())
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

extension Array where Element: RapidDocument {
    
    /// Decode an array of `RapidDocument`s into an array of a specified type that conforms to `Decodable`
    ///
    /// This is just a convenience method that calls `decode` method on each instance of `RapidDocument`
    ///
    /// - Parameters:
    ///   - type: Data type that conforms to `Decodable`
    ///   - decoder: `JSONDecoder` that should be used for decoding. If `nil` a default `JSONDecoder()` is used
    /// - Returns: Array of decodeded instances of the specified type
    /// - Throws: Errors thrown by `JSONDecoder`
    public func decode<T>(toType type: T.Type, decoder: JSONDecoder? = nil) throws -> [T] where T : Decodable {
        return try self.map({ try $0.decode(toType: type, decoder: decoder) })
    }
    
    /// Decode an array of `RapidDocument`s into an array of a specified type that conforms to `Decodable`
    /// Instances of `RapidDocument` that cannot be decoded are not present in the returned array
    ///
    /// This is just a convenience method that calls `decode` method on each instance of `RapidDocument`
    ///
    /// - Parameters:
    ///   - type: Data type that conforms to `Decodable`
    ///   - decoder: `JSONDecoder` that should be used for decoding. If `nil` a default `JSONDecoder()` is used
    /// - Returns: Array of decodeded instances of the specified type
    public func flatDecode<T>(toType type: T.Type, decoder: JSONDecoder? = nil) -> [T] where T : Decodable {
        return self.flatMap({ try? $0.decode(toType: type, decoder: decoder) })
    }
    
}
