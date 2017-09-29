//
//  RapidDocumentMerge.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Document merge

/// Document merge request
class RapidDocumentMerge: RapidMutationRequest {
    
    /// Request should timeout only if `Rapid.timeout` is set
    let alwaysTimeout = false
    
    /// JSON with values to be merged
    let value: [String: Any]
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Merge completion
    let completion: RapidDocumentMergeCompletion?
    
    /// Timeout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Cache handler
    internal weak var cacheHandler: RapidDocCacheHandler?
    
    internal weak var requestDelegate: RapidMutationRequestDelegate?
    
    /// Etag for concurrency optimistic mutation
    var etag: Any?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: JSON with values to be merged
    ///   - completion: Merge completion
    init(collectionID: String, documentID: String, value: [String: Any], cache: RapidDocCacheHandler?, completion: RapidDocumentMergeCompletion?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.completion = completion
        self.cacheHandler = cache
    }
    
    func register(delegate: RapidMutationRequestDelegate) {
        self.requestDelegate = delegate
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
                if let oldDoc = object, var value = oldDoc.value {
                    value.merge(with: self.value)
                    if let document = RapidDocument(document: oldDoc, newValue: value) {
                        self.cacheHandler?.storeObject(document)
                    }
                }
            })
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid merge failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.completion?(.failure(error: error.error))
        }
    }
}

extension RapidDocumentMerge: RapidWriteRequest {
    
    func cancel() {
        requestDelegate?.cancelMutationRequest(self)
    }
}

// MARK: On-connect merge

class RapidDocumentOnConnectMerge {
    
    let merge: RapidDocumentMerge!
    
    internal(set) var completion: RapidDocumentRegisterOnConnectActionCompletion?
    
    internal(set) var actionID: String?
    internal(set) weak var delegate: RapidOnConnectActionDelegate?
    
    init(collectionID: String, documentID: String, value: [String: Any], completion: RapidDocumentRegisterOnConnectActionCompletion?) {
        self.completion = completion
        
        self.merge = RapidDocumentMerge(collectionID: collectionID, documentID: documentID, value: value, cache: nil, completion: nil)
    }
    
}

extension RapidDocumentOnConnectMerge: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(merge: merge, withIdentifiers: identifiers)
    }
}

extension RapidDocumentOnConnectMerge: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        RapidLogger.log(message: "Rapid on-connect merge performed - document \(self.merge.documentID) in collection \(self.merge.collectionID)", level: .debug)
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        switch error.error {
        case .cancelled, .permissionDenied:
            DispatchQueue.main.async {
                RapidLogger.log(message: "Rapid on-connect merge cancelled - document \(self.merge.documentID) in collection \(self.merge.collectionID) - because of error: \(error)", level: .debug)
                
                self.completion?(.failure(error: error.error))
            }
            
        default:
            break
        }
    }
    
}

extension RapidDocumentOnConnectMerge: RapidOnConnectAction {
    
    func register(actionID: String, delegate: RapidOnConnectActionDelegate) {
        self.actionID = actionID
        self.delegate = delegate
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-connect merge registered - document \(self.merge.documentID) in collection \(self.merge.collectionID)", level: .debug)
            
            self.completion?(.success(value: nil))
        }
    }
}

extension RapidDocumentOnConnectMerge: RapidWriteRequest {
    
    func cancel() {
        if let id = actionID {
            delegate?.cancelOnConnectAction(withActionID: id)
        }
    }
}

// MARK: On-disconnect merge

class RapidDocumentOnDisconnectMerge {
    
    let merge: RapidDocumentMerge!
    
    internal(set) var completion: RapidDocumentRegisterOnDisonnectActionCompletion?
    
    internal(set) var actionID: String?
    internal(set) weak var delegate: RapidOnDisconnectActionDelegate?
    
    init(collectionID: String, documentID: String, value: [String: Any], completion: RapidDocumentRegisterOnDisonnectActionCompletion?) {
        self.completion = completion
        
        self.merge = RapidDocumentMerge(collectionID: collectionID, documentID: documentID, value: value, cache: nil, completion: nil)
    }
    
}

extension RapidDocumentOnDisconnectMerge: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(disconnectAction: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentOnDisconnectMerge: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation registered - document \(self.merge.documentID) in collection \(self.merge.collectionID)", level: .debug)
            
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation cancelled - document \(self.merge.documentID) in collection \(self.merge.collectionID) - because of error: \(error)", level: .debug)
            
            self.completion?(.failure(error: error.error))
        }
    }
    
}

extension RapidDocumentOnDisconnectMerge: RapidOnDisconnectAction {
    
    func actionJSON() throws -> [AnyHashable : Any] {
        let jsonString = try RapidSerialization.serialize(merge: merge, withIdentifiers: [:])
        return try jsonString.json() ?? [:]
    }
    
    func register(actionID: String, delegate: RapidOnDisconnectActionDelegate) {
        self.actionID = actionID
        self.delegate = delegate
    }
    
    func cancelRequest() -> RapidCancelOnDisconnectAction {
        return RapidCancelOnDisconnectAction(actionID: actionID ?? "", collectionID: merge.collectionID, documentID: merge.documentID)
    }
}

extension RapidDocumentOnDisconnectMerge: RapidWriteRequest {
    
    func cancel() {
        if let id = actionID {
            delegate?.cancelOnDisconnectAction(withActionID: id)
        }
    }
}
