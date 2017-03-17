//
//  RapidMutateProtocol.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public typealias RapidMutationCallback = (_ error: Error?, _ object: Any?) -> Void

protocol MutationRequest: RapidRequest {
    func mutationJSON(withEventID eventID: String) -> [AnyHashable: Any]
}

class RapidDocumentMutation: NSObject, MutationRequest {
    
    let value: [AnyHashable: Any]?
    let collectionID: String
    let documentID: String
    let callback: RapidMutationCallback?
    
    init(collectionID: String, documentID: String, value: [AnyHashable: Any]?, callback: RapidMutationCallback?) {
        self.value = value
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
    }
    
    func mutationJSON(withEventID eventID: String) -> [AnyHashable : Any] {
        var json = [AnyHashable: Any]()
        
        json["evt-id"] = eventID
        json["col-id"] = collectionID
        //json["doc-id"] = documentID
        var doc = value
        doc?["id"] = documentID
        json["doc"] = doc
        
        return json
    }
}

extension RapidDocumentMutation: RapidRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        callback?(nil, value)
    }
    
    func eventFailed(withError error: RapidSocketError) {
        callback?(error, nil)
    }
}
