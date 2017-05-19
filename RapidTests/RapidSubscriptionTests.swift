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
    
    func testSnapshotEqualityEquals() {
        let snap1 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: nil, etag: "123")
        let snap2 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: nil, etag: "123")
        let snap3 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: ["name": "test"], etag: "123")
        let snap4 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: ["name": "test"], etag: "123")
        
        XCTAssertEqual(snap1, snap2, "Snapshots not equal")
        XCTAssertEqual(snap3, snap4, "Snapshots not equal")
   }
    
    func testSnapshotEqualityDifferentID() {
        let snap1 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: nil, etag: "123")
        let snap2 = RapidDocumentSnapshot(id: "2", collectionID: testCollectionName, value: [:], etag: "123")
        
        XCTAssertNotEqual(snap1, snap2, "Snapshots not equal")
    }
    
    func testSnapshotEqualityDifferentCollectionID() {
        let snap1 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: nil, etag: "123")
        let snap2 = RapidDocumentSnapshot(id: "2", collectionID: "1", value: [:], etag: "123")
        
        XCTAssertNotEqual(snap1, snap2, "Snapshots not equal")
    }
    
    func testSnapshotEqualityDifferentEtag() {
        let snap1 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: nil, etag: "123")
        let snap2 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: [:], etag: "1234")
        
        XCTAssertNotEqual(snap1, snap2, "Snapshots not equal")
    }
    
    func testSnapshotEqualityDifferentValues() {
        let snap1 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: nil, etag: "123")
        let snap2 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: [:], etag: "123")
        let snap3 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: ["name": "test1"], etag: "123")
        let snap4 = RapidDocumentSnapshot(id: "1", collectionID: testCollectionName, value: ["name": "test2"], etag: "123")
        
        XCTAssertNotEqual(snap1, snap2, "Snapshots not equal")
        XCTAssertNotEqual(snap3, snap4, "Snapshots not equal")
    }
    
    func testDuplicateSubscriptions() {
        guard let sub1 = self.rapid.collection(named: "users").document(withID: "1").subscribe(completion: { (_, _) in }) as? RapidDocumentSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        guard let sub2 = self.rapid.collection(named: "users").filter(by: RapidFilterSimple(keyPath: RapidFilterSimple.documentIdKey, relation: .equal, value: "1")).subscribe(completion: { (_, _) in }) as? RapidCollectionSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        let handler1 = self.rapid.handler.socketManager.activeSubscription(withHash: sub1.subscriptionHash)
        let handler2 = self.rapid.handler.socketManager.activeSubscription(withHash: sub2.subscriptionHash)
        
        XCTAssertEqual(handler1, handler2, "Different handlers for same subscription")
    }

    func testSubscriptionInitialResponse() {
        let promise = expectation(description: "Subscription initial value")
        
        self.rapid.collection(named: testCollectionName).subscribe { (_, _) in
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsubscription() {
        let promise = expectation(description: "Unsubscribe")
        
        var initialValue = true
        let subscription = self.rapid.collection(named: testCollectionName).subscribe { (_, _) in
            if initialValue {
                initialValue = false
            }
            else {
                XCTFail("Subscription not uregistered")
            }
        }
        
        runAfter(2) {
            subscription.unsubscribe()
            self.mutate(documentID: "1", value: ["name": "testUnsubscriptiion"])
        }
        
        runAfter(4) { 
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsubsciptionRetry() {
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, callback: nil) { (_, documents, insert, update, delete) in
        }
        
        var activeSubscriptions = [RapidSubscriptionHandler]()
        
        let promise = expectation(description: "Unsubscription retry")
        
        var firstTry = true
        let subscriptionDelegate = MockSubHandlerDelegate { (handler) in
            if firstTry {
                firstTry = false
                handler.eventFailed(withError: RapidErrorInstance(eventID: Rapid.uniqueID, error: RapidError.default))
            }
            else {
                promise.fulfill()
            }
        }
        
        let handler = RapidSubscriptionHandler(withSubscriptionID: Rapid.uniqueID, subscription: subscription, delegate: subscriptionDelegate)
        activeSubscriptions.append(handler)
        
        subscription.unsubscribe()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDoubleUnsubscriptionOnOneHandler() {
        let promise = expectation(description: "Double unsubscription")
        
        let sub1 = RapidCollectionSub(collectionID: testCollectionName, filter: RapidFilter.equal(keyPath: RapidFilter.documentIdKey, value: "1"), ordering: nil, paging: nil, callback: nil, callbackWithChanges: nil)
        let sub2 = RapidDocumentSub(collectionID: testCollectionName, documentID: "1", callback: nil)
        
        let sub3 = RapidCollectionSub(collectionID: testCollectionName, filter: RapidFilter.equal(keyPath: RapidFilter.documentIdKey, value: "1"), ordering: nil, paging: nil, callback: nil, callbackWithChanges: nil)
        let sub4 = RapidDocumentSub(collectionID: testCollectionName, documentID: "1", callback: nil)
        
        let networkHandler = RapidNetworkHandler(socketURL: self.socketURL)
        let fakeNetworkHandler = RapidNetworkHandler(socketURL: self.fakeSocketURL)
        let socketManager = RapidSocketManager(networkHandler: networkHandler)
        socketManager.authorize(authRequest: RapidAuthRequest(accessToken: testAuthToken))
        let fakeSocketManager = RapidSocketManager(networkHandler: fakeNetworkHandler)
        
        socketManager.subscribe(sub2)
        socketManager.subscribe(sub1)
        
        fakeSocketManager.subscribe(sub3)
        fakeSocketManager.subscribe(sub4)

        sub1.unsubscribe()
        sub4.unsubscribe()
        
        runAfter(1) {
            XCTAssertNotNil(socketManager.activeSubscription(withHash: sub1.subscriptionHash), "Subscription handler released")
            XCTAssertNotNil(fakeSocketManager.activeSubscription(withHash: sub4.subscriptionHash), "Subscription handler released")
            
            sub2.unsubscribe()
            sub3.unsubscribe()
            
            runAfter(1, closure: {
                XCTAssertNil(socketManager.activeSubscription(withHash: sub2.subscriptionHash), "Subscription handler not released")
                XCTAssertNil(fakeSocketManager.activeSubscription(withHash: sub3.subscriptionHash), "Subscription handler not released")
                
                promise.fulfill()
            })
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testUnsubscribeAll() {
        let promise = expectation(description: "Unsubscribe all")
        
        var initial1 = true
        var initial2 = true
        
        self.rapid.collection(named: testCollectionName).subscribe { (_, _) in
            if initial1 {
                initial1 = false
            }
            else {
                XCTFail("Subscription not uregistered")
            }
        }
        
        self.rapid.collection(named: testCollectionName).order(by: RapidOrdering(keyPath: "name", ordering: .ascending)).subscribe { (_, _) in
            if initial2 {
                initial2 = false
            }
            else {
                XCTFail("Subscription not uregistered")
            }
        }
        
        runAfter(2) {
            self.rapid.unsubscribeAll()
            self.mutate(documentID: "1", value: ["name": "testUnsubscriptiion"])
        }
        
        runAfter(4) {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testInsert() {
        let promise = expectation(description: "Subscription insert")

        mutate(documentID: "1", value: nil)
        
        runAfter(1) { 
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe { (_, _, inserts, updates, deletes) in
                if initialValue {
                    initialValue = false
                }
                else if inserts.count == 1 && updates.count == 0 && deletes.count == 0 && inserts.first?.id == "1" {
                    promise.fulfill()
                }
                else {
                    XCTFail("Document not inserted")
                }
            }
            
            self.mutate(documentID: "1", value: ["name": "testInsert"])
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUpdate() {
        let promise = expectation(description: "Subscription update")
        Rapid.logLevel = .debug
        mutate(documentID: "1", value: ["name": "testUpdate"])
        
        runAfter(1) { 
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe { (_, documents, inserts, updates, deletes) in
                if initialValue {
                    initialValue = false
                }
                else if inserts.count == 0 && updates.count == 1 && deletes.count == 0 && updates.first?.id == "1" {
                    promise.fulfill()
                }
                else {
                    XCTFail("Document not updated")
                }
            }
            
            self.mutate(documentID: "1", value: ["name": "testUpdatedUpdate"])
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDelete() {
        let promise = expectation(description: "Subscription delete")

        mutate(documentID: "1", value: ["name": "testDelete"])
        
        runAfter(1) { 
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe { (_, _, inserts, updates, deletes) in
                if initialValue {
                    initialValue = false
                }
                else if inserts.count == 0 && updates.count == 0 && deletes.count == 1 && deletes.first?.id == "1" {
                    promise.fulfill()
                }
                else {
                    XCTFail("Document not deleted")
                }
            }
            
            self.mutate(documentID: "1", value: nil)
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testEmptySubscriptionUpdate() {
        let subID = Rapid.uniqueID
        let doc1Etag = Rapid.uniqueID
        let doc2Etag = Rapid.uniqueID
        let doc3Etag = Rapid.uniqueID
        
        let subValue: [AnyHashable: Any] = [
            "val": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "docs": [
                    [
                        "id": "1",
                        "etag": doc1Etag,
                        "body": [
                            "name": "test1"
                        ]
                    ],
                    [
                        "id": "2",
                        "etag": doc2Etag,
                        "body": [
                            "name": "test2"
                        ]
                    ],
                    [
                        "id": "3",
                        "etag": doc3Etag,
                        "body": [
                            "name": "test3"
                        ]
                    ]
                ]
            ]
        ]
        
        let promise = expectation(description: "Subscription empty update")
        
        var initial = true
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, callback: nil) { (_, documents, insert, update, delete) in
            if initial {
                initial = false
            }
            else {
                XCTFail("Subscription was informed about no change")
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            runAfter(1, closure: {
                promise.fulfill()
            })
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testSubscriptionUpdates() {
        let subID = Rapid.uniqueID
        let docEtag = Rapid.uniqueID
        
        let initialValue: [AnyHashable: Any] = [
            "val": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "docs": [
                    [
                        "id": "1",
                        "skey": ["1"],
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test1"
                        ]
                    ],
                    [
                        "id": "2",
                        "skey": ["2"],
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test2"
                        ]
                    ],
                    [
                        "id": "3",
                        "skey": ["3"],
                        "etag": docEtag,
                        "body": [
                            "name": "test3"
                        ]
                    ]
                ]
            ]
        ]
        
        let batch: [AnyHashable: Any] = [
            "batch": [
                [
                    "val": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "docs": [
                            [
                                "id": "2",
                                "etag": Rapid.uniqueID,
                                "skey": ["2"],
                                "body": [
                                    "name": "test22"
                                ]
                            ],
                            [
                                "id": "3",
                                "etag": docEtag,
                                "skey": ["3"],
                                "body": [
                                    "name": "test3"
                                ]
                            ],
                            [
                                "id": "4",
                                "etag": Rapid.uniqueID,
                                "skey": ["4"],
                                "body": [
                                    "name": "test"
                                ]
                            ],
                            [
                                "id": "666",
                                "etag": Rapid.uniqueID
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
                                "id": "4",
                                "skey": ["1"],
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test4"
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
                                "id": "5",
                                "skey": ["5"],
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test5"
                                ]
                        ]
                    ]
                ]
            ]
        ]

        let promise = expectation(description: "Subscription updates")
        
        var val = true
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: [RapidOrdering(keyPath: RapidOrdering.documentIdKey, ordering: .ascending)], paging: nil, callback: nil) { (_, documents, insert, update, delete) in
            if val {
                val = false
                XCTAssertEqual(documents.count, 3, "Number of documents")
                XCTAssertEqual(insert.count, 3, "Number of inserts")
                XCTAssertEqual(update.count, 0, "Number of updates")
                XCTAssertEqual(delete.count, 0, "Number of deletes")
                XCTAssertEqual(documents[0].id, "1", "Number of inserts")
                XCTAssertEqual(documents[1].id, "2", "Number of inserts")
                XCTAssertEqual(documents[2].id, "3", "Number of inserts")
                XCTAssertEqual(documents[0].value?["name"] as? String, "test1", "Number of inserts")
                XCTAssertEqual(documents[1].value?["name"] as? String, "test2", "Number of inserts")
                XCTAssertEqual(documents[2].value?["name"] as? String, "test3", "Number of inserts")
            }
            else {
                XCTAssertEqual(documents.count, 4, "Number of documents")
                XCTAssertEqual(insert.count, 2, "Number of inserts")
                XCTAssertEqual(update.count, 1, "Number of updates")
                XCTAssertEqual(delete.count, 1, "Number of deletes")
                XCTAssertEqual(delete[0].id, "1", "Number of inserts")
                XCTAssertEqual(update[0].id, "2", "Number of inserts")
                XCTAssertEqual(documents[0].id, "4", "Number of inserts")
                XCTAssertEqual(documents[1].id, "2", "Number of inserts")
                XCTAssertEqual(documents[2].id, "3", "Number of inserts")
                XCTAssertEqual(documents[3].id, "5", "Number of inserts")
                XCTAssertEqual(documents[0].value?["name"] as? String, "test4", "Number of inserts")
                XCTAssertEqual(documents[1].value?["name"] as? String, "test22", "Number of inserts")
                XCTAssertEqual(documents[2].value?["name"] as? String, "test3", "Number of inserts")
                XCTAssertEqual(documents[3].value?["name"] as? String, "test5", "Number of inserts")
                
                promise.fulfill()
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: batch)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testSubscriptionOrderUpdates() {
        let subID = Rapid.uniqueID
        let doc2Etag = Rapid.uniqueID
        let doc3Etag = Rapid.uniqueID
        
        let initialValue: [AnyHashable: Any] = [
            "val": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "docs": [
                    [
                        "id": "1",
                        "etag": Rapid.uniqueID,
                        "skey": ["1"],
                        "body": [
                            "name": "test1"
                        ]
                    ],
                    [
                        "id": "2",
                        "etag": doc2Etag,
                        "skey": ["2"],
                        "body": [
                            "name": "test2"
                        ]
                    ],
                    [
                        "id": "3",
                        "etag": doc3Etag,
                        "skey": ["3"],
                        "body": [
                            "name": "test3"
                        ]
                    ]
                ]
            ]
        ]
        
        let batch: [AnyHashable: Any] = [
            "batch": [
                [
                    "val": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "docs": [
                            [
                                "id": "1",
                                "etag": Rapid.uniqueID,
                                "skey": ["1"],
                                "body": [
                                    "name": "test11"
                                ]
                            ],
                            [
                                "id": "2",
                                "etag": doc2Etag,
                                "skey": ["2"],
                                "body": [
                                    "name": "test2"
                                ]
                            ],
                            [
                                "id": "3",
                                "etag": doc3Etag,
                                "skey": ["3"],
                                "body": [
                                    "name": "test3"
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
                                "skey": ["5"],
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test111"
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
                                "id": "3",
                                "skey": ["4"],
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test33"
                                ]
                        ]
                    ]
                ]
            ]
        ]
        
        let promise = expectation(description: "Subscription updates")
        
        var val = true
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: [RapidOrdering(keyPath: RapidOrdering.documentIdKey, ordering: .ascending)], paging: nil, callback: nil) { (_, documents, insert, update, delete) in
            if val {
                val = false
                XCTAssertEqual(documents.count, 3, "Number of documents")
                XCTAssertEqual(insert.count, 3, "Number of inserts")
                XCTAssertEqual(update.count, 0, "Number of updates")
                XCTAssertEqual(delete.count, 0, "Number of deletes")
                XCTAssertEqual(documents[0].id, "1", "Number of inserts")
                XCTAssertEqual(documents[1].id, "2", "Number of inserts")
                XCTAssertEqual(documents[2].id, "3", "Number of inserts")
                XCTAssertEqual(documents[0].value?["name"] as? String, "test1", "Number of inserts")
                XCTAssertEqual(documents[1].value?["name"] as? String, "test2", "Number of inserts")
                XCTAssertEqual(documents[2].value?["name"] as? String, "test3", "Number of inserts")
            }
            else {
                XCTAssertEqual(documents.count, 3, "Number of documents")
                XCTAssertEqual(insert.count, 0, "Number of inserts")
                XCTAssertEqual(update.count, 2, "Number of updates")
                XCTAssertEqual(delete.count, 0, "Number of deletes")
                XCTAssertEqual(update[0].id, "1", "Number of inserts")
                XCTAssertEqual(update[1].id, "3", "Number of inserts")
                XCTAssertEqual(documents[0].id, "2", "Number of inserts")
                XCTAssertEqual(documents[1].id, "3", "Number of inserts")
                XCTAssertEqual(documents[2].id, "1", "Number of inserts")
                XCTAssertEqual(documents[0].value?["name"] as? String, "test2", "Number of inserts")
                XCTAssertEqual(documents[1].value?["name"] as? String, "test33", "Number of inserts")
                XCTAssertEqual(documents[2].value?["name"] as? String, "test111", "Number of inserts")
                
                promise.fulfill()
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: batch)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testSubscriptionComplementaryUpdates() {
        let subID = Rapid.uniqueID
        
        let initialValue: [AnyHashable: Any] = [
            "val": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "docs": [
                    [
                        "id": "1",
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test1"
                        ]
                    ]
                ]
            ]
        ]
        
        let batch: [AnyHashable: Any] = [
            "batch": [
                [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "doc": [
                                "id": "1",
                                "etag": Rapid.uniqueID,
                        ]
                    ]
                ],
                [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "doc": [
                                "id": "1",
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test11"
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
                        "doc": [
                                "id": "2",
                                "etag": Rapid.uniqueID,
                                "body": [
                                    "name": "test2"
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
                        "doc": [
                                "id": "2",
                                "etag": Rapid.uniqueID,
                        ]
                    ]
                ]
            ]
        ]
        
        let promise = expectation(description: "Subscription updates")

        var val = true
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, callback: nil) { (_, documents, insert, update, delete) in
            if val {
                val = false
                XCTAssertEqual(documents.count, 1, "Number of documents")
                XCTAssertEqual(insert.count, 1, "Number of inserts")
                XCTAssertEqual(update.count, 0, "Number of updates")
                XCTAssertEqual(delete.count, 0, "Number of deletes")
                XCTAssertEqual(documents[0].id, "1", "Number of inserts")
                XCTAssertEqual(documents[0].value?["name"] as? String, "test1", "Number of inserts")
            }
            else {
                XCTAssertEqual(documents.count, 1, "Number of documents")
                XCTAssertEqual(insert.count, 0, "Number of inserts")
                XCTAssertEqual(update.count, 1, "Number of updates")
                XCTAssertEqual(delete.count, 0, "Number of deletes")
                XCTAssertEqual(update[0].id, "1", "Number of inserts")
                XCTAssertEqual(documents[0].id, "1", "Number of inserts")
                XCTAssertEqual(documents[0].value?["name"] as? String, "test11", "Number of inserts")
                
                promise.fulfill()
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: batch)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testSubscriptionUpdateWithoutInitialValue() {
        let subID = Rapid.uniqueID
        
        let subValue: [AnyHashable: Any] = [
            "upd": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "doc":
                    [
                        "id": "5",
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test5"
                        ]
                ]
            ]
        ]
        
        let promise = expectation(description: "Subscription no initial value")
        
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, callback: nil) { (_, documents, insert, update, delete) in
            if insert.count == 1 && update.count == 0 && delete.count == 0 && documents == insert && documents.first?.id == "5" {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong update")
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let updateResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testSubscriptionUpdateRemoveNonexistentDocument() {
        let subID = Rapid.uniqueID
        
        let subValue: [AnyHashable: Any] = [
            "upd": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "doc": [
                        "id": "666",
                        "etag": Rapid.uniqueID
                ]
            ]
        ]
        
        let promise = expectation(description: "Subscription no initial value")
        
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, callback: nil) { (_, documents, insert, update, delete) in
            if insert.count == 0 && update.count == 0 && delete.count == 0 && documents.count == 0 {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong update")
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let updateResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testInitialValueOnDuplicateSubscription() {
        self.rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "testInitialValueOnDuplicateSubscription"])
        
        let promise = expectation(description: "Duplicate initial value")
        
        var initial = true
        self.rapid.collection(named: testCollectionName).subscribe { (_, docs, ins, _, _) in
            
            if initial {
                initial = false
                
                let documents = docs
                let inserts = ins
                
                self.rapid.collection(named: self.testCollectionName).subscribe(completionWithChanges: { (_, docs, ins, _, _) in
                    if documents == docs && inserts == ins {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Initial value different")
                    }
                })
            }
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testDocumentSubscriptionDelete() {
        let subID = Rapid.uniqueID
        
        let initialValue: [AnyHashable: Any] = [
            "val": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "docs": [
                    [
                        "id": "1",
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test"
                        ]
                    ]
                ]
            ]
        ]
        
        let update: [AnyHashable: Any] = [
                    "upd": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
                        "doc": [
                            "id": "1",
                            "etag": Rapid.uniqueID,
                        ]
                    ]
                ]
        
        let promise = expectation(description: "Document subscription delete")
        
        var initial = true
        let subscription = RapidDocumentSub(collectionID: testCollectionName, documentID: "1") { (_, document) in
            if initial {
                initial = false
                XCTAssertEqual(document.id, "1", "Wrong document id")
                XCTAssertEqual(document.value?["name"] as? String, "test", "Wrong document value")
            }
            else {
                XCTAssertEqual(document.id, "1", "Wrong document id")
                XCTAssertNil(document.value, "Wrong document value")
                
                promise.fulfill()
            }
        }

        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidSubscriptionHandler(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: update)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 2, handler: nil)
        }
        else {
            XCTFail("Wrong response")
        }
    }
    
    func testCollectionFetch() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true

        mutate(documentID: "1", value: ["name": "testUpdate"])
        
        runAfter(1) {
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe { (_, documents) in
                XCTAssertGreaterThan(documents.count, 0, "No documentss")
                
                if initialValue {
                    initialValue = false
                    let docs = documents
                    
                    self.rapid.collection(named: self.testCollectionName).readOnce(completion: { (_, fetched) in
                        if docs == fetched {
                            promise.fulfill()
                        }
                        else{
                            XCTFail("Fetched collection is different")
                        }
                    })
                }
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDocumentFetch() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true
        
        mutate(documentID: "1", value: ["name": "testUpdate"])
        
        runAfter(1) {
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").readOnce(completion: { (_, document) in
                XCTAssertEqual(document.value?["name"] as? String, "testUpdate", "Wrong document")
                promise.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUnauthorizedCollectionFetch() {
        let promise = expectation(description: "Subscription update")

        self.rapid.collection(named: "fakeCollectionName").readOnce(completion: { (error, _) in
            if let error = error as? RapidError, case RapidError.permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Fetch passed")
            }
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnauthorizedDocumentFetch() {
        let promise = expectation(description: "Subscription update")

        self.rapid.collection(named: "fakeCollectionName").document(withID: "1").readOnce(completion: { (error, _) in
            if let error = error as? RapidError, case RapidError.permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Fetch passed")
            }
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDotConventionFilter() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true
        
        mutate(documentID: "1", value: ["car": ["type": "Skoda", "model": "Octavia"]])
        
        runAfter(1) {

            self.rapid.collection(named: self.testCollectionName).filter(by: RapidFilter.equal(keyPath: "car.type", value: "Skoda")).readOnce { (_, documents) in
                XCTAssertGreaterThan(documents.count, 0, "No documentss")
                
                for document in documents {
                    let car = document.value?["car"] as? [AnyHashable: Any]
                    XCTAssertEqual(car?["type"] as? String, "Skoda", "Wrong document")
                }
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDotConventionOrder() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true
        
        mutate(documentID: "1", value: ["car": ["type": "Skoda", "model": "Octavia"]])
        mutate(documentID: "2", value: ["car": ["type": "Skoda", "model": "Fabia"]])
        
        runAfter(1) {
            
            self.rapid.collection(named: self.testCollectionName).order(by: RapidOrdering(keyPath: "car.model", ordering: .ascending)).readOnce { (_, documents) in
                XCTAssertGreaterThan(documents.count, 0, "No documents")
                
                var lastValue: String?
                for document in documents {
                    let car = document.value?["car"] as? [AnyHashable: Any]
                    let model = car?["model"] as? String
                    
                    if let value = lastValue {
                        if let model = model {
                            XCTAssertGreaterThanOrEqual(model, value, "Wrong order")
                        }
                        else {
                            XCTFail("No model")
                        }
                    }
                    
                    lastValue = model
                }
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
}

// MARK: Helper methods
fileprivate extension RapidTests {
    
    func mutate(documentID: String?, value: [AnyHashable: Any]?) {
        if let id = documentID, let value = value {
            self.rapid.collection(named: testCollectionName).document(withID: id).mutate(value: value)
        }
        else if let id = documentID {
            self.rapid.collection(named: testCollectionName).document(withID: id).delete()
        }
        else {
            self.rapid.collection(named: testCollectionName).newDocument().mutate(value: value ?? [:])
        }
    }
    
}

// MARK: Mock subscription handler delegate
class MockSubHandlerDelegate: RapidSubscriptionHandlerDelegate, RapidCacheHandler {
    
    let websocketQueue: OperationQueue
    let parseQueue: OperationQueue
    var cache: RapidCache?
    let unsubscriptionHandler: (_ handler: RapidUnsubscriptionHandler) -> Void
    var authorization: RapidAuthorization?
    
    var cacheHandler: RapidCacheHandler? {
        return self
    }
    
    init(authorization: RapidAuthorization? = nil, unsubscriptionHandler: @escaping (_ handler: RapidUnsubscriptionHandler) -> Void) {
        self.websocketQueue = OperationQueue()
        websocketQueue.name = "Websocket queue"
        websocketQueue.maxConcurrentOperationCount = 1

        self.parseQueue = OperationQueue()
        parseQueue.name = "Parse queue"
        parseQueue.maxConcurrentOperationCount = 1
        
        self.unsubscriptionHandler = unsubscriptionHandler
        self.authorization = authorization
    }
    
    func unsubscribe(handler: RapidUnsubscriptionHandler) {
        self.unsubscriptionHandler(handler)
    }
    
    func loadSubscriptionValue(forSubscription subscription: RapidSubscriptionHandler, completion: @escaping ([RapidCachableObject]?) -> Void) {
        cache?.loadDataset(forKey: subscription.subscriptionHash, secret: authorization?.accessToken, completion: completion)
    }
    
    func storeDataset(_ dataset: [RapidCachableObject], forSubscription subscription: RapidSubscriptionHashable) {
        cache?.save(dataset: dataset, forKey: subscription.subscriptionHash, secret: authorization?.accessToken)
    }
    
    func storeObject(_ object: RapidCachableObject) {
        cache?.save(object: object, withSecret: authorization?.accessToken)
    }
    
    func loadObject(withGroupID groupID: String, objectID: String, completion: @escaping (RapidCachableObject?) -> Void) {
        cache?.loadObject(withGroupID: groupID, objectID: objectID, secret: authorization?.accessToken, completion: completion)
    }
    
    func removeObject(withGroupID groupID: String, objectID: String) {
        cache?.removeObject(withGroupID: groupID, objectID: objectID)
    }

}
