//
//  RapidDocument.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class RapidDocument: NSObject {
    
    unowned let collection: RapidCollection
    let documentID: String
    
    init(id: String, inCollection collection: RapidCollection) {
        self.documentID = id
        self.collection = collection
    }
    
    public func mutate(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collection.collectionID, documentID: documentID, value: value)
        collection.rapid.socketManager.sendMutation(forObject: mutation, withCompletion: completion)
    }
    
    public func merge(value: [AnyHashable: Any], completion: RapidMutationCallback? = nil) {
        //TODO: Implement merge
    }
    
    public func delete(completion: RapidMutationCallback? = nil) {
        let mutation = RapidDocumentMutation(collectionID: collection.collectionID, documentID: documentID, value: nil)
        collection.rapid.socketManager.sendMutation(forObject: mutation, withCompletion: completion)
    }
}
