//
//  RapidDocumentExecution.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Execution

/// Flow controller for a document execution
class RapidDocumentExecution: RapidExecution {
    
    /// Operation identifier
    let identifier = Rapid.uniqueID
    
    /// Collection identifier
    let collectionID: String
    
    /// Document identifier
    let documentID: String
    
    /// Flow controller delegate
    weak var delegate: RapidExectuionDelegate?
    
    /// Cache handler
    weak var cacheHandler: RapidCacheHandler?
    
    /// Execution block that returns a client action based on current data
    let executionBlock: RapidDocumentExecutionBlock
    
    /// Completion handler
    let completion: RapidDocumentExecutionCompletion?
    
    /// Fetch document request
    var fetchRequest: RapidFetchInstance {
        let fetch = RapidDocumentFetch(collectionID: collectionID, documentID: documentID, cache: cacheHandler, completion: { [weak self] result in
            switch result {
            case .success(let document):
                self?.resolveValue(forDocument: document)
                
            case .failure(let error):
                self?.completeExecution(withError: error)
            }
        })
        
        return fetch
    }
    
    /// Initialize optimistic concurrency flow controller
    ///
    /// - Parameters:
    ///   - collectionID: Collection ID
    ///   - documentID: Document ID
    ///   - delegate: Flow controller delegate
    ///   - block: Execution block that returns a client action based on current data
    ///   - completion: Completion handler
    init(collectionID: String, documentID: String, delegate: RapidExectuionDelegate, block: @escaping RapidDocumentExecutionBlock, completion: RapidDocumentExecutionCompletion?) {
        self.collectionID = collectionID
        self.documentID = documentID
        self.executionBlock = block
        self.completion = completion
        self.delegate = delegate
    }
    
    /// Send fetch document request
    internal func sendFetchRequest() {
        delegate?.sendFetchRequest(fetchRequest)
    }
    
    /// Pass current value to `RapidDocumentExecutionBlock` and perform an action based on a result
    ///
    /// - Parameter document: `RapidDocument` returned from fetch
    internal func resolveValue(forDocument document: RapidDocument) {
        DispatchQueue.main.async { [weak self] in
            // Get developer action
            guard let result = self?.executionBlock(document) else {
                return
            }
            
            switch result {
            case .write(let value):
                self?.write(value: value, forDocument: document)
                
            case .delete:
                self?.delete(document: document)
                
            case .abort:
                self?.completeExecution(withError: RapidError.executionFailed(reason: .aborted))
            }
        }
    }
    
    /// Decide what to do after the server responds to a write trial
    ///
    /// - Parameter error: Optional resulting error
    internal func resolveWriteError(_ error: RapidError) {
        // If the error is a write-conflict error start over the whole flow
        // Otherwise, finish the optimistic concurrency flow
        if case RapidError.executionFailed(let reason) = error,
            case RapidError.ExecutionError.writeConflict = reason {
            
            sendFetchRequest()
        }
        else {
            completeExecution(withError: error)
        }
    }
    
    /// Finish the optimistic concurrency flow
    ///
    /// - Parameter error: Optional resulting error
    internal func completeExecution(withError error: RapidError?) {
        // Inform the delegate so that it can release the flow controller
        delegate?.executionCompleted(self)
        
        DispatchQueue.main.async {
            if let error = error {
                self.completion?(.failure(error: error))
            }
            else {
                self.completion?(.success(value: nil))
            }
        }
    }
    
    /// Process a write action returned from `RapidConcurrencyOptimisticBlock`
    ///
    /// - Parameters:
    ///   - value: Value to be written
    ///   - document: `RapidDocument` returned from fetch
    internal func write(value: [String: Any], forDocument document: RapidDocument) {
        let request = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, cache: cacheHandler, completion: { [weak self] result in
            switch result {
            case .failure(let error):
                self?.resolveWriteError(error)
                
            case .success:
                self?.completeExecution(withError: nil)
            }
        })
        request.etag = document.etag ?? Rapid.nilValue
        delegate?.sendMutationRequest(request)
    }
    
    /// Process a delete action returned from `RapidConcurrencyOptimisticBlock`
    ///
    /// - Parameter document: `RapidDocument` returned from fetch
    internal func delete(document: RapidDocument) {
        let request = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, cache: cacheHandler, completion: { [weak self] result in
            switch result {
            case .failure(let error):
                self?.resolveWriteError(error)
                
            case .success:
                self?.completeExecution(withError: nil)
            }
        })
        request.etag = document.etag ?? Rapid.nilValue
        delegate?.sendMutationRequest(request)
    }
}
