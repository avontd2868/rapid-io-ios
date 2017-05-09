//
//  RapidMutations.swift
//  Rapid
//
//  Created by Jan on 28/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Document mutation

/// Document mutation request
class RapidDocumentMutation: NSObject, RapidMutationRequest {
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false
    
    /// Document JSON
    let value: [AnyHashable: Any]
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Mutation callback
    let callback: RapidMutationCallback?
    
    /// Timout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Cache handler
    internal weak var cacheHandler: RapidCacheHandler?
    
    /// Initialize mutation request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: Document JSON
    ///   - callback: Mutation callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], callback: RapidMutationCallback?, cache: RapidCacheHandler?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
        self.cacheHandler = cache
    }
    
}

extension RapidDocumentMutation: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(mutation: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentMutation: RapidTimeoutRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid document \(self.documentID) in collection \(self.collectionID) mutated", level: .info)
            
            let snapshot = RapidDocumentSnapshot(id: self.documentID, collectionID: self.collectionID, value: self.value)
            self.cacheHandler?.storeObject(snapshot)
            
            self.callback?(nil, self.value)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid mutation failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.callback?(error.error, nil)
        }
    }
}

// MARK: Document merge

/// Document merge request
class RapidDocumentMerge: NSObject, RapidMutationRequest {
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false

    /// JSON with values to be merged
    let value: [AnyHashable: Any]
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Merge callback
    let callback: RapidMutationCallback?
    
    /// Timeout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Cache handler
    internal weak var cacheHandler: RapidCacheHandler?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: JSON with values to be merged
    ///   - callback: Merge callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], callback: RapidMergeCallback?, cache: RapidCacheHandler?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
        self.cacheHandler = cache
    }
    
}

extension RapidDocumentMerge: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(merge: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentMerge: RapidTimeoutRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid document \(self.documentID) in collection \(self.collectionID) merged", level: .info)
            
            self.cacheHandler?.loadObject(withGroupID: self.collectionID, objectID: self.documentID, completion: { (object) in
                if let snapshot = object as? RapidDocumentSnapshot, var value = snapshot.value {
                    value.merge(with: self.value)
                    let snapshot = RapidDocumentSnapshot(id: self.documentID, collectionID: self.collectionID, value: value)
                    self.cacheHandler?.storeObject(snapshot)
                }
            })
            self.callback?(nil, self.value)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid merge failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.callback?(error.error, nil)
        }
    }
}

// MARK: Document delete

/// Document merge request
class RapidDocumentDelete: NSObject, RapidMutationRequest {
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Merge callback
    let callback: RapidDeletionCallback?
    
    /// Timeout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Cache handler
    internal weak var cacheHandler: RapidCacheHandler?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - callback: Delete callback
    init(collectionID: String, documentID: String, callback: RapidDeletionCallback?, cache: RapidCacheHandler?) {
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
        self.cacheHandler = cache
    }
    
}

extension RapidDocumentDelete: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(delete: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentDelete: RapidTimeoutRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid document \(self.documentID) in collection \(self.collectionID) deleted", level: .info)
            
            self.cacheHandler?.removeObject(withGroupID: self.collectionID, objectID: self.documentID)
            
            self.callback?(nil)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid delete failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.callback?(error.error)
        }
    }
}
