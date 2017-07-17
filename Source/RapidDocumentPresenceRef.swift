//
//  RapidDocumentPresenceRef.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: On connect
open class RapidDocumentOnConnectedRef: NSObject, RapidInstanceWithSocketManager {
    
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

extension RapidDocumentOnConnectedRef: RapidMutationReference {
    
    @discardableResult
    open func mutate(value: [AnyHashable: Any], completion: RapidDocumentMutationCompletion? = nil) -> RapidWriteRequest {
        let mutation = RapidDocumentOnConnectMutation(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnConnectAction(mutation)
        return mutation
    }
    
}

extension RapidDocumentOnConnectedRef: RapidMergeReference {
    
    @discardableResult
    open func merge(value: [AnyHashable: Any], completion: RapidDocumentMergeCompletion? = nil) -> RapidWriteRequest {
        let merge = RapidDocumentOnConnectMerge(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnConnectAction(merge)
        return merge
    }
    
}

extension RapidDocumentOnConnectedRef: RapidDeletionReference {
    
    @discardableResult
    open func delete(completion: RapidDocumentDeletionCompletion? = nil) -> RapidWriteRequest {
        let deletion = RapidDocumentOnConnectDelete(collectionID: collectionName, documentID: documentID, completion: completion)
        socketManager.registerOnConnectAction(deletion)
        return deletion
    }
    
}

// MARK: On disconnect
open class RapidDocumentOnDisconnectedRef: NSObject, RapidInstanceWithSocketManager {
    
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

extension RapidDocumentOnDisconnectedRef: RapidMutationReference {
    
    @discardableResult
    open func mutate(value: [AnyHashable: Any], completion: RapidDocumentMutationCompletion? = nil) -> RapidWriteRequest {
        let mutation = RapidDocumentOnDisconnectMutation(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnDisconnectAction(mutation)
        return mutation
    }
    
}

extension RapidDocumentOnDisconnectedRef: RapidMergeReference {
    
    @discardableResult
    open func merge(value: [AnyHashable: Any], completion: RapidDocumentMergeCompletion? = nil) -> RapidWriteRequest {
        let merge = RapidDocumentOnDisconnectMerge(collectionID: collectionName, documentID: documentID, value: value, completion: completion)
        socketManager.registerOnDisconnectAction(merge)
        return merge
    }
    
}

extension RapidDocumentOnDisconnectedRef: RapidDeletionReference {
    
    @discardableResult
    open func delete(completion: RapidDocumentDeletionCompletion? = nil) -> RapidWriteRequest {
        let deletion = RapidDocumentOnDisconnectDelete(collectionID: collectionName, documentID: documentID, completion: completion)
        socketManager.registerOnDisconnectAction(deletion)
        return deletion
    }
    
}
