//
//  RapidSubscription.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public typealias RapidColSubCallback = (_ error: Error?, _ value: [Any]) -> Void
public typealias RapidColSubCallbackWithChanges = (_ error: Error?, _ value: [Any], _ added: [Any], _ updated: [Any], _ deleted: [Any]) -> Void

func == <T: RapidSubscription>(lhs: T, rhs: T) -> Bool {
    return lhs.hash == rhs.hash
}

protocol RapidSubscription: Equatable, RapidSerializable {
    var hash: String { get }
}

struct RapidCollectionSub: RapidSubscription {
    
    var hash: String {
        return collectionID
    }
    
    let collectionID: String
    let filter: RapidFilter?
    let ordering: [RapidOrdering]?
    let paging: RapidPaging?
    let callBack: RapidColSubCallback?
    let callBackWithChanges: RapidColSubCallbackWithChanges?
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(subscription: self, withIdentifiers: identifiers)
    }
}
