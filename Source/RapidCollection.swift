//
//  Collection.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class RapidCollection: NSObject {
    
    weak var handler: RapidHandler?
    
    let collectionID: String

    init(id: String, handler: RapidHandler) {
        self.collectionID = id
        self.handler = handler
    }
    
    public func newDocument() -> RapidDocument {
        return document(id: Rapid.uniqueID)
    }
    
    public func document(id: String) -> RapidDocument {
        return try! document(withID: id)
    }
    
    func document(withID id: String) throws -> RapidDocument {
        if let handler = handler {
            return RapidDocument(id: id, inCollection: collectionID, handler: handler)
        }
        else {
            print(RapidError.rapidInstanceNotInitialized.message)
            throw RapidError.rapidInstanceNotInitialized
        }
    }
}
