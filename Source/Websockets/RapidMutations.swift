//
//  RapidMutations.swift
//  Rapid
//
//  Created by Jan on 28/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Document mutation

class RapidDocumentMutation: NSObject, RapidMutationRequest {
    
    let alwaysTimeout = false
    let needsAcknowledgement = true
    
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
        
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                self?.timer = Timer.scheduledTimer(timeInterval: timeout, target: strongSelf, selector: #selector(strongSelf.requestTimeout), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func requestTimeout() {
        timer = nil
        
        timoutDelegate?.requestTimeout(self)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.callback?(nil, self.value)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.callback?(error.error, nil)
        }
    }
}

// MARK: Document merge

class RapidDocumentMerge: NSObject, RapidMergeRequest {
    
    let alwaysTimeout = false
    let needsAcknowledgement = true
    
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
        
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                self?.timer = Timer.scheduledTimer(timeInterval: timeout, target: strongSelf, selector: #selector(strongSelf.requestTimeout), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func requestTimeout() {
        timer = nil
        
        timoutDelegate?.requestTimeout(self)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.callback?(nil, self.value)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.callback?(error.error, nil)
        }
    }
}
