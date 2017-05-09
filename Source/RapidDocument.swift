//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Document subscription callback which provides a client either with an error or with a document
public typealias RapidDocSubCallback = (_ error: Error?, _ value: RapidDocumentSnapshot) -> Void

/// Document mutation callback which provides a client either with an error or with a successfully mutated object
public typealias RapidMutationCallback = (_ error: Error?, _ object: Any?) -> Void

/// Document deletion callback which provides a client with an possible error
public typealias RapidDeletionCallback = (_ error: Error?) -> Void

/// Document merge callback which provides a client either with an error or with a successfully merged values
public typealias RapidMergeCallback = (_ error: Error?, _ object: Any?) -> Void

/// Compare two docuement snapshots
///
/// Compera ids, etags and dictionaries
///
/// - Parameters:
///   - lhs: Left operand
///   - rhs: Right operand
/// - Returns: `true` if operands are equal
func == (lhs: RapidDocumentSnapshot, rhs: RapidDocumentSnapshot) -> Bool {
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

/// Class representing Rapid.io document that is returned from a subscription callback
public class RapidDocumentSnapshot: NSObject, NSCoding, RapidCachableObject {
    
    /// Document ID
    public let id: String
    
    public let collectionID: String
    
    var objectID: String {
        return id
    }
    
    var groupID: String {
        return collectionID
    }
    
    /// Document body
    public let value: [AnyHashable: Any]?
    
    /// Etag identifier
    public let etag: String?
    
    /// Document creation time
    public let createdAt: Date?
    
    /// Value that serves to order documents
    ///
    /// Value is computed by Rapid.io database based on sort descriptors in a subscription
    let sortKeys: [String]
    
    init?(json: Any?, collectionID: String) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let id = dict[RapidSerialization.Document.DocumentID.name] as? String else {
            return nil
        }
        
        let body = dict[RapidSerialization.Document.Body.name] as? [AnyHashable: Any]
        let etag = dict[RapidSerialization.Document.Etag.name] as? String
        let sortValue = dict[RapidSerialization.Document.SortKeys.name] as? [String]
        let createdAt = dict[RapidSerialization.Document.Created.name] as? TimeInterval
        
        self.id = id
        self.collectionID = collectionID
        self.value = body
        self.etag = etag
        self.sortKeys = sortValue ?? []
        
        if let createdAt = createdAt {
            self.createdAt = Date(timeIntervalSince1970: createdAt/1000)
        }
        else {
            self.createdAt = nil
        }
    }
    
    init(id: String, collectionID: String, value: [AnyHashable: Any]?, etag: String? = nil) {
        self.id = id
        self.collectionID = collectionID
        self.value = value
        self.etag = etag
        self.sortKeys = []
        self.createdAt = nil
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
        
        self.id = id
        self.collectionID = collectionID
        self.etag = aDecoder.decodeObject(forKey: "etag") as? String
        self.sortKeys = sortKeys
        self.createdAt = aDecoder.decodeObject(forKey: "createdAt") as? Date
        do {
            self.value = try (aDecoder.decodeObject(forKey: "value") as? String)?.json()
        }
        catch {
            self.value = nil
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(collectionID, forKey: "collectionID")
        aCoder.encode(etag, forKey: "etag")
        aCoder.encode(sortKeys, forKey: "sortKeys")
        aCoder.encode(createdAt, forKey: "createdAt")
        do {
            aCoder.encode(try value?.jsonString(), forKey: "value")
        }
        catch {}
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        if let snapshot = object as? RapidDocumentSnapshot {
            return self == snapshot
        }

        return false
    }
    
}

/// Class representing Rapid.io document
public class RapidDocument: NSObject {
    
    fileprivate weak var handler: RapidHandler?
    fileprivate var socketManager: RapidSocketManager {
        return try! getSocketManager()
    }
    
    /// ID of a collection to which the document belongs
    public let collectionID: String
    /// Document ID
    public let documentID: String
    
    init(id: String, inCollection collectionID: String, handler: RapidHandler!) {
        self.documentID = id
        self.collectionID = collectionID
        self.handler = handler
    }
    
    /// Mutate the document
    ///
    /// All values in the document are replaced by values in the provided dictionary
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - completion: Mutation callback which provides a client either with an error or with a successfully mutated object
    public func mutate(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, callback: completion, cache: handler)
        socketManager.mutate(mutationRequest: mutation)
    }
    
    /// Merge values in the document with new ones
    ///
    /// Values that are not mentioned in the provided dictionary remains as they are.
    /// Values that are mentioned in the provided dictionary are either replaced or added to the document.
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that should be merged into the document
    ///   - completion: merge callback which provides a client either with an error or with a successfully merged values
    public func merge(value: [AnyHashable: Any], completion: RapidMergeCallback? = nil) {
        let merge = RapidDocumentMerge(collectionID: collectionID, documentID: documentID, value: value, callback: completion, cache: handler)
        socketManager.mutate(mutationRequest: merge)
    }
    
    /// Delete the document
    ///
    /// `Delete` is equivalent to `Mutate` with a value equal to `nil`
    ///
    /// - Parameter completion: Delete callback which provides a client either with an error or with the document object how it looked before it was deleted
    public func delete(completion: RapidDeletionCallback? = nil) {
        let deletion = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, callback: completion, cache: handler)
        socketManager.mutate(mutationRequest: deletion)
    }
    
    /// Subscribe for listening to the document changes
    ///
    /// - Parameter completion: subscription callback which provides a client either with an error or with a document
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribe(completion: @escaping RapidDocSubCallback) -> RapidSubscription {
        let subscription = RapidDocumentSub(collectionID: collectionID, documentID: documentID, callback: completion)
        
        socketManager.subscribe(subscription)
        
        return subscription
    }
    
}

extension RapidDocument {
    
    func getSocketManager() throws -> RapidSocketManager {
        if let manager = handler?.socketManager {
            return manager
        }

        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, priority: .high)
        throw RapidInternalError.rapidInstanceNotInitialized
    }
}
