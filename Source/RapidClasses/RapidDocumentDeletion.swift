//
//  RapidDocumentDeletion.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Document delete

/// Document merge request
class RapidDocumentDelete: NSObject, RapidMutationRequest {
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Deletion completion
    let completion: RapidDocumentDeletionCompletion?
    
    /// Timeout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Cache handler
    internal weak var cacheHandler: RapidCacheHandler?
    
    internal weak var requestDelegate: RapidMutationRequestDelegate?
    
    /// Etag for concurrency optimistic mutation
    var etag: Any?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - completion: Delete completion handler
    init(collectionID: String, documentID: String, cache: RapidCacheHandler?, completion: RapidDocumentDeletionCompletion?) {
        self.collectionID = collectionID
        self.documentID = documentID
        self.completion = completion
        self.cacheHandler = cache
    }
    
    func register(delegate: RapidMutationRequestDelegate) {
        self.requestDelegate = delegate
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
            
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid delete failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.completion?(.failure(error: error.error))
        }
    }
}

extension RapidDocumentDelete: RapidWriteRequest {
    
    func cancel() {
        requestDelegate?.cancelMutationRequest(self)
    }
}

// MARK: On-connect merge

class RapidDocumentOnConnectDelete: NSObject {
    
    let delete: RapidDocumentDelete!
    
    fileprivate(set) var completion: RapidDocumentMergeCompletion?
    
    fileprivate(set) var actionID: String?
    fileprivate(set) weak var delegate: RapidOnConnectActionDelegate?
    
    init(collectionID: String, documentID: String, completion: RapidDocumentMergeCompletion?) {
        self.completion = completion
        
        self.delete = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, cache: nil, completion: nil)
    }
    
}

extension RapidDocumentOnConnectDelete: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(delete: delete, withIdentifiers: identifiers)
    }
}

extension RapidDocumentOnConnectDelete: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        RapidLogger.log(message: "Rapid on-connect delete performed - document \(self.delete.documentID) in collection \(self.delete.collectionID)", level: .info)
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        switch error.error {
        case .cancelled, .permissionDenied:
            DispatchQueue.main.async {
                RapidLogger.log(message: "Rapid on-connect delete cancelled - document \(self.delete.documentID) in collection \(self.delete.collectionID) - because of error: \(error)", level: .info)
                
                self.completion?(.failure(error: error.error))
            }
            
        default:
            break
        }
    }
    
}

extension RapidDocumentOnConnectDelete: RapidOnConnectAction {
    
    func register(actionID: String, delegate: RapidOnConnectActionDelegate) {
        self.actionID = actionID
        self.delegate = delegate
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-connect delete registered - document \(self.delete.documentID) in collection \(self.delete.collectionID)", level: .info)
            
            self.completion?(.success(value: nil))
        }
    }
}

extension RapidDocumentOnConnectDelete: RapidWriteRequest {
    
    func cancel() {
        if let id = actionID {
            delegate?.cancelOnConnectAction(withActionID: id)
        }
    }
}

// MARK: On-disconnect delete

class RapidDocumentOnDisconnectDelete: NSObject {
    
    let delete: RapidDocumentDelete!
    
    fileprivate(set) var completion: RapidDocumentDeletionCompletion?
    
    fileprivate(set) var actionID: String?
    fileprivate(set) weak var delegate: RapidOnDisconnectActionDelegate?
    
    init(collectionID: String, documentID: String, completion: RapidDocumentDeletionCompletion?) {
        self.completion = completion
        
        self.delete = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, cache: nil, completion: nil)
    }
    
}

extension RapidDocumentOnDisconnectDelete: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(disconnectAction: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentOnDisconnectDelete: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation registered - document \(self.delete.documentID) in collection \(self.delete.collectionID)", level: .debug)
            
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation cancelled - document \(self.delete.documentID) in collection \(self.delete.collectionID) - because of error: \(error)", level: .debug)
            
            self.completion?(.failure(error: error.error))
        }
    }
    
}

extension RapidDocumentOnDisconnectDelete: RapidOnDisconnectAction {
    
    func actionJSON() throws -> [AnyHashable : Any] {
        let jsonString = try RapidSerialization.serialize(delete: delete, withIdentifiers: [:])
        return try jsonString.json() ?? [:]
    }
    
    func register(actionID: String, delegate: RapidOnDisconnectActionDelegate) {
        self.actionID = actionID
        self.delegate = delegate
    }
    
    func cancelRequest() -> RapidCancelOnDisconnectAction {
        return RapidCancelOnDisconnectAction(actionID: actionID ?? "", collectionID: delete.collectionID, documentID: delete.documentID)
    }
}

extension RapidDocumentOnDisconnectDelete: RapidWriteRequest {
    
    func cancel() {
        if let id = actionID {
            delegate?.cancelOnDisconnectAction(withActionID: id)
        }
    }
}
