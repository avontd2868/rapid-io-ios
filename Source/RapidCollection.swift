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
    var socketManager: SocketManager {
        return try! getSocketManager()
    }
    
    public let collectionID: String
    public fileprivate(set) var filter: RapidFilter?
    public fileprivate(set) var ordering: [RapidOrdering]?
    public fileprivate(set) var paging: RapidPaging?

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
    
    public func filter(by filter: RapidFilter) -> RapidCollection {
        if let previousFilter = self.filter {
            let compoundFilter = RapidFilterCompound(compoundOperator: .and, operands: [previousFilter, filter])
            self.filter = compoundFilter
        }
        else {
            self.filter = filter
        }
        return self
    }
    
    public func order(by ordering: [RapidOrdering]) -> RapidCollection {
        if self.ordering == nil {
            self.ordering = []
        }
        self.ordering?.append(contentsOf: ordering)
        return self
    }
    
    public func limit(to take: Int, skip: Int? = nil) -> RapidCollection {
        
        self.paging = RapidPaging(skip: skip, take: take)
        return self
    }
    
    public func subscribe(completion: @escaping RapidColSubCallback) -> Int {
        let subscription = RapidCollectionSub(collectionID: collectionID, filter: filter, ordering: ordering, paging: paging, callBack: completion, callBackWithChanges: nil)
        
        socketManager.subscribe(subscription)
        
        return 0
    }
    
    public func subscribe(completionWithChanges completion: @escaping RapidColSubCallbackWithChanges) -> Int {
        let subscription = RapidCollectionSub(collectionID: collectionID, filter: filter, ordering: ordering, paging: paging, callBack: nil, callBackWithChanges: completion)
        
        socketManager.subscribe(subscription)
        
        return 0
    }
}

extension RapidCollection {
    
    func document(withID id: String) throws -> RapidDocument {
        if let handler = handler {
            return RapidDocument(id: id, inCollection: collectionID, handler: handler)
        }
        else {
            print(RapidError.rapidInstanceNotInitialized.message)
            throw RapidError.rapidInstanceNotInitialized
        }
    }
    
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
