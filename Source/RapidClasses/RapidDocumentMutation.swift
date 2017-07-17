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
    
    /// Mutation completion
    let completion: RapidDocumentMutationCompletion?
    
    /// Timout delegate
    internal weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    internal var requestTimeoutTimer: Timer?
    
    /// Cache handler
    internal weak var cacheHandler: RapidCacheHandler?
    
    internal weak var requestDelegate: RapidMutationRequestDelegate?
    
    /// Etag for concurrency optimistic mutation
    var etag: Any?
    
    /// Initialize mutation request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: Document JSON
    ///   - completion: Mutation completion
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], cache: RapidCacheHandler?, completion: RapidDocumentMutationCompletion?) {
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
                if let oldDoc = object as? RapidDocument,
                    let document = RapidDocument(document: oldDoc, newValue: self.value) {
                    
                    self.cacheHandler?.storeObject(document)
                }
            })
            
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        invalidateTimer()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid mutation failed - document \(self.documentID) in collection \(self.collectionID)", level: .info)
            
            self.completion?(.failure(error: error.error))
        }
    }
}

extension RapidDocumentMutation: RapidWriteRequest {
    
    func cancel() {
        requestDelegate?.cancelMutationRequest(self)
    }
}

// MARK: On-connect mutation

class RapidDocumentOnConnectMutation: NSObject {
    
    let mutation: RapidDocumentMutation!
    
    fileprivate(set) var completion: RapidDocumentMutationCompletion?
    
    fileprivate(set) var actionID: String?
    fileprivate(set) weak var delegate: RapidOnConnectActionDelegate?
    
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], completion: RapidDocumentMutationCompletion?) {
        self.completion = completion
        
        self.mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, cache: nil, completion: nil)
    }

}

extension RapidDocumentOnConnectMutation: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(mutation: mutation, withIdentifiers: identifiers)
    }
}

extension RapidDocumentOnConnectMutation: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        RapidLogger.log(message: "Rapid on-connect mutation performed - document \(self.mutation.documentID) in collection \(self.mutation.collectionID)", level: .debug)
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        cancel()
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-connect mutation cancelled - document \(self.mutation.documentID) in collection \(self.mutation.collectionID) - because of error: \(error)", level: .debug)
            
            self.completion?(.failure(error: error.error))
            self.completion = nil
        }
    }

}

extension RapidDocumentOnConnectMutation: RapidOnConnectAction {
    
    func register(actionID: String, delegate: RapidOnConnectActionDelegate) {
        self.actionID = actionID
        self.delegate = delegate
        
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-connect mutation registered - document \(self.mutation.documentID) in collection \(self.mutation.collectionID)", level: .debug)
            
            self.completion?(.success(value: nil))
        }
    }

    func performAction() {
        delegate?.mutate(mutationRequest: mutation)
    }
}

extension RapidDocumentOnConnectMutation: RapidWriteRequest {
    
    func cancel() {
        if let id = actionID {
            delegate?.cancelOnConnectAction(withActionID: id)
        }
    }
}

// MARK: On-disconnect mutation

class RapidDocumentOnDisconnectMutation: NSObject {
    
    let mutation: RapidDocumentMutation!
    
    fileprivate(set) var completion: RapidDocumentMutationCompletion?
    
    fileprivate(set) var actionID: String?
    fileprivate(set) weak var delegate: RapidOnDisconnectActionDelegate?
    
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], completion: RapidDocumentMutationCompletion?) {
        self.completion = completion
        
        self.mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, cache: nil, completion: nil)
    }
    
}

extension RapidDocumentOnDisconnectMutation: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(disconnectAction: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentOnDisconnectMutation: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation registered - document \(self.mutation.documentID) in collection \(self.mutation.collectionID)", level: .debug)
            
            self.completion?(.success(value: nil))
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation cancelled - document \(self.mutation.documentID) in collection \(self.mutation.collectionID) - because of error: \(error)", level: .debug)
            
            self.completion?(.failure(error: error.error))
            self.completion = nil
        }
    }
    
}

extension RapidDocumentOnDisconnectMutation: RapidOnDisconnectAction {
    
    func actionJSON() throws -> [AnyHashable : Any] {
        let jsonString = try RapidSerialization.serialize(mutation: mutation, withIdentifiers: [:])
        return try jsonString.json() ?? [:]
    }
    
    func register(actionID: String, delegate: RapidOnDisconnectActionDelegate) {
        self.actionID = actionID
        self.delegate = delegate
    }
    
    func cancelRequest() -> RapidCancelOnDisconnectAction {
        return RapidCancelOnDisconnectAction(actionID: actionID ?? "", collectionID: mutation.collectionID, documentID: mutation.documentID)
    }
}

extension RapidDocumentOnDisconnectMutation: RapidWriteRequest {
    
    func cancel() {
        if let id = actionID {
            delegate?.cancelOnDisconnectAction(withActionID: id)
        }
    }
}

class RapidCancelOnDisconnectAction: RapidSerializable, RapidClientRequest {
    
    let actionID: String
    let collectionID: String
    let documentID: String
    
    init(actionID: String, collectionID: String, documentID: String) {
        self.actionID = actionID
        self.collectionID = collectionID
        self.documentID = documentID
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(cancelDisconnectAction: self, withIdentifiers: identifiers)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect action cancelled - document \(self.documentID) in collection \(self.collectionID)", level: .debug)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            RapidLogger.log(message: "Rapid on-disconnect mutation cancelled - document \(self.documentID) in collection \(self.collectionID) - because of error: \(error)", level: .info)
        }
    }
}
