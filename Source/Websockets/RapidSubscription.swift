//
//  RapidSubscription.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public typealias RapidDocSubCallback = (_ error: Error?, _ value: RapidDocumentSnapshot) -> Void
public typealias RapidColSubCallback = (_ error: Error?, _ value: [RapidDocumentSnapshot]) -> Void
public typealias RapidColSubCallbackWithChanges = (_ error: Error?, _ value: [RapidDocumentSnapshot], _ added: [RapidDocumentSnapshot], _ updated: [RapidDocumentSnapshot], _ deleted: [RapidDocumentSnapshot]) -> Void

protocol RapidSubscriptionInstance: class, RapidSerializable {
    var subscriptionHash: String { get }
    
    func receivedNewValue(_ value: [RapidDocumentSnapshot], oldValue: [RapidDocumentSnapshot]?)
    func subscriptionFailed(withError error: RapidError)
    func registerUnsubscribeCallback(_ callback: @escaping (RapidSubscriptionInstance) -> Void)
}

public protocol RapidSubscription {
    func unsubscribe()
}

class RapidCollectionSub: NSObject {
    
    let collectionID: String
    let filter: RapidFilter?
    let ordering: [RapidOrdering]?
    let paging: RapidPaging?
    let callback: RapidColSubCallback?
    let callbackWithChanges: RapidColSubCallbackWithChanges?
    
    fileprivate var unsubscribeCallback: ((RapidSubscriptionInstance) -> Void)?
    
    init(collectionID: String, filter: RapidFilter?, ordering: [RapidOrdering]?, paging: RapidPaging?, callback: RapidColSubCallback?, callbackWithChanges: RapidColSubCallbackWithChanges?) {
        self.collectionID = collectionID
        self.filter = filter
        self.ordering = ordering
        self.paging = paging
        self.callback = callback
        self.callbackWithChanges = callbackWithChanges
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(subscription: self, withIdentifiers: identifiers)
    }
    
}

fileprivate extension RapidCollectionSub {
    
    func incorporateChanges(newValue: [RapidDocumentSnapshot], oldValue: [RapidDocumentSnapshot]?) -> (dataSet: [RapidDocumentSnapshot], insert: [RapidDocumentSnapshot], update: [RapidDocumentSnapshot], delete: [RapidDocumentSnapshot]) {
        guard var documents = oldValue else {
            let dataSet = newValue.flatMap({ $0.value == nil ? nil : $0 })
            return (dataSet, dataSet, [], [])
        }
        
        var inserted = [RapidDocumentSnapshot]()
        var updated = [RapidDocumentSnapshot]()
        var deleted = [RapidDocumentSnapshot]()
        
        for value in newValue {
            let index = documents.index(where: { $0.id == value.id })
            
            if let index = index, value.value == nil {
                let document = documents.remove(at: index)
                deleted.append(document)
            }
            else if let predID = value.predecessorID, let predIndex = documents.index(where: { $0.id == predID }) {
                if let index = index {
                    documents.remove(at: index)
                    let newIndex = predIndex < index ? predIndex + 1 : predIndex
                    documents.insert(value, at: newIndex)
                    updated.append(value)
                }
                else {
                    documents.insert(value, at: predIndex + 1)
                    inserted.append(value)
                }
            }
            else if let index = index {
                documents.remove(at: index)
                documents.insert(value, at: 0)
                updated.append(value)
            }
            else {
                documents.insert(value, at: 0)
                inserted.append(value)
            }
        }
        
        return (documents, inserted, updated, deleted)
    }
    
}

extension RapidCollectionSub: RapidSubscriptionInstance {
    
    var subscriptionHash: String {
        return "\(collectionID)#\(filter?.filterHash ?? "")#\(ordering?.map({ $0.orderingHash }).joined(separator: "|") ?? "")#\(paging?.pagingHash ?? "")"
    }
    
    func subscriptionFailed(withError error: RapidError) {
        callback?(error, [])
        callbackWithChanges?(error, [], [], [], [])
    }
    
    func registerUnsubscribeCallback(_ callback: @escaping (RapidSubscriptionInstance) -> Void) {
        unsubscribeCallback = callback
    }

    func receivedNewValue(_ value: [RapidDocumentSnapshot], oldValue: [RapidDocumentSnapshot]?) {
        let changes = incorporateChanges(newValue: value, oldValue: oldValue)
        
        callback?(nil, changes.dataSet)
        callbackWithChanges?(nil, changes.dataSet, changes.insert, changes.update, changes.delete)
        
    }
}

extension RapidCollectionSub: RapidSubscription {
    
    func unsubscribe() {
        unsubscribeCallback?(self)
    }
    
}

// MARK: Document subscription
class RapidDocumentSub: NSObject {
    
    let collectionID: String
    let documentID: String
    let callback: RapidDocSubCallback?
    fileprivate(set) var subscription: RapidCollectionSub!

    init(collectionID: String, documentID: String, callback: RapidDocSubCallback?) {
        self.collectionID = collectionID
        self.documentID = documentID
        self.callback = callback
        
        super.init()
        
        self.subscription = RapidCollectionSub(collectionID: collectionID, filter: RapidFilterSimple(key: RapidFilterSimple.documentIdKey, relation: .equal, value: documentID), ordering: nil, paging: nil, callback: { [weak self] (error, documents) in
            let document = documents.last ?? RapidDocumentSnapshot(id: documentID, value: nil)
            self?.callback?(error, document)
        }, callbackWithChanges: nil)
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try subscription.serialize(withIdentifiers: identifiers)
    }

}

extension RapidDocumentSub: RapidSubscriptionInstance {
    
    var subscriptionHash: String {
        return subscription.subscriptionHash
    }
    
    func subscriptionFailed(withError error: RapidError) {
        subscription.subscriptionFailed(withError: error)
    }
    
    func registerUnsubscribeCallback(_ callback: @escaping (RapidSubscriptionInstance) -> Void) {
        subscription.registerUnsubscribeCallback(callback)
    }
    
    func receivedNewValue(_ value: [RapidDocumentSnapshot], oldValue: [RapidDocumentSnapshot]?) {
        subscription.receivedNewValue(value, oldValue: oldValue)
    }
}

extension RapidDocumentSub: RapidSubscription {
    
    func unsubscribe() {
        subscription?.unsubscribe()
    }
}
