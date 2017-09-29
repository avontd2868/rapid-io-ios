//
//  RapidDocumentPresenceRef.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: On connect

/// Register on-connect action completion handler which informs a client about the operation result
public typealias RapidDocumentRegisterOnConnectActionCompletion = (_ result: RapidResult<Any?>) -> Void

/// Rapid.io document reference
///
/// `RapidDocumentRefOnConnect` is used to register actions that should be performed
/// when `Rapid` instance connects to a server
public struct RapidDocumentRefOnConnect: RapidInstanceWithSocketManager {
    
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
    
}

extension RapidDocumentRefOnConnect: RapidMutationReference {
    
    /// Mutate the document once the instance connects to a server
    ///
    /// All values in the document are deleted and replaced by values in the provided dictionary
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - completion: Mutation completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    public func mutate(value: [String: Any], completion: RapidDocumentRegisterOnConnectActionCompletion? = nil) -> RapidWriteRequest {
        let mutation = RapidDocumentOnConnectMutation(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnConnectAction(mutation)
        return mutation
    }
    
}

extension RapidDocumentRefOnConnect: RapidMergeReference {
    
    /// Merge values in the document with values in a provided dictionary
    /// once the instance connects to a server
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
    public func merge(value: [String: Any], completion: RapidDocumentRegisterOnConnectActionCompletion? = nil) -> RapidWriteRequest {
        let merge = RapidDocumentOnConnectMerge(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnConnectAction(merge)
        return merge
    }
    
}

extension RapidDocumentRefOnConnect: RapidDeletionReference {
    
    /// Delete the document once the instance connects to a server
    ///
    /// - Parameter completion: Deletion completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    public func delete(completion: RapidDocumentRegisterOnConnectActionCompletion? = nil) -> RapidWriteRequest {
        let deletion = RapidDocumentOnConnectDelete(collectionID: collectionName, documentID: documentID, completion: completion)
        socketManager.registerOnConnectAction(deletion)
        return deletion
    }
    
}

// MARK: On disconnect

/// Register on-disconnect action completion handler which informs a client about the operation result
public typealias RapidDocumentRegisterOnDisonnectActionCompletion = (_ result: RapidResult<Any?>) -> Void

/// Rapid.io document reference
///
/// `RapidDocumentRefOnDisconnect` is used to register actions that should be performed
/// when `Rapid` instance disconnects from a server
public struct RapidDocumentRefOnDisconnect: RapidInstanceWithSocketManager {
    
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
    
}

extension RapidDocumentRefOnDisconnect: RapidMutationReference {
    
    /// Mutate the document once the instance disconnects from a server
    ///
    /// All values in the document are deleted and replaced by values in the provided dictionary
    ///
    /// - Parameters:
    ///   - value: Dictionary with new values that the document should contain
    ///   - completion: Mutation completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    public func mutate(value: [String: Any], completion: RapidDocumentRegisterOnDisonnectActionCompletion? = nil) -> RapidWriteRequest {
        let mutation = RapidDocumentOnDisconnectMutation(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnDisconnectAction(mutation)
        return mutation
    }
    
}

extension RapidDocumentRefOnDisconnect: RapidMergeReference {
    
    /// Merge values in the document with values in a provided dictionary
    /// once the instance disconnects from a server
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
    public func merge(value: [String: Any], completion: RapidDocumentRegisterOnDisonnectActionCompletion? = nil) -> RapidWriteRequest {
        let merge = RapidDocumentOnDisconnectMerge(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnDisconnectAction(merge)
        return merge
    }
    
}

extension RapidDocumentRefOnDisconnect: RapidDeletionReference {
    
    /// Delete the document once the instance disconnects from a server
    ///
    /// - Parameter completion: Deletion completion handler which provides a client with an error if any error occurs
    /// - Returns: `RapidWriteRequest` instance
    @discardableResult
    public func delete(completion: RapidDocumentRegisterOnDisonnectActionCompletion? = nil) -> RapidWriteRequest {
        let deletion = RapidDocumentOnDisconnectDelete(collectionID: collectionName, documentID: documentID, completion: completion)
        socketManager.registerOnDisconnectAction(deletion)
        return deletion
    }
    
}
