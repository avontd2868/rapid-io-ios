//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Document subscription handler which provides a client either with an error or with a document
public typealias RapidDocumentSubscriptionHandler = (_ result: RapidResult<RapidDocument>) -> Void

/// Document fetch completion handler which provides a client either with an error or with a document
public typealias RapidDocumentFetchCompletion = RapidDocumentSubscriptionHandler

/// Document mutation completion handler which informs a client about the operation result
public typealias RapidDocumentMutationCompletion = (_ result: RapidResult<Any?>) -> Void

/// Document deletion completion handler which informs a client about the operation result
public typealias RapidDocumentDeletionCompletion = RapidDocumentMutationCompletion

/// Document merge completion handler which informs a client about the operation result
public typealias RapidDocumentMergeCompletion = RapidDocumentMutationCompletion

/// The block of code that receives current document content and a developer chooses an action based on that.
public typealias RapidDocumentExecutionBlock = (_ current: RapidDocument) -> RapidExecutionResult

/// Execution completion handler which informs a client about the operation result
public typealias RapidDocumentExecutionCompletion = RapidDocumentMutationCompletion

/// Return type for `RapidDocumentExecutionBlock`
///
/// `RapidExecutionResult` represents an action that should be performed based on a current value
/// that is provided as an input parameter of `RapidDocumentExecutionBlock`
///
/// - write: Write new data
/// - delete: Delete a document
/// - abort: Abort process
public enum RapidExecutionResult {
    case write(value: [AnyHashable: Any])
    case delete
    case abort
}

/// Class representing Rapid.io document
open class RapidDocumentRef: NSObject, RapidInstanceWithSocketManager {
    
    internal weak var handler: RapidHandler?
    
    /// Name of a collection to which the document belongs
    public let collectionName: String
    
    /// Document ID
    public let documentID: String
    
    init(id: String, inCollection collectionID: String, handler: RapidHandler!) {
        self.documentID = id
        self.collectionName = collectionID
        self.handler = handler
    }
    
    /// Mutate the document
    ///
    /// All values in the document are deleted and replaced by values in the provided dictionary
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - completion: Mutation completion handler which provides a client with an error if any error occurs
    open func mutate(value: [AnyHashable: Any], completion: RapidDocumentMutationCompletion? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        socketManager.mutate(mutationRequest: mutation)
    }
    
    /// Mutate the document with regard to a current document content.
    ///
    /// Provided etag is compared to an etag of the document stored in a database.
    /// When provided etag is `nil` it means that the document shouldn't be stored in a database yet.
    /// If provided etag equals to an etag stored in a database all values in the document are deleted and replaced by values in the provided dictionary.
    /// If provided etag differs from an etag stored in a database the mutation fails with `RapidError.executionFailed`
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - etag: `RapidDocument` etag
    ///   - completion: Mutation completion handler which provides a client with an error if any error occurs
    open func mutate(value: [AnyHashable: Any], etag: String?, completion: RapidDocumentMutationCompletion? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        mutation.etag = etag ?? Rapid.nilValue
        socketManager.mutate(mutationRequest: mutation)
    }
    
    /// Update the document with regard to a current document content.
    ///
    /// The block of code receives current document content and a developer chooses an action based on that.
    ///
    /// If the block returns `RapidExecutionResult.abort` the execution is aborted and the completion handler receives `RapidError.executionFailed(RapidError.ExecutionError.aborted)`.
    ///
    /// If the block returns `RapidExecutionResult.delete` it means that the document should be deleted, but only if it wasn't updated in a database in the meanwhile.
    /// If the document was updated in the meanwhile the block is called again with a new document content.
    ///
    /// If block returns `RapidExecutionResult.write(value)` it means that the document should be mutated with `value`, but only if it wasn't updated in a database in the meanwhile.
    /// If the document was updated in the meanwhile the block is called again with a new document content.
    ///
    /// - Parameters:
    ///   - block: Block of code that receives current document content and returns `RapidExecutionResult` based on the received value.
    ///   - completion: Execuction completion handler which provides a client with an error if any error occurs
    open func execute(block: @escaping RapidDocumentExecutionBlock, completion: RapidDocumentExecutionCompletion? = nil) {
        let concurrencyMutation = RapidDocumentExecution(collectionID: collectionName, documentID: documentID, delegate: socketManager, block: block, completion: completion)
        concurrencyMutation.cacheHandler = handler
        socketManager.execute(execution: concurrencyMutation)
    }
    
