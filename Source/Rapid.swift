//
//  Rapid.swift
//  Rapid
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//
//  swiftlint:disable force_try

import Foundation

public class Rapid: NSObject {
    
    let socketManager: SocketManager
    
    static var sharedInstance: Rapid?
    
    fileprivate var collections: [RapidCollection] = []
    
    public init(apiKey: String) {
        socketManager = SocketManager(apiKey: apiKey)
    }
    
    public func collection(named: String) -> RapidCollection {
        let collection = RapidCollection(id: named, inRapid: self)
        collections.append(collection)
        return collection
    }
}

// MARK: Class methods
extension Rapid {
    
    class func shared() throws -> Rapid {
        if let shared = sharedInstance {
            return shared
        }
        else {
            throw RapidError.mainInstanceNotInitialized
        }
    }
    
}

// MARK: Singleton methods
public extension Rapid {
    
    public class var uniqueID: String {
        return NSUUID().uuidString
    }
    
    public class func configure(withAPIKey key: String) {
        sharedInstance = Rapid(apiKey: key)
    }
    
    public class func collection(named: String) -> RapidCollection {
        return try! shared().collection(named: named)
    }
}
