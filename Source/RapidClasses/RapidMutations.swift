//
//  RapidMutations.swift
//  Rapid
//
//  Created by Jan on 28/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Concurrency optimistic mutations

/// Flow controller for optimistic concurrency document write
class RapidConOptDocumentMutation: RapidConcurrencyOptimisticMutation {
    
    /// Optimistic concurrency write
    ///
    /// - mutate: Document mutation
    /// - merge: Document merge
    /// - delete: Document delete
    enum WriteType {
        case mutate
        case merge
        case delete
    }
    
    /// Operation identifier
    let identifier = Generator.uniqueID
    
    /// Collection identifier
    let collectionID: String
    
    /// Document identifier
    let documentID: String
    
    /// Write type
    let type: WriteType
    
    /// Flow controller delegate
    weak var delegate: RapidConOptMutationDelegate?
    
    /// Cache handler
    weak var cacheHandler: RapidCacheHandler?
    
    /// Optimistic concurrency block that returns a client action based on current data
    let concurrencyBlock: RapidConcurrencyOptimisticBlock
    
    /// Completion callback
    let completion: RapidConcurrencyCompletionBlock?
    
    /// Fetch document request
    var fetchRequest: RapidFetchInstance {
        let fetch = RapidDocumentFetch(collectionID: collectionID, documentID: documentID, cache: cacheHandler, callback: { [weak self] (error, document) in
            if let error = error {
                self?.completeMutation(withError: error)
            }
            else {
                self?.resolveValue(forDocument: document)
            }
        })
        
        return fetch
    }
    
    /// Initialize optimistic concurrency flow controller
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - type: Write type
    ///   - delegate: Flow controller delegate
    ///   - concurrencyBlock: Optimistic concurrency block that returns a client action based on current data
    ///   - completion: Completion callback
    init(collectionID: String, documentID: String, type: WriteType, delegate: RapidConOptMutationDelegate, concurrencyBlock: @escaping RapidConcurrencyOptimisticBlock, completion: RapidConcurrencyCompletionBlock?) {
        self.collectionID = collectionID
        self.documentID = documentID
        self.type = type
        self.concurrencyBlock = concurrencyBlock
        self.completion = completion
        self.delegate = delegate
    }
    
    /// Send fetch document request
    fileprivate func sendFetchRequest() {
        delegate?.sendFetchRequest(fetchRequest)
    }
    
    /// Pass current value to `RapidConcurrencyOptimisticBlock` and perform an action based on a result
    ///
    /// - Parameter document: `RapidDocumentSnapshot` returned from fetch
    fileprivate func resolveValue(forDocument document: RapidDocumentSnapshot) {
        DispatchQueue.main.async { [weak self] in
            // Get developer action
            guard let result = self?.concurrencyBlock(document.value) else {
                return
            }
            
            switch result {
            case .write(let value):
                self?.write(value: value, forDocument: document)
                
            case .delete():
                self?.delete(document: document)
                
            case .abort():
                self?.completeMutation(withError: RapidError.concurrencyWriteFailed(reason: .aborted))
            }
        }
    }
    
    /// Decide what to do after the server responds to a write trial
    ///
    /// - Parameter error: Optional resulting error
    fileprivate func resolveWriteResponse(withError error: Error?) {
        // If the error is a write-conflict error start over the whole flow
        // Otherwise, finish the optimistic concurrency flow
        if let error = error as? RapidError,
            case RapidError.concurrencyWriteFailed(let reason) = error,
            case RapidError.ConcurrencyWriteError.writeConflict = reason {
            
            sendFetchRequest()
        }
        else {
            completeMutation(withError: error)
        }
    }
    
    /// Finish the optimistic concurrency flow
    ///
    /// - Parameter error: Optional resulting error
    fileprivate func completeMutation(withError error: Error?) {
        // Inform the delegate so that it can release the flow controller
        delegate?.conOptMutationCompleted(self)
        
        DispatchQueue.main.async {
            self.completion?(error)
        }
    }
    
    /// Process a write action returned from `RapidConcurrencyOptimisticBlock`
    ///
    /// - Parameters:
    ///   - value: Value to be written
    ///   - document: `RapidDocumentSnapshot` returned from fetch
    fileprivate func write(value: [AnyHashable: Any], forDocument document: RapidDocumentSnapshot) {
        switch type {
        case .mutate:
            let request = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, cache: cacheHandler, callback: { [weak self] error in
                self?.resolveWriteResponse(withError: error)
            })
            request.etag = document.etag ?? Rapid.nilValue
            delegate?.sendMutationRequest(request)
            
        case .merge:
            let request = RapidDocumentMerge(collectionID: collectionID, documentID: documentID, value: value, cache: cacheHandler, callback: { [weak self] error in
                self?.resolveWriteResponse(withError: error)
            })
            request.etag = document.etag ?? Rapid.nilValue
            delegate?.sendMutationRequest(request)
            
        case .delete:
            let message = "Concurrecy block returned value, but the concurrency request type is delete"
            completeMutation(withError: RapidError.concurrencyWriteFailed(reason: .invalidResult(message: message)))
        }
    }
    
    /// Process a delete action returned from `RapidConcurrencyOptimisticBlock`
    ///
    /// - Parameter document: `RapidDocumentSnapshot` returned from fetch
    fileprivate func delete(document: RapidDocumentSnapshot) {
        if type == .delete {
            let request = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, cache: cacheHandler, callback: { [weak self] (error) in
                self?.resolveWriteResponse(withError: error)
            })
            request.etag = document.etag ?? Rapid.nilValue
            delegate?.sendMutationRequest(request)
        }
        else {
            let message = "Concurrecy block returned `delete` result, but the concurrency request type is different from delete"
            completeMutation(withError: RapidError.concurrencyWriteFailed(reason: .invalidResult(message: message)))
        }
    }
}

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
    
    /// Etag for concurrency optimistic mutation
    var etag: Any?
    
    /// Initialize mutation request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: Document JSON
    ///   - callback: Mutation callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], cache: RapidCacheHandler?, callback: RapidMutationCallback?) {
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
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid document \(self.documentID) in collection \(self.collectionID) mutated", level: .info)
            
            self.cacheHandler?.loadObject(withGroupID: self.collectionID, objectID: self.documentID, completion: { (object) in
                if let oldSnapshot = object as? RapidDocumentSnapshot,
                    let snapshot = RapidDocumentSnapshot(snapshot: oldSnapshot, newValue: self.value) {
                    
                    self.cacheHandler?.storeObject(snapshot)
                }
            })
            
            self.callback?(nil)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid mutation failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.callback?(error.error)
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
    
    /// Etag for concurrency optimistic mutation
    var etag: Any?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: JSON with values to be merged
    ///   - callback: Merge callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], cache: RapidCacheHandler?, callback: RapidMergeCallback?) {
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
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid document \(self.documentID) in collection \(self.collectionID) merged", level: .info)
            
            self.cacheHandler?.loadObject(withGroupID: self.collectionID, objectID: self.documentID, completion: { (object) in
                if let oldSnapshot = object as? RapidDocumentSnapshot, var value = oldSnapshot.value {
                    value.merge(with: self.value)
                    if let snapshot = RapidDocumentSnapshot(snapshot: oldSnapshot, newValue: value) {
                        self.cacheHandler?.storeObject(snapshot)
                    }
                }
            })
            self.callback?(nil)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid merge failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.callback?(error.error)
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
    
    /// Etag for concurrency optimistic mutation
    var etag: Any?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - callback: Delete callback
    init(collectionID: String, documentID: String, cache: RapidCacheHandler?, callback: RapidDeletionCallback?) {
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
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
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
