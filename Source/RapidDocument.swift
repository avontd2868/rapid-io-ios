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
func == (lhs: RapidDocument, rhs: RapidDocument) -> Bool {
    if lhs.id == rhs.id && lhs.collectionID == rhs.collectionID && lhs.etag == rhs.etag {
        if let lValue = lhs.value, let rValue = rhs.value {
            return NSDictionary(dictionary: lValue).isEqual(to: rValue)
        }
        else if lhs.value == nil && rhs.value == nil {
            return true
        }
    }
    
    return false
}

/// Class representing Rapid.io document that is returned from a subscription handler
open class RapidDocument: NSObject, NSCoding, RapidCachableObject {
    
    var objectID: String {
        return id
    }
    
    var groupID: String {
        return collectionID
    }
    
    /// Document ID
    public let id: String
    
    /// Collection ID
    public let collectionID: String
    
    /// Document body
    public let value: [AnyHashable: Any]?
    
    /// Etag identifier
    public let etag: String?
    
    /// Time of a document creation
    public let createdAt: Date?
    
    /// Time of a document modification
    public let modifiedAt: Date?
    
    /// Document creation sort identifier
    let sortValue: String
    
    /// Value that serves to order documents
    ///
    /// Value is computed by Rapid.io database based on sort descriptors in a subscription
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
        
        let body = dict[RapidSerialization.Document.Body.name] as? [AnyHashable: Any]
        let sortKeys = dict[RapidSerialization.Document.SortKeys.name] as? [String]
        
        self.id = id
        self.collectionID = collectionID
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
        
        let body = dict[RapidSerialization.Document.Body.name] as? [AnyHashable: Any]
        let sortKeys = dict[RapidSerialization.Document.SortKeys.name] as? [String]
        
        self.id = id
        self.collectionID = collectionID
        self.value = body
        self.etag = nil
        self.createdAt = nil
        self.modifiedAt = nil
        self.sortKeys = sortKeys ?? []
        self.sortValue = ""
    }
    
    init(removedDocId id: String, collectionID: String) {
        self.id = id
        self.collectionID = collectionID
        self.value = nil
        self.etag = nil
        self.createdAt = nil
        self.modifiedAt = nil
        self.sortKeys = []
        self.sortValue = ""
    }
    
    init?(document: RapidDocument, newValue: [AnyHashable: Any]) {
        self.id = document.id
        self.collectionID = document.collectionID
        self.etag = document.etag
        self.createdAt = document.createdAt
        self.modifiedAt = document.modifiedAt
        self.sortKeys = document.sortKeys
        self.sortValue = document.sortValue
        self.value = newValue
    }
    
    public required init?(coder aDecoder: NSCoder) {
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
        self.collectionID = collectionID
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
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(collectionID, forKey: "collectionID")
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
    
    override open func isEqual(_ object: Any?) -> Bool {
        if let document = object as? RapidDocument {
            return self == document
        }
        
        return false
    }
    
    override open var description: String {
        var dict: [AnyHashable: Any] = [
            "id": id,
            "etag": String(describing: etag),
            "collectionID": collectionID,
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
}

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
    
    fileprivate var set = Set<RapidDocumentOperation>()
    
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
