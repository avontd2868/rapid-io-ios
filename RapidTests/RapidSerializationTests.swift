//
//  RapidQueryTests.swift
//  Rapid
//
//  Created by Jan on 05/04/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testJSONString() {
        let dict = ["object": self]
        
        XCTAssertThrowsError(try dict.jsonString())
    }
    
    func testParseNil() {
        XCTAssertNil(RapidSerialization.parse(json: nil), "Nil parsed")
    }
    
    func testParseUnknownEvents() {
        XCTAssertNil(RapidSerialization.parse(json: [:]), "Parsed empty dictionary")
        XCTAssertNil(RapidSerialization.parse(json: ["jkldsf": ["name": "test"]]), "Parsed unknown event")
    }
    
    func testJSONValidationInvalidValue() {
        let mut = RapidDocumentMutation(collectionID: testCollectionName, documentID: "1", value: ["name": self], cache: nil, completion: nil)
        
        XCTAssertThrowsError(try mut.serialize(withIdentifiers: [:]), "JSON validation")
    }
    
    func testJSONValidationInvalidKeyPath() {
        let sub = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter.equal(keyPath: "sender.hu.", value: "john123"),
            ordering: nil,
            paging: nil,
            handler: nil,
            handlerWithChanges: nil)
        
        XCTAssertThrowsError(try sub.serialize(withIdentifiers: [:]), "JSON validation")
    }
    
    func testJSONValidationValidParameters() {
        let sub1 = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter.and([
                RapidFilter.or([
                    RapidFilter.equal(keyPath: "$sender", value: "john123"),
                    RapidFilter.greaterThanOrEqual(keyPath: "max_urgency", value: 1),
                    RapidFilter.lessThanOrEqual(keyPath: "min-priority", value: 2)
                    ]),
                RapidFilter.not(RapidFilter.isNull(keyPath: "receiver"))
                ]),
            ordering: [RapidOrdering(keyPath: "sentDate", ordering: .descending)],
            paging: RapidPaging(take: 50),
            handler: nil,
            handlerWithChanges: nil)
        
        let sub2 = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter.equal(keyPath: "sender.hu", value: "john123"),
            ordering: nil,
            paging: nil,
            handler: nil,
            handlerWithChanges: nil)
        
        XCTAssertNoThrow(try sub1.serialize(withIdentifiers: [:]), "JSON validation")
        XCTAssertNoThrow(try sub2.serialize(withIdentifiers: [:]), "JSON validation")
    }
    
    func testJSONValidationInvalidIDParameter() {
        let sub = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: 3),
            ordering: nil,
            paging: nil,
            handler: nil,
            handlerWithChanges: nil)
        
        XCTAssertThrowsError(try sub.serialize(withIdentifiers: [:]), "JSON validation")
    }
    
    func testInvalidSimpleFilter() {
        let sub = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: RapidFilter(keyPath: "name", relation: .greaterThanOrEqual),
            ordering: nil,
            paging: nil,
            handler: nil,
            handlerWithChanges: nil)
        
        XCTAssertThrowsError(try sub.serialize(withIdentifiers: [:]), "JSON validation")
    }
    
    func testInvalidOrderingKeyPath() {
        let sub = RapidCollectionSub(
            collectionID: testCollectionName,
            filter: nil,
            ordering: [RapidOrdering(keyPath: "name.", ordering: .ascending)],
            paging: nil,
            handler: nil,
            handlerWithChanges: nil)
        
        XCTAssertThrowsError(try sub.serialize(withIdentifiers: [:]), "JSON validation")
    }
    
    func testEventBatch() {
        let subID = Rapid.uniqueID
        
        let batch: [AnyHashable: Any] = [
            "batch": [
                [
                    "ack": [
                        "evt-id": Rapid.uniqueID
                    ]
                ],
                [
                    "err": [
                        "evt-id": Rapid.uniqueID,
                        "err-type": "permission-denied",
                        "err-msg": "Test message"
                    ]
                ],
                [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "doc":
                            [
                                "id": "1",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "etag": Rapid.uniqueID,
                                "crt": "",
                                "body": [
                                    "name": "testy"
                                ]
                        ]
                    ]
                ],
                [
                    "val": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "docs": [
                            [
                                "id": "1",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "crt": "",
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test"
                                ]
                            ],
                            [
                                "id": "2",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "crt": "",
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test"
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "doc":
                            [
                                "id": "1",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "crt": "",
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "testy"
                                ]
                        ]
                    ]
                ],
                [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "psib-id": "1",
                        "doc":
                            [
                                "id": "2",
                                "crt-ts": 0.0,
                                "crt": "",
                                "mod-ts": 0.0,
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "testy"
                                ]
                        ]
                    ]
                ],
                [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": Rapid.uniqueID,
                        "doc":
                            [
                                "id": "2",
                                "crt-ts": 0.0,
                                "crt": "",
                                "mod-ts": 0.0,
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "testy"
                                ]
                        ]
                    ]
                ]
            ]
        ]
        
        let responses = RapidSerialization.parse(json: batch) ?? []
        
        XCTAssertEqual(responses.count, 4, "Number of responses")
        
        if !(responses[0] is RapidServerAcknowledgement) {
            XCTFail("Not an acknowledgement")
        }
        
        if let error = responses[1] as? RapidErrorInstance, case RapidError.permissionDenied(let message) = error.error {
            XCTAssertEqual(message, "Test message", "Error message")
        }
        else {
            XCTFail("Wrong error")
        }
        
        if let batch = responses[2] as? RapidSubscriptionBatch {
            XCTAssertEqual(batch.subscriptionID, subID, "Subscription batch")
            XCTAssertNotNil(batch.collection, "Subscription batch")
            XCTAssertEqual(batch.updates.count, 2, "Subscription batch")
        }
        else {
            XCTFail("Wrong response")
        }
        
        if let batch = responses[3] as? RapidSubscriptionBatch {
            XCTAssertNil(batch.collection, "Subscription batch")
            XCTAssertEqual(batch.updates.count, 1, "Subscription batch")
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testCollectionSubscription() {
        let subscription = RapidCollectionSub(collectionID: "users", filter: nil, ordering: nil, paging: nil, handler: nil, handlerWithChanges: nil)
        
        let json: [String: Any] = [
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
            .filter(by: RapidFilter(keyPath: "text", relation: .equal, value: "texty text"))
        
        let sub = RapidCollectionSub(collectionID: collection.collectionName, filter: collection.subscriptionFilter, ordering: collection.subscriptionOrdering, paging: collection.subscriptionPaging, handler: nil, handlerWithChanges: nil)
        
        let json: [String: Any] = [
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
    
    func testSubscriptionOrdering() {
        let collection = self.rapid.collection(named: testCollectionName)
            .order(by: RapidOrdering(keyPath: "name", ordering: .ascending))
        
        let sub = RapidCollectionSub(collectionID: collection.collectionName, filter: collection.subscriptionFilter, ordering: collection.subscriptionOrdering, paging: collection.subscriptionPaging, handler: nil, handlerWithChanges: nil)
        
        let json: [String: Any] = [
            "sub": [
                "col-id": sub.collectionID,
                "order": [
                    ["name": "asc"]
                ]
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
                RapidFilter.and([
                    RapidFilter.or([
                        RapidFilter.equal(keyPath: "sender", value: "john123"),
                        RapidFilter.greaterThanOrEqual(keyPath: "urgency", value: 1),
                        RapidFilter.lessThanOrEqual(keyPath: "priority", value: 2)
                        ]),
                    RapidFilter.not(RapidFilter.isNull(keyPath: "receiver"))
                    ]))
            .filter(by:
                RapidFilter.and([
                    RapidFilter.greaterThan(keyPath: "urgency", value: 2),
                    RapidFilter.lessThan(keyPath: "urgency", value: 4)
                ]))
            .order(by:
                RapidOrdering(keyPath: "urgency", ordering: .ascending)
            )
            .limit(to: 50)
        
        let sub = RapidCollectionSub(collectionID: collection.collectionName, filter: collection.subscriptionFilter, ordering: collection.subscriptionOrdering, paging: collection.subscriptionPaging, handler: nil, handlerWithChanges: nil)
        
        let json: [String: Any] = [
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
                    ["urgency": "asc"]
                ],
                "limit": 50
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
    
    func testWrongDocumentIDSubscription() {
        let promise = expectation(description: "Wrong document id")
        
        self.rapid.collection(named: testCollectionName).document(withID: "t e s t").subscribe { result in
            if case .failure(let error) = result,
                case .invalidData(let reason) = error,
                case .invalidIdentifierFormat(let idef) = reason, idef as? String == "t e s t" {
                promise.fulfill()
            }
            else {
                XCTFail("Subsription passed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMutationWithArray() {
        let promise = expectation(description: "Wrong document id")
        
        self.rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": [["test": 1], ["test2": 2]], "json": ["testJSON": "blaaaa"] ] ) { result in
            switch result {
            case .failure:
                XCTFail("Error occured")
                
            default:
                break
            }
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testInvalidNestedDictionaryMutation() {
        let promise = expectation(description: "Wrong document id")
        
        self.rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": [["test": 1], ["tes.t": 2]] ] ) { result in
            if case .failure(let error) = result,
                case .invalidData(let reason) = error,
                case .invalidDocument = reason {
                promise.fulfill()
            }
            else {
                XCTFail("Subsription passed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testWrongDocumentIDMutation() {
        let promise = expectation(description: "Wrong document id")
        
        self.rapid.collection(named: testCollectionName).document(withID: "t e s t").mutate(value: ["name": "test"]) { result in
            if case .failure(let error) = result,
                case .invalidData(let reason) = error,
                case .invalidIdentifierFormat(let idef) = reason, idef as? String == "t e s t" {
                promise.fulfill()
            }
            else {
                XCTFail("Subsription passed")
                promise.fulfill()
            }
        }
            
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testInvalidKeyMutation() {
        let promise = expectation(description: "Wrong key")
        
        self.rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["na.me": "test"]) { result in
            if case .failure(let error) = result,
                case .invalidData(let reason) = error,
                case .invalidDocument = reason {
                promise.fulfill()
            }
            else {
                XCTFail("Subsription passed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testEmptyAndFilter() {
        let promise = expectation(description: "Empty compound filter")
        
        self.rapid.collection(named: testCollectionName).filter(by: RapidFilter.and([])).subscribe { result in
            if case .failure(let error) = result, case .invalidData = error {
                promise.fulfill()
            }
            else {
                XCTFail("Dictionary valid")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testEmptyOrFilter() {
        let promise = expectation(description: "Empty compound filter")
        
        self.rapid.collection(named: testCollectionName).filter(by: RapidFilter.or([])).subscribe { result in
            if case .failure(let error) = result, case .invalidData = error {
                promise.fulfill()
            }
            else {
                XCTFail("Dictionary valid")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testSubscriptionHashes() {
        let collection = self.rapid.collection(named: testCollectionName)
            .filter(by:
                RapidFilter.and([
                    RapidFilter.or([
                        RapidFilter.equal(keyPath: "sender", value: "john123"),
                        RapidFilter.greaterThanOrEqual(keyPath: "urgency", value: 1),
                        RapidFilter.lessThanOrEqual(keyPath: "priority", value: 2)
                        ]),
                    RapidFilter.not(RapidFilter.isNull(keyPath: "receiver"))
                    ]))
            .filter(by:
                RapidFilter.and([
                    RapidFilter.greaterThan(keyPath: "urgency", value: 2),
                    RapidFilter.lessThan(keyPath: "urgency", value: 4)
                    ]))
            .order(by:
                RapidOrdering(keyPath: "urgency", ordering: .ascending)
            )
            .limit(to: 50)

        let sub = RapidCollectionSub(collectionID: collection.collectionName, filter: collection.subscriptionFilter, ordering: collection.subscriptionOrdering, paging: collection.subscriptionPaging, handler: nil, handlerWithChanges: nil)
        
        let hash = "collection#\(testCollectionName)#and(and(urgency-lt-4|urgency-gt-2)|and(or(urgency-gte-1|sender-e-john123|priority-lte-2)|not(receiver-e-null)))#o-urgency-a#t50"
        
        XCTAssertEqual(sub.subscriptionHash, hash)
    }
    
    func testSubscriptionHashComparison() {
        let collection1 = self.rapid.collection(named: testCollectionName)
            .filter(by:
                RapidFilter.and([
                    RapidFilter.or([
                        RapidFilter.equal(keyPath: "sender", value: "john123"),
                        RapidFilter.greaterThanOrEqual(keyPath: "urgency", value: 1),
                        RapidFilter.lessThanOrEqual(keyPath: "priority", value: 2)
                        ]),
                    RapidFilter.not(RapidFilter.isNull(keyPath: "receiver"))
                    ]))
            .filter(by:
                RapidFilter.and([
                    RapidFilter.greaterThan(keyPath: "urgency", value: 2),
                    RapidFilter.lessThan(keyPath: "urgency", value: 4)
                    ]))
        
        let collection2 = self.rapid.collection(named: testCollectionName)
            .filter(by:
                RapidFilter.and([
                    RapidFilter.lessThan(keyPath: "urgency", value: 4),
                    RapidFilter.greaterThan(keyPath: "urgency", value: 2)
                    ]))
            .filter(by:
                RapidFilter.and([
                    RapidFilter.not(RapidFilter.isNull(keyPath: "receiver")),
                    RapidFilter.or([
                        RapidFilter.greaterThanOrEqual(keyPath: "urgency", value: 1),
                        RapidFilter.equal(keyPath: "sender", value: "john123"),
                        RapidFilter.lessThanOrEqual(keyPath: "priority", value: 2)
                        ])
                    ]))
        
        let sub1 = RapidCollectionSub(collectionID: collection1.collectionName, filter: collection1.subscriptionFilter, ordering: collection1.subscriptionOrdering, paging: collection1.subscriptionPaging, handler: nil, handlerWithChanges: nil)
        
        let sub2 = RapidCollectionSub(collectionID: collection2.collectionName, filter: collection2.subscriptionFilter, ordering: collection2.subscriptionOrdering, paging: collection2.subscriptionPaging, handler: nil, handlerWithChanges: nil)
        
        XCTAssertEqual(sub1.subscriptionHash, sub2.subscriptionHash)

    }
    
    func testSubscriptionBatchObjectForValue() {
        let update2 = RapidSubscriptionBatch(withCollectionJSON: [:])
        let update3 = RapidSubscriptionBatch(withCollectionJSON: ["evt-id": "kdsjghds"])
        let update4 = RapidSubscriptionBatch(withCollectionJSON: ["evt-id": "kdsjghds", "sub-id": "fjdslkfj"])
        
        XCTAssertNil(update2, "Object created")
        XCTAssertNil(update3, "Object created")
        XCTAssertNil(update4, "Object created")
    }
    
    func testSubscriptionBatchObjectForUpdate() {
        let update2 = RapidSubscriptionBatch(withUpdateJSON: [:], docRemoved: false)
        let update3 = RapidSubscriptionBatch(withUpdateJSON: ["evt-id": "kdsjghds"], docRemoved: false)
        let update4 = RapidSubscriptionBatch(withUpdateJSON: ["evt-id": "kdsjghds", "sub-id": "fjdslkfj"], docRemoved: false)
        
        XCTAssertNil(update2, "Object created")
        XCTAssertNil(update3, "Object created")
        XCTAssertNil(update4, "Object created")
    }
    
    func testSocketAcknowledgement() {
        let ack1 = RapidServerAcknowledgement(json: ["test"])
        let ack2 = RapidServerAcknowledgement(json: [:])
        
        XCTAssertNil(ack1, "Object created")
        XCTAssertNil(ack2, "Object created")
    }
    
    func testSubscriptionCancel() {
        let ca1 = RapidSubscriptionCancelled(json: "test")
        let ca2 = RapidSubscriptionCancelled(json: [:])
        let ca3 = RapidSubscriptionCancelled(json: ["evt-id": "kldjflk"])
        
        XCTAssertNil(ca1, "Not nil")
        XCTAssertNil(ca2, "Not nil")
        XCTAssertNil(ca3, "Not nil")
    }
    
    func testChannelMessage() {
        let mes1 = RapidChannelMessage(withJSON: [:])
        let mes2 = RapidChannelMessage(withJSON: ["evt-id": "kldjflk"])
        let mes3 = RapidChannelMessage(withJSON: ["evt-id": "kldjflk", "sub-id": "fkdsjlf"])
        let mes4 = RapidChannelMessage(withJSON: ["evt-id": "kldjflk", "sub-id": "fkdsjlf", "chan-id": "jdkfsj"])
        
        XCTAssertNil(mes1, "Not nil")
        XCTAssertNil(mes2, "Not nil")
        XCTAssertNil(mes3, "Not nil")
        XCTAssertNil(mes4, "Not nil")
    }
    
    func testLimitExceeded() {
        let promise = expectation(description: "Limit exceeded")
        
        rapid.collection(named: testCollectionName).limit(to: RapidPaging.takeLimit+1).subscribe { result in
            if case .failure(let error) = result, case RapidError.invalidData(let reason) = error, case RapidError.InvalidDataReason.invalidLimit = reason {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong error")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
}
