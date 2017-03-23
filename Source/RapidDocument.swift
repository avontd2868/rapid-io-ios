//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class RapidDocumentSnapshot {
    
    public let id: String
    public let value: [AnyHashable: Any]?
    let predecessorID: String?
    
    init?(json: Any?) {
        guard let dict = json as? [AnyHashable: Any] else {
            return nil
        }
        
        guard let id = dict[RapidSerialization.Document.DocumentID.name] as? String else {
            return nil
        }
        
        let body = dict[RapidSerialization.Document.Body.name] as? [AnyHashable: Any]
        let predecessor = dict[RapidSerialization.Document.Predecessor.name] as? String
        
        self.id = id
        self.value = body
        self.predecessorID = predecessor
    }
    
    init(id: String, value: [AnyHashable: Any]?) {
        self.id = id
        self.value = value
        self.predecessorID = nil
    }
    
}

public class RapidDocument: NSObject {
    
    weak var handler: RapidHandler?
    var socketManager: SocketManager {
        return try! getSocketManager()
    }
    
    let collectionID: String
    let documentID: String
    
    init(id: String, inCollection collectionID: String, handler: RapidHandler) {
        self.documentID = id
        self.collectionID = collectionID
        self.handler = handler
    }
    
    public func mutate(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: value, callback: completion)
        socketManager.mutate(mutationRequest: mutation)
    }
    
    public func merge(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        //TODO: Implement merge
    }
    
    public func delete(completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: nil, callback: completion)
        socketManager.mutate(mutationRequest: mutation)
    }
    
    @discardableResult
    public func subscribe(completion: @escaping RapidDocSubCallback) -> RapidSubscription {
        let subscription = RapidDocumentSub(collectionID: collectionID, documentID: documentID, callback: completion)
        
        socketManager.subscribe(subscription)
        
        return subscription
    }
    
}

extension RapidDocument {
    
    func getSocketManager() throws -> SocketManager {
        if let manager = handler?.socketManager {
            return manager
        }
        else {
            print(RapidInternalError.rapidInstanceNotInitialized.message)
            throw RapidInternalError.rapidInstanceNotInitialized
        }
    }
}