    /// Merge values in the document with values in a provided dictionary
    ///
    /// Properties that are not mentioned in the provided dictionary remains as they are.
    /// Properties that are mentioned in the provided dictionary are either replaced or added to the document.
    /// Properties that are mentioned in the provided dictionary and contains `Rapid.nilValue` are deleted from the document
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that should be merged with the document values
    ///   - completion: Merge completion handler which provides a client with an error if any error occurs
    open func merge(value: [AnyHashable: Any], completion: RapidDocumentMergeCompletion? = nil) {
        let merge = RapidDocumentMerge(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        socketManager.mutate(mutationRequest: merge)
    }
    
    /// Merge values in the document with values in a provided dictionary.
    ///
    /// Provided etag is compared to an etag of the document stored in a database.
    /// When provided etag is `nil` it means that the document shouldn't be stored in a database yet.
    /// If provided etag equals to an etag stored in a database the merge takes place.
    /// If provided etag differs from an etag stored in a database the merge fails with `RapidError.executionFailed`
    ///
    /// Properties that are not mentioned in the provided dictionary remains as they are.
    /// Properties that are mentioned in the provided dictionary are either replaced or added to the document.
    /// Properties that are mentioned in the provided dictionary and contains `Rapid.nilValue` are deleted from the document
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that should be merged with the document values
    ///   - etag: `RapidDocument` etag
    ///   - completion: Merge completion handler which provides a client with an error if any error occurs
    open func merge(value: [AnyHashable: Any], etag: String?, completion: RapidDocumentMergeCompletion? = nil) {
        let merge = RapidDocumentMerge(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        merge.etag = etag ?? Rapid.nilValue
        socketManager.mutate(mutationRequest: merge)
    }
    
    /// Delete the document
    ///
    /// - Parameter completion: Deletion completion handler which provides a client with an error if any error occurs
    open func delete(completion: RapidDocumentDeletionCompletion? = nil) {
        let deletion = RapidDocumentDelete(collectionID: collectionName, documentID: documentID, cache: handler, completion: completion)
        socketManager.mutate(mutationRequest: deletion)
    }
    
    /// Delete the document.
    ///
    /// Provided etag is compared to an etag of the document stored in a database.
    /// If provided etag equals to an etag stored in a database the merge takes place.
    /// If provided etag differs from an etag stored in a database the merge fails with `RapidError.executionFailed`.
    ///
    /// - Parameters:
    ///   - etag: `RapidDocument` etag
    ///   - completion: Deletion completion handler which provides a client with an error if any error occurs
    open func delete(etag: String, completion: RapidDocumentDeletionCompletion? = nil) {
        let deletion = RapidDocumentDelete(collectionID: collectionName, documentID: documentID, cache: handler, completion: completion)
        deletion.etag = etag
        socketManager.mutate(mutationRequest: deletion)
    }
    
}

extension RapidDocumentRef: RapidSubscriptionReference {
    
    /// Subscribe for listening to document changes
    ///
    /// - Parameter block: Subscription handler that provides a client either with an error or with any new document content
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    open func subscribe(block: @escaping RapidDocumentSubscriptionHandler) -> RapidSubscription {
        let subscription = RapidDocumentSub(collectionID: collectionName, documentID: documentID, handler: block)
        
        socketManager.subscribe(toCollection: subscription)
        
        return subscription
    }
    
}

extension RapidDocumentRef: RapidFetchReference {
    
    /// Fetch the document
    ///
    /// - Parameter completion: Fetch completion handler that provides a client either with an error or with the document
    open func fetch(completion: @escaping RapidDocumentFetchCompletion) {
        let fetch = RapidDocumentFetch(collectionID: collectionName, documentID: documentID, cache: handler, completion: completion)
        
        socketManager.fetch(fetch)
    }
    
}
