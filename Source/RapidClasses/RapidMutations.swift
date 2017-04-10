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
    let value: [AnyHashable: Any]?
    
    /// Collection ID
    let collectionID: String
    
    /// Document ID
    let documentID: String
    
    /// Mutation callback
    let callback: RapidMutationCallback?
    
    /// Timout delegate
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    /// Initialize mutation request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: Document JSON
    ///   - callback: Mutation callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any]?, callback: RapidMutationCallback?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
    }
    
    /// Initialize mutation request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: Document JSON
    ///   - callback: Mutation callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any]?, deletionCallback: RapidDeletionCallback?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = { error, _ in deletionCallback?(error) }
    }
    
}

extension RapidDocumentMutation: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        return try RapidSerialization.serialize(mutation: self, withIdentifiers: identifiers)
    }
}

extension RapidDocumentMutation: RapidTimeoutRequest {
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
        // Start timeout

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
    
    func invalidateTimer() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
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

/// Document merge request
class RapidDocumentMerge: NSObject, RapidMergeRequest {
    
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
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    /// Initialize merge request
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - value: JSON with values to be merged
    ///   - callback: Merge callback
    init(collectionID: String, documentID: String, value: [AnyHashable: Any], callback: RapidMergeCallback?) {
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
        // Start timeout countdown
        
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
    
    func invalidateTimer() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
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
