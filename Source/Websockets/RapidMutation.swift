//
//  RapidMutateProtocol.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol MutationRequest: RapidTimeoutRequest, RapidSerializable {
}

class RapidDocumentMutation: NSObject, MutationRequest {
    
    let alwaysTimeout = false
    
    let value: [AnyHashable: Any]?
    let collectionID: String
    let documentID: String
    let callback: RapidMutationCallback?
    
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    init(collectionID: String, documentID: String, value: [AnyHashable: Any]?, callback: RapidMutationCallback?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
    }
    
}

extension RapidDocumentMutation: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(mutation: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentMutation: RapidTimeoutRequest {
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
        self.timoutDelegate = delegate
        
        timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(self.requestTimeout), userInfo: nil, repeats: false)
    }
    
    @objc func requestTimeout() {
        timer = nil
        
        timoutDelegate?.requestTimeout(self)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        timer?.invalidate()
        timer = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.callback?(nil, self?.value)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        timer?.invalidate()
        timer = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.callback?(error.error, nil)
        }
    }
}

// MARK: Merge

protocol MergeRequest: RapidTimeoutRequest, RapidSerializable {
    
}

class RapidDocumentMerge: NSObject, MergeRequest {
    
    let alwaysTimeout = false
    
    let value: [AnyHashable: Any]?
    let collectionID: String
    let documentID: String
    let callback: RapidMutationCallback?
    
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    init(collectionID: String, documentID: String, value: [AnyHashable: Any]?, callback: RapidMergeCallback?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
    }
    
}

extension RapidDocumentMerge: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(merge: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentMerge: RapidTimeoutRequest {
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
        self.timoutDelegate = delegate
        
        timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(self.requestTimeout), userInfo: nil, repeats: false)
    }
    
    @objc func requestTimeout() {
        timer = nil
        
        timoutDelegate?.requestTimeout(self)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        timer?.invalidate()
        timer = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.callback?(nil, self?.value)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        timer?.invalidate()
        timer = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.callback?(error.error, nil)
        }
    }
}
