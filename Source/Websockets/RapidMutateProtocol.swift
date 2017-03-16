//
//  RapidMutateProtocol.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public typealias RapidMutationCallback = (_ error: Error?, _ object: Any?) -> Void

protocol MutationEntity {
    func mutationJSON(withEventID eventID: String) -> [AnyHashable: Any]
}

class RapidDocumentMutation: NSObject, MutationEntity {
    
    let value: [AnyHashable: Any]?
    let collectionID: String
    let documentID: String
    
    init(collectionID: String, documentID: String, value: [AnyHashable: Any]?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
    }
    
    func mutationJSON(withEventID eventID: String) -> [AnyHashable : Any] {
        var json = [AnyHashable: Any]()
        
        json["evt-id"] = eventID
        json["col-id"] = collectionID
        json["doc-id"] = documentID
        json["doc"] = value
        
        return json
    }
}
