//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

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
        socketManager.sendMutation(mutationRequest: mutation)
    }
    
    public func merge(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        //TODO: Implement merge
    }
    
    public func delete(completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collectionID, documentID: documentID, value: nil, callback: completion)
        socketManager.sendMutation(mutationRequest: mutation)
    }
}

extension RapidDocument {
    
    func getSocketManager() throws -> SocketManager {
        if let manager = handler?.socketManager {
            return manager
        }
        else {
            print(RapidError.rapidInstanceNotInitialized.message)
            throw RapidError.rapidInstanceNotInitialized
        }
    }
}
