//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Document subscription callback which provides a client either with an error or with a document
public typealias RapidDocSubCallback = (_ error: Error?, _ value: RapidDocument) -> Void

/// Document fetch callback which provides a client either with an error or with a document
public typealias RapidDocFetchCallback = RapidDocSubCallback

/// Document mutation callback which informs a client about the operation result
public typealias RapidMutationCallback = (_ error: Error?) -> Void

/// Document mutation callback which informs a client about the operation result
public typealias RapidDeletionCallback = RapidMutationCallback

/// Document mutation callback which informs a client about the operation result
public typealias RapidMergeCallback = RapidMutationCallback

/// Block of code which is called on optimistic concurrency write
public typealias RapidConcurrencyOptimisticBlock = (_ currentValue: [AnyHashable: Any]?) -> RapidConOptResult

/// Optimistic concurrency write completion callback which informs a client about the operation result
public typealias RapidConcurrencyCompletionBlock = RapidMutationCallback

//FIXME: Better name

/// Return type for `RapidConcurrencyOptimisticBlock`
///
/// `RapidConOptResult` represents an action that should be performed based on a current value
/// that is provided as an input parameter of `RapidConcurrencyOptimisticBlock`
///
/// - write: Write new data
/// - delete: Delete document. This action is applicable only for optimistic concurrency delete
/// - abort: Abort process
public enum RapidConOptResult {
    case write(value: [AnyHashable: Any])
    case delete()
    case abort()
}

/// Class representing Rapid.io document
public class RapidDocumentRef: NSObject {
    
    fileprivate weak var handler: RapidHandler?
    fileprivate var socketManager: RapidSocketManager {
        return try! getSocketManager()
    }
    
    /// ID of a collection to which the document belongs
    public let collectionID: String
    
    /// Document ID
    public let documentID: String
    
    init(id: String, inCollection collectionID: String, handler: RapidHandler!) {
        self.documentID = id
        self.collectionID = collectionID
        self.handler = handler
    }
    
    /// Mutate the document
    ///
    /// All values in the document are replaced by values in the provided dictionary
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - completion: Mutation callback which provides a client either with an error or with a successfully mutated object
    public func mutate(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, cache: handler, callback: completion)
        socketManager.mutate(mutationRequest: mutation)
    }
    
    //FIXME: Better name
    public func concurrencySafeMutate(value: [AnyHashable: Any], etag: String?, completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, cache: handler, callback: completion)
        mutation.etag = etag ?? Rapid.nilValue
        socketManager.mutate(mutationRequest: mutation)
    }
    
    public func concurrencySafeMutate(concurrencyBlock: @escaping RapidConcurrencyOptimisticBlock, completion: RapidConcurrencyCompletionBlock? = nil) {
        let concurrencyMutation = RapidConOptDocumentMutation(collectionID: collectionID, documentID: documentID, type: .mutate, delegate: socketManager, concurrencyBlock: concurrencyBlock, completion: completion)
        concurrencyMutation.cacheHandler = handler
        socketManager.concurrencyOptimisticMutate(mutation: concurrencyMutation)
    }
    
    /// Merge values in the document with new ones
    ///
    /// Values that are not mentioned in the provided dictionary remains as they are.
    /// Values that are mentioned in the provided dictionary are either replaced or added to the document.
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that should be merged into the document
    ///   - completion: merge callback which provides a client either with an error or with a successfully merged values
    public func merge(value: [AnyHashable: Any], completion: RapidMergeCallback? = nil) {
        let merge = RapidDocumentMerge(collectionID: collectionID, documentID: documentID, value: value, cache: handler, callback: completion)
        socketManager.mutate(mutationRequest: merge)
    }
    
    //FIXME: Better name
    public func concurrencySafeMerge(value: [AnyHashable: Any], etag: String?, completion: RapidMergeCallback? = nil) {
        let merge = RapidDocumentMerge(collectionID: collectionID, documentID: documentID, value: value, cache: handler, callback: completion)
        merge.etag = etag ?? Rapid.nilValue
        socketManager.mutate(mutationRequest: merge)
    }
    
    public func concurrencySafeMerge(concurrencyBlock: @escaping RapidConcurrencyOptimisticBlock, completion: RapidConcurrencyCompletionBlock? = nil) {
        let concurrencyMutation = RapidConOptDocumentMutation(collectionID: collectionID, documentID: documentID, type: .merge, delegate: socketManager, concurrencyBlock: concurrencyBlock, completion: completion)
        concurrencyMutation.cacheHandler = handler
        socketManager.concurrencyOptimisticMutate(mutation: concurrencyMutation)
    }
    
    /// Delete the document
    ///
    /// `Delete` is equivalent to `Mutate` with a value equal to `nil`
    ///
    /// - Parameter completion: Delete callback which provides a client either with an error or with the document object how it looked before it was deleted
    public func delete(completion: RapidDeletionCallback? = nil) {
        let deletion = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, cache: handler, callback: completion)
        socketManager.mutate(mutationRequest: deletion)
    }
    
    //FIXME: Better name
    public func concurrencySafeDelete(etag: String, completion: RapidDeletionCallback? = nil) {
        let deletion = RapidDocumentDelete(collectionID: collectionID, documentID: documentID, cache: handler, callback: completion)
        deletion.etag = etag
        socketManager.mutate(mutationRequest: deletion)
    }
    
    public func concurrencySafeDelete(concurrencyBlock: @escaping RapidConcurrencyOptimisticBlock, completion: RapidConcurrencyCompletionBlock? = nil) {
        let concurrencyMutation = RapidConOptDocumentMutation(collectionID: collectionID, documentID: documentID, type: .delete, delegate: socketManager, concurrencyBlock: concurrencyBlock, completion: completion)
        concurrencyMutation.cacheHandler = handler
        socketManager.concurrencyOptimisticMutate(mutation: concurrencyMutation)
    }
    
    /// Subscribe for listening to the document changes
    ///
    /// - Parameter completion: subscription callback which provides a client either with an error or with a document
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    public func subscribe(completion: @escaping RapidDocSubCallback) -> RapidSubscription {
        let subscription = RapidDocumentSub(collectionID: collectionID, documentID: documentID, callback: completion)
        
        socketManager.subscribe(subscription)
        
        return subscription
    }
    
    /// Fetch document
    ///
    /// - Parameter completion: Fetch callback which provides a client either with an error or with an array of documents
    public func readOnce(completion: @escaping RapidDocFetchCallback) {
        let fetch = RapidDocumentFetch(collectionID: collectionID, documentID: documentID, cache: handler, callback: completion)
        
        socketManager.fetch(fetch)
    }
    
}

extension RapidDocumentRef {
    
    func getSocketManager() throws -> RapidSocketManager {
        if let manager = handler?.socketManager {
            return manager
        }

        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, level: .critical)
        throw RapidInternalError.rapidInstanceNotInitialized
    }
}
