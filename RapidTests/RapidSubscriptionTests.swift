//
//  RapidSubscriptionTests.swift
//  Rapid
//
//  Created by Jan Schwarz on 27/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testCollectionSubscription() {
        Rapid.configure(withAPIKey: apiKey)
        
        let subscription = Rapid.collection(named: "users").subscribe { (_, _) in
        }
        
        if let sub = subscription as? RapidCollectionSub {
            let json: [AnyHashable: Any] = [
                "sub": [
                    "col-id": sub.collectionID
                ]
            ]
            
            do {
                let comparison = try sub.serialize(withIdentifiers: [:]).json() ?? [:]
                
                if !(comparison == json) {
                    XCTFail("Subscription wrongly serialized")
                }
            }
            catch {
            }
        }
        else {
            XCTFail("Subscription of wrong type")
        }
    }
    
    func testMultiArgumentNotFilter() {
        let filter = RapidFilterCompound(compoundOperator: .not, operands: [
            RapidFilterSimple(key: "id", relation: .equal, value: "1"),
            RapidFilterSimple(key: "text", relation: .equal, value: "text")
            ])
        
        XCTAssertNil(filter, "Filter not nil")
    }
    
    func testEmptyFilter() {
        let filter = RapidFilterCompound(compoundOperator: .and, operands: [])
        
        XCTAssertNil(filter, "Filter not nil")
    }
    
    func testSubscriptionFilter() {
        Rapid.configure(withAPIKey: apiKey)
        
        let subscription = Rapid.collection(named: "users")
            .filter(by: RapidFilterSimple(key: "text", relation: .equal, value: "texty text"))
            .subscribe { (_, _) in
        }
        
        if let sub = subscription as? RapidCollectionSub {
            let json: [AnyHashable: Any] = [
                "sub": [
                    "col-id": sub.collectionID,
                    "filter": ["text": "texty text"]
                ]
            ]
            
            do {
                let comparison = try sub.serialize(withIdentifiers: [:]).json() ?? [:]
                
                if !(comparison == json) {
                    XCTFail("Subscription wrongly serialized")
                }
            }
            catch {
            }
        }
        else {
            XCTFail("Subscription of wrong type")
        }
    }
    
    func testSubscriptionComplexFilter() {
        Rapid.configure(withAPIKey: apiKey)
        
        let subscription = Rapid.collection(named: "users")
            .filter(by:
                RapidFilterCompound(compoundOperator: .and, operands: [
                    RapidFilterCompound(compoundOperator: .or, operands: [
                        RapidFilterSimple(key: "sender", relation: .equal, value: "john123"),
                        RapidFilterSimple(key: "urgency", relation: .greaterThanOrEqual, value: 1),
                        RapidFilterSimple(key: "priority", relation: .lessThanOrEqual, value: 2)
                        ])!,
                    RapidFilterCompound(compoundOperator: .not, operands: [RapidFilterSimple(key: "receiver", relation: .equal, value: nil)])!
                    ])!)
            .order(by: [
                RapidOrdering(key: "sentDate", ordering: .descending),
                RapidOrdering(key: "urgency", ordering: .ascending)
                ])
            .limit(to: 50, skip: 10)
            .subscribe { (_, _) in
        }
        
        if let sub = subscription as? RapidCollectionSub {
            let json: [AnyHashable: Any] = [
                "sub": [
                    "col-id": sub.collectionID,
                    "filter": [
                        "and": [
                            [
                                "or": [
                                    ["sender": "john123"],
                                    ["urgency": ["gte": 1]],
                                    ["priority": ["lte": 2]]
                                ]
                            ],
                            [
                                "not": ["receiver": NSNull()]
                            ]
                        ]
                    ],
                    "order": [
                        ["sentDate": "desc"],
                        ["urgency": "asc"]
                    ],
                    "limit": 50,
                    "skip": 10
                ]
            ]
            
            do {
                let comparison = try sub.serialize(withIdentifiers: [:]).json() ?? [:]

                if !(comparison == json) {
                    XCTFail("Subscription wrongly serialized")
                }
            }
            catch {
            }
        }
        else {
            XCTFail("Subscription of wrong type")
        }
    }
    
    func testDuplicateSubscriptions() {
        Rapid.configure(withAPIKey: apiKey)
        
        guard let sub1 = Rapid.collection(named: "users").document(withID: "1").subscribe(completion: { (_, _) in }) as? RapidDocumentSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        guard let sub2 = Rapid.collection(named: "users").filter(by: RapidFilterSimple(key: RapidFilterSimple.documentIdKey, relation: .equal, value: "1")).subscribe(completion: { (_, _) in }) as? RapidCollectionSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        do {
            let handler1 = try Rapid.shared().handler.socketManager.activeSubscription(withHash: sub1.subscriptionHash)
            let handler2 = try Rapid.shared().handler.socketManager.activeSubscription(withHash: sub2.subscriptionHash)
            
            XCTAssertEqual(handler1, handler2, "Different handlers for same subscription")
        }
        catch {
            XCTFail("Rapid instance not initialized")
        }
    }

}
