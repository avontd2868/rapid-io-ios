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
    
    /// Get an instance of Rapid document reference that is used to register
    /// actions that should be permormed when `Rapid` instance connects
    /// to a server
    ///
    /// - Returns: Instance of `RapidDocumentRefOnConnect`
    open func onConnect() -> RapidDocumentRefOnConnect {
        return try! getOnConnected()
    }
    
    /// Get an instance of Rapid document reference that is used to register
    /// actions that should be permormed when `Rapid` instance disconnects
    /// from a server
    ///
    /// - Returns: Instance of `RapidDocumentRefOnDisconnect`
    open func onDisconnect() -> RapidDocumentRefOnDisconnect {
        return try! getOnDisconnected()
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
    
    /// Subscribe for listening to data changes
    ///
    /// - Parameter objectType: Type of object to which should be json coming from Rapid server deserialized
    /// - Parameter block: Subscription handler that provides a client either with an error or with up-to-date data
    /// - Returns: Subscription object which can be used for unsubscribing
    @discardableResult
    open func subscribe<T>(objectType type: T.Type, block: @escaping (_ result: RapidResult<T>) -> Void) -> RapidSubscription where T: Decodable {
        return self.subscribe { result in
            switch result {
            case .failure(let error):
                block(RapidResult.failure(error: error))
                
            case .success(let document):
                do {
                    let object = try document.decode(toType: type)
                    block(RapidResult.success(value: object))
                }
                catch let error {
                    block(RapidResult.failure(error: RapidError.decodingFailed(messaage: error.localizedDescription)))
                }
            }
        }
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
    
    /// Fetch data
    ///
    /// - Parameter objectType: Type of object to which should be json coming from Rapid server deserialized
    /// - Parameter completion: Completion handler that provides a client either with an error or with data
    open func fetch<T>(objectType type: T.Type, completion: @escaping (_ result: RapidResult<T>) -> Void) where T : Decodable {
        self.fetch { result in
            switch result {
            case .failure(let error):
                completion(RapidResult.failure(error: error))
                
            case .success(let document):
                do {
                    let object = try document.decode(toType: type)
                    completion(RapidResult.success(value: object))
                }
                catch let error {
                    completion(RapidResult.failure(error: RapidError.decodingFailed(messaage: error.localizedDescription)))
                }
            }
        }
    }
}

extension RapidDocumentRef: RapidMutationReference {

    /// Mutate the document
    ///
    /// All values in the document are deleted and replaced by values in the provided dictionary
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - completion: Mutation completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    open func mutate(value: [AnyHashable: Any], completion: RapidDocumentMutationCompletion? = nil) -> RapidWriteRequest {
        let mutation = RapidDocumentMutation(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        socketManager.mutate(mutationRequest: mutation)
        return mutation
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
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    open func mutate(value: [AnyHashable: Any], etag: String?, completion: RapidDocumentMutationCompletion? = nil) -> RapidWriteRequest {
        let mutation = RapidDocumentMutation(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        mutation.etag = etag ?? Rapid.nilValue
        socketManager.mutate(mutationRequest: mutation)
        return mutation
    }
    
}

extension RapidDocumentRef: RapidMergeReference {
    
    /// Merge values in the document with values in a provided dictionary
    ///
    /// Properties that are not mentioned in the provided dictionary remains as they are.
    /// Properties that are mentioned in the provided dictionary are either replaced or added to the document.
    /// Properties that are mentioned in the provided dictionary and contains `Rapid.nilValue` are deleted from the document
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that should be merged with the document values
    ///   - completion: Merge completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    open func merge(value: [AnyHashable: Any], completion: RapidDocumentMergeCompletion? = nil) -> RapidWriteRequest {
        let merge = RapidDocumentMerge(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        socketManager.mutate(mutationRequest: merge)
        return merge
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
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    open func merge(value: [AnyHashable: Any], etag: String?, completion: RapidDocumentMergeCompletion? = nil) -> RapidWriteRequest {
        let merge = RapidDocumentMerge(collectionID: collectionName, documentID: documentID, value: value, cache: handler, completion: completion)
        merge.etag = etag ?? Rapid.nilValue
        socketManager.mutate(mutationRequest: merge)
        return merge
    }
    
}

extension RapidDocumentRef: RapidDeletionReference {
    
    /// Delete the document
    ///
    /// - Parameter completion: Deletion completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    open func delete(completion: RapidDocumentDeletionCompletion? = nil) -> RapidWriteRequest {
        let deletion = RapidDocumentDelete(collectionID: collectionName, documentID: documentID, cache: handler, completion: completion)
        socketManager.mutate(mutationRequest: deletion)
        return deletion
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
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    open func delete(etag: String, completion: RapidDocumentDeletionCompletion? = nil) -> RapidWriteRequest {
        let deletion = RapidDocumentDelete(collectionID: collectionName, documentID: documentID, cache: handler, completion: completion)
        deletion.etag = etag
        socketManager.mutate(mutationRequest: deletion)
        return deletion
    }
    
}

extension RapidDocumentRef {
    
    func getOnConnected() throws -> RapidDocumentRefOnConnect {
        if let handler = handler {
            return RapidDocumentRefOnConnect(id: documentID, inCollection: collectionName, handler: handler)
        }
        
        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, level: .critical)
        throw RapidInternalError.rapidInstanceNotInitialized
    }
    
    func getOnDisconnected() throws -> RapidDocumentRefOnDisconnect {
        if let handler = handler {
            return RapidDocumentRefOnDisconnect(id: documentID, inCollection: collectionName, handler: handler)
        }
        
        RapidLogger.log(message: RapidInternalError.rapidInstanceNotInitialized.message, level: .critical)
        throw RapidInternalError.rapidInstanceNotInitialized
    }
    
}
