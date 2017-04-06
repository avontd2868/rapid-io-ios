//
//  RapidQueryTests.swift
//  Rapid
//
//  Created by Jan on 05/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testParameterValidation() {
        XCTAssertTrue(Validator.isValid(parameterName: "name"), "Parameter name")
        XCTAssertTrue(Validator.isValid(parameterName: "$name"), "Parameter name")
        XCTAssertTrue(Validator.isValid(parameterName: "name.name"), "Parameter name")
        XCTAssertTrue(Validator.isValid(parameterName: "_n-a_m-e_1"), "Parameter name")
        XCTAssertFalse(Validator.isValid(parameterName: "name."), "Parameter name")
        XCTAssertFalse(Validator.isValid(parameterName: "name$"), "Parameter name")
        XCTAssertFalse(Validator.isValid(parameterName: "name.name.name"), "Parameter name")
    }
    
    func testJSONValidation() {
        let sub1 = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter.and([
                RapidFilter.or([
                    RapidFilter.equal(key: "$sender", value: "john123"),
                    RapidFilter.greaterThanOrEqual(key: "max_urgency", value: 1),
                    RapidFilter.lessThanOrEqual(key: "min-priority", value: 2)
                    ]),
                RapidFilter.not(RapidFilter.isNull(key: "receiver"))
                ]),
            ordering: [RapidOrdering(key: "sentDate", ordering: .descending)],
            paging: RapidPaging(skip: 10, take: 50),
            callback: nil,
            callbackWithChanges: nil)
        
        let mut = RapidDocumentMutation(collectionID: testCollectionName, documentID: "1", value: ["name": self], callback: nil)
        
        let sub2 = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter.equal(key: "$sender.blender.hu", value: "john123"),
            ordering: nil,
            paging: nil,
            callback: nil,
            callbackWithChanges: nil)
        
        let sub3 = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: nil,
            ordering: [RapidOrdering(key: "&sentDate", ordering: .descending)],
            paging: nil,
            callback: nil,
            callbackWithChanges: nil)
        
        XCTAssertNoThrow(try sub1.serialize(withIdentifiers: [:]), "JSON validation")
        XCTAssertThrowsError(try mut.serialize(withIdentifiers: [:]), "JSON validation")
        XCTAssertThrowsError(try sub2.serialize(withIdentifiers: [:]), "JSON validation")
        XCTAssertThrowsError(try sub3.serialize(withIdentifiers: [:]), "JSON validation")
        
    }
    
    func testCollectionSubscription() {
        let subscription = RapidCollectionSub(collectionID: "users", filter: nil, ordering: nil, paging: nil, callback: nil, callbackWithChanges: nil)
        
        let json: [AnyHashable: Any] = [
            "sub": [
                "col-id": subscription.collectionID
            ]
        ]
        
        do {
            let comparison = try subscription.serialize(withIdentifiers: [:]).json() ?? [:]
            
            if !(comparison == json) {
                XCTFail("Subscription wrongly serialized")
            }
        }
        catch {
            XCTFail("Serialization failed")
        }
    }
    
    func testSubscriptionFilter() {
        let collection = self.rapid.collection(named: "users")
            .filter(by: RapidFilterSimple(key: "text", relation: .equal, value: "texty text"))
        
        let sub = RapidCollectionSub(collectionID: collection.collectionID, filter: collection.subscriptionFilter, ordering: collection.subscriptionOrdering, paging: collection.subscriptionPaging, callback: nil, callbackWithChanges: nil)
        
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
            XCTFail("Serialization failed")
        }
    }
    
    func testSubscriptionComplexFilter() {
        let collection = self.rapid.collection(named: "users")
            .filter(by:
                RapidFilterCompound.and([
                    RapidFilterCompound.or([
                        RapidFilter.equal(key: "sender", value: "john123"),
                        RapidFilterSimple.greaterThanOrEqual(key: "urgency", value: 1),
                        RapidFilterSimple.lessThanOrEqual(key: "priority", value: 2)
                        ]),
                    RapidFilter.not(RapidFilter.isNull(key: "receiver"))
                    ]))
            .filter(by:
                RapidFilter.and([
                    RapidFilter.greaterThan(key: "urgency", value: 2),
                    RapidFilter.lessThan(key: "urgency", value: 4)
                ]))
            .order(by: [
                RapidOrdering(key: "sentDate", ordering: .descending)
                ])
            .order(by:
                RapidOrdering(key: "urgency", ordering: .ascending)
                )
            .limit(to: 50, skip: 10)
        
        let sub = RapidCollectionSub(collectionID: collection.collectionID, filter: collection.subscriptionFilter, ordering: collection.subscriptionOrdering, paging: collection.subscriptionPaging, callback: nil, callbackWithChanges: nil)
        
        let json: [AnyHashable: Any] = [
            "sub": [
                "col-id": sub.collectionID,
                "filter": [
                    "and": [
                        [
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
                        [
                            "and": [
                                ["urgency": ["gt": 2]],
                                ["urgency": ["lt": 4]]
                            ]
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
            XCTFail("Serialization failed")
        }
    }
    
    func testEmptyAndFilter() {
        let promise = expectation(description: "Empty compound filter")
        
        self.rapid.collection(named: testCollectionName).filter(by: RapidFilter.and([])).subscribe { (error, _) in
            if let error = error as? RapidError, case .invalidData = error {
                promise.fulfill()
            }
            else {
                XCTFail("Dictionary valid")
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testEmptyOrFilter() {
        let promise = expectation(description: "Empty compound filter")
        
        self.rapid.collection(named: testCollectionName).filter(by: RapidFilter.or([])).subscribe { (error, _) in
            if let error = error as? RapidError, case .invalidData = error {
                promise.fulfill()
            }
            else {
                XCTFail("Dictionary valid")
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
