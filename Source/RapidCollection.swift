//
//  Collection.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class RapidCollection: NSObject {
    
    let collectionID: String
    unowned let rapid: Rapid
    
    fileprivate var documents: [RapidDocument] = []
    
    init(id: String, inRapid rapid: Rapid) {
        self.collectionID = id
        self.rapid = rapid
    }
    
    public func newDocument() -> RapidDocument {
        return document(id: Rapid.uniqueID)
    }
    
    public func document(id: String) -> RapidDocument {
        let document = RapidDocument(id: id, inCollection: self)
        documents.append(document)
        return document
    }
}
