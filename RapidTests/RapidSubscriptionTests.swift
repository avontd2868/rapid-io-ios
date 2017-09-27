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
    
    func testDocumentEqualityEquals() {
        let doc1 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123"
        ] as [String : Any]
        let doc2 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123"
        ] as [String : Any]
        let doc3 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [
                "name": "test"
            ]
        ] as [String : Any]
        let doc4 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [
                "name": "test"
            ]
        ] as [String : Any]
        let document1 = RapidDocument(existingDocJson: doc1, collectionID: testCollectionName)
        let document2 = RapidDocument(existingDocJson: doc2, collectionID: testCollectionName)
        let document3 = RapidDocument(existingDocJson: doc3, collectionID: testCollectionName)
        let document4 = RapidDocument(existingDocJson: doc4, collectionID: testCollectionName)
        
        XCTAssertEqual(document1, document2, "Documents not equal")
        XCTAssertEqual(document3, document4, "Documents not equal")
   }
    
    func testDocumentsEqualityDifferentID() {
        let doc1 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123"
            ] as [String : Any]
        let doc2 = [
            "id": "2",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [
                "name": "test"
            ]
            ] as [String : Any]
        let document1 = RapidDocument(existingDocJson: doc1, collectionID: testCollectionName)
        let document2 = RapidDocument(existingDocJson: doc2, collectionID: testCollectionName)
        
        XCTAssertNotEqual(document1, document2, "Documents not equal")
    }
    
    func testDocumentsEqualityDifferentCollectionID() {
        let doc1 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123"
            ] as [String : Any]
        let doc2 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [
                "name": "test"
            ]
            ] as [String : Any]
        let document1 = RapidDocument(existingDocJson: doc1, collectionID: testCollectionName)
        let document2 = RapidDocument(existingDocJson: doc2, collectionID: "1")
        
        XCTAssertNotEqual(document1, document2, "Documents not equal")
    }
    
    func testDocumentsEqualityDifferentEtag() {
        let doc1 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123"
            ] as [String : Any]
        let doc2 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "1234",
            "body": [
                "name": "test"
            ]
            ] as [String : Any]
        let document1 = RapidDocument(existingDocJson: doc1, collectionID: testCollectionName)
        let document2 = RapidDocument(existingDocJson: doc2, collectionID: testCollectionName)
        
        XCTAssertNotEqual(document1, document2, "Documents not equal")
    }
    
    func testDocumentsEqualityDifferentValues() {
        let doc1 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123"
            ] as [String : Any]
        let doc2 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [:]
            ] as [String : Any]
        let doc3 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [
                "name": "test1"
            ]
            ] as [String : Any]
        let doc4 = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "123",
            "body": [
                "name": "test2"
            ]
            ] as [String : Any]
        let document1 = RapidDocument(existingDocJson: doc1, collectionID: testCollectionName)
        let document2 = RapidDocument(existingDocJson: doc2, collectionID: testCollectionName)
        let document3 = RapidDocument(existingDocJson: doc3, collectionID: testCollectionName)
        let document4 = RapidDocument(existingDocJson: doc4, collectionID: testCollectionName)
        
        XCTAssertNotEqual(document1, document2, "Documents not equal")
        XCTAssertNotEqual(document3, document4, "Documents not equal")
    }
    
    func testDuplicateSubscriptions() {
        guard let sub1 = self.rapid.collection(named: "users").document(withID: "1").subscribe(block: { _ in }) as? RapidDocumentSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        guard let sub2 = self.rapid.collection(named: "users").filter(by: RapidFilterSimple(keyPath: RapidFilterSimple.docIdKey, relation: .equal, value: "1")).subscribe(block: { _ in }) as? RapidCollectionSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        let handler1 = self.rapid.handler.socketManager.activeSubscription(withHash: sub1.subscriptionHash)
        let handler2 = self.rapid.handler.socketManager.activeSubscription(withHash: sub2.subscriptionHash)
        
        if handler1 !== handler2 {
            XCTFail("Different handlers for same subscription")
        }
    }

    func testSubscriptionInitialResponse() {
        let promise = expectation(description: "Subscription initial value")
        
        self.rapid.collection(named: testCollectionName).subscribe(block: { _ in
            promise.fulfill()
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnsubscription() {
        let promise = expectation(description: "Unsubscribe")
        
        var initialValue = true
        let subscription = self.rapid.collection(named: testCollectionName).subscribe(block: { _ in
            if initialValue {
                initialValue = false
            }
            else {
                XCTFail("Subscription not uregistered")
            }
        })
        
        runAfter(2) {
            subscription.unsubscribe()
            self.mutate(documentID: "1", value: ["name": "testUnsubscriptiion"])
        }
        
        runAfter(4) { 
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnsubsciptionRetry() {
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil) { _ in
        }
        
        var activeSubscriptions = [RapidSubscriptionManager]()
        
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
        
        let handler = RapidColSubManager(withSubscriptionID: Rapid.uniqueID, subscription: subscription, delegate: subscriptionDelegate)
        activeSubscriptions.append(handler)
        
        subscription.unsubscribe()
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDoubleUnsubscriptionOnOneHandler() {
        let promise = expectation(description: "Double unsubscription")
        
        let sub1 = RapidCollectionSub(collectionID: testCollectionName, filter: RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"), ordering: nil, paging: nil, handler: nil, handlerWithChanges: nil)
        let sub2 = RapidDocumentSub(collectionID: testCollectionName, documentID: "1", handler: nil)
        
        let sub3 = RapidCollectionSub(collectionID: testCollectionName, filter: RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"), ordering: nil, paging: nil, handler: nil, handlerWithChanges: nil)
        let sub4 = RapidDocumentSub(collectionID: testCollectionName, documentID: "1", handler: nil)
        
        let networkHandler = RapidNetworkHandler(socketURL: self.socketURL)
        let fakeNetworkHandler = RapidNetworkHandler(socketURL: self.fakeSocketURL)
        let socketManager = RapidSocketManager(networkHandler: networkHandler)
        socketManager.authorize(authRequest: RapidAuthRequest(token: testAuthToken))
        let fakeSocketManager = RapidSocketManager(networkHandler: fakeNetworkHandler)
        
        socketManager.subscribe(toCollection: sub2)
        socketManager.subscribe(toCollection: sub1)
        
        fakeSocketManager.subscribe(toCollection: sub3)
        fakeSocketManager.subscribe(toCollection: sub4)

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
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnsubscribeAll() {
        let promise = expectation(description: "Unsubscribe all")
        
        var initial1 = true
        var initial2 = true
        
        self.rapid.collection(named: testCollectionName).subscribe(block: { _ in
            if initial1 {
                initial1 = false
            }
            else {
                XCTFail("Subscription not uregistered")
            }
        })
        
        self.rapid.collection(named: testCollectionName).order(by: RapidOrdering(keyPath: "name", ordering: .ascending)).subscribe(block: { _ in
            if initial2 {
                initial2 = false
            }
            else {
                XCTFail("Subscription not uregistered")
            }
        })
        
        runAfter(2) {
            self.rapid.unsubscribeAll()
            self.mutate(documentID: "1", value: ["name": "testUnsubscriptiion"])
        }
        
        runAfter(4) {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testInsert() {
        let promise = expectation(description: "Subscription insert")

        mutate(documentID: "1", value: nil) { _ in
        
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribeWithChanges { result in
                guard case .success(let tuple) = result else {
                    XCTFail("Document not inserted")
                    promise.fulfill()
                    return
                }
                
                if initialValue {
                    initialValue = false
                }
                else if tuple.added.count == 1 && tuple.updated.count == 0 && tuple.removed.count == 0 && tuple.added.first?.id == "1" {
                    promise.fulfill()
                }
                else {
                    XCTFail("Document not inserted")
                    promise.fulfill()
                }
            }
            
            self.mutate(documentID: "1", value: ["name": "testInsert"])
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testUpdate() {
        let promise = expectation(description: "Subscription update")

        mutate(documentID: "1", value: ["name": "testUpdate"]) { _ in
        
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribeWithChanges { result in
                guard case .success(let tuple) = result else {
                    XCTFail("Document not inserted")
                    promise.fulfill()
                    return
                }
                
                if initialValue {
                    initialValue = false
                }
                else if tuple.added.count == 0 && tuple.updated.count == 1 && tuple.removed.count == 0 && tuple.updated.first?.id == "1" {
                    promise.fulfill()
                }
                else {
                    XCTFail("Document not updated")
                    promise.fulfill()
                }
            }
            
            self.mutate(documentID: "1", value: ["name": "testUpdatedUpdate"])
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDelete() {
        let promise = expectation(description: "Subscription delete")

        mutate(documentID: "1", value: ["name": "testDelete"]) { _ in
        
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribeWithChanges { result in
                guard case .success(let tuple) = result else {
                    XCTFail("Document not inserted")
                    promise.fulfill()
                    return
                }
                
                if initialValue {
                    initialValue = false
                }
                else if tuple.added.count == 0 && tuple.updated.count == 0 && tuple.removed.count == 1 && tuple.removed.first?.id == "1" {
                    promise.fulfill()
                }
                else {
                    XCTFail("Document not deleted")
                    promise.fulfill()
                }
            }
            
            self.mutate(documentID: "1", value: nil)
        }
        
        waitForExpectations(timeout: 15, handler: nil)
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
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
                        "etag": doc1Etag,
                        "body": [
                            "name": "test1"
                        ]
                    ],
                    [
                        "id": "2",
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
                        "etag": doc2Etag,
                        "body": [
                            "name": "test2"
                        ]
                    ],
                    [
                        "id": "3",
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
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
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil) { _ in
            if initial {
                initial = false
            }
            else {
                XCTFail("Subscription was informed about no change")
                promise.fulfill()
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            runAfter(1, closure: {
                promise.fulfill()
            })
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
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
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test1"
                        ]
                    ],
                    [
                        "id": "2",
                        "skey": ["2"],
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
                        "etag": Rapid.uniqueID,
                        "body": [
                            "name": "test2"
                        ]
                    ],
                    [
                        "id": "3",
                        "skey": ["3"],
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "etag": Rapid.uniqueID,
                                "skey": ["2"],
                                "body": [
                                    "name": "test22"
                                ]
                            ],
                            [
                                "id": "3",
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "etag": docEtag,
                                "skey": ["3"],
                                "body": [
                                    "name": "test3"
                                ]
                            ],
                            [
                                "id": "4",
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: [RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending)], paging: nil, handler: nil) { result in
            guard case .success(let changes) = result else {
                XCTFail("Error")
                promise.fulfill()
                return
            }
            
            let (documents, insert, update, delete) = changes
            
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
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: batch)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
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
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
                        "skey": ["1"],
                        "body": [
                            "name": "test1"
                        ]
                    ],
                    [
                        "id": "2",
                        "etag": doc2Etag,
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
                        "skey": ["2"],
                        "body": [
                            "name": "test2"
                        ]
                    ],
                    [
                        "id": "3",
                        "etag": doc3Etag,
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "skey": ["1"],
                                "body": [
                                    "name": "test11"
                                ]
                            ],
                            [
                                "id": "2",
                                "etag": doc2Etag,
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "skey": ["2"],
                                "body": [
                                    "name": "test2"
                                ]
                            ],
                            [
                                "id": "3",
                                "etag": doc3Etag,
                                "skey": ["3"],
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: [RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending)], paging: nil, handler: nil) { result in
            
            guard case .success(let changes) = result else {
                XCTFail("Error")
                promise.fulfill()
                return
            }
            
            let (documents, insert, update, delete) = changes
            
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
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: batch)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
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
                        "crt": "a",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
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
                                "crt": "a",
                                "crt-ts": 0.0,
                                "mod-ts": 0.0,
                                "body": [
                                    "name": "test2"
                                ]
                        ]
                    ]
                ],
                [
                    "rm": [
                        "evt-id": Rapid.uniqueID,
                        "col-id": testCollectionName,
                        "sub-id": subID,
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
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil) { result in
            guard case .success(let changes) = result else {
                XCTFail("Error")
                promise.fulfill()
                return
            }
            
            let (documents, insert, update, delete) = changes
            
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
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: batch)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
        }
    }
    
    func testSubscriptionUpdateWithoutInitialValue() {
        let subID = Rapid.uniqueID
        
        let subValue: [AnyHashable: Any] = [
            "upd": [
                "evt-id": Rapid.uniqueID,
                "col-id": testCollectionName,
                "sub-id": subID,
                "doc": [
                    "id": "5",
                    "etag": Rapid.uniqueID,
                    "crt": "a",
                    "crt-ts": 0.0,
                    "mod-ts": 0.0,
                    "body": [
                        "name": "test5"
                    ]
                ]
            ]
        ]
        
        let promise = expectation(description: "Subscription no initial value")
        
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil) { result in
            guard case .success(let changes) = result else {
                XCTFail("Error")
                promise.fulfill()
                return
            }
            
            let (documents, insert, update, delete) = changes
            
            if insert.count == 1 && update.count == 0 && delete.count == 0 && documents == insert && documents.first?.id == "5" {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong update")
                promise.fulfill()
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let updateResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
        }
    }
    
    func testSubscriptionUpdateRemoveNonexistentDocument() {
        let subID = Rapid.uniqueID
        
        let subValue: [AnyHashable: Any] = [
            "rm": [
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
        
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil) { result in
            guard case .success(let changes) = result else {
                XCTFail("Error")
                promise.fulfill()
                return
            }
            
            let (documents, insert, update, delete) = changes
            
            if insert.count == 0 && update.count == 0 && delete.count == 0 && documents.count == 0 {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong update")
                promise.fulfill()
            }
        }
        
        let delegate = MockSubHandlerDelegate(unsubscriptionHandler: { _ in })
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let updateResponse = RapidSerialization.parse(json: subValue)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
       }
    }
    
    func testInitialValueOnDuplicateSubscription() {
        let promise = expectation(description: "Duplicate initial value")
        
        self.rapid.collection(named: testCollectionName).document(withID: "1")
            .mutate(value: ["name": "testInitialValueOnDuplicateSubscription"])
            { error in
                
                var initial = true
                self.rapid.collection(named: self.testCollectionName).subscribeWithChanges { result in
                    guard case .success(let changes) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    let (docs, ins, _, _) = changes
                    
                    if initial {
                        initial = false
                        
                        let documents = docs
                        let inserts = ins
                        
                        self.rapid.collection(named: self.testCollectionName).subscribeWithChanges { result in
                            guard case .success(let changes) = result else {
                                XCTFail("Error")
                                promise.fulfill()
                                return
                            }
                            
                            let (docs, ins, _, _) = changes
                            
                            if documents == docs && inserts == ins {
                                promise.fulfill()
                            }
                            else {
                                XCTFail("Initial value different")
                                promise.fulfill()
                            }
                        }
                    }
                }
            }
        
        waitForExpectations(timeout: 15, handler: nil)
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
                        "crt": "<DEFAULT SORT ORDER>",
                        "crt-ts": 0.0,
                        "mod-ts": 0.0,
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
                            "crt": "<DEFAULT SORT ORDER>",
                            "crt-ts": 0.0,
                            "mod-ts": 0.0,
                            "etag": "<SERVER ETAG>",
                        ]
                    ]
                ]
        
        let promise = expectation(description: "Document subscription delete")
        
        var initial = true
        let subscription = RapidDocumentSub(collectionID: testCollectionName, documentID: "1") { result in
            guard case .success(let document) = result else {
                XCTFail("Error")
                promise.fulfill()
                return
            }
            
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
        let handler = RapidColSubManager(withSubscriptionID: subID, subscription: subscription, delegate: delegate)
        
        if let valResponse = RapidSerialization.parse(json: initialValue)?.first as? RapidSubscriptionBatch,
            let updateResponse = RapidSerialization.parse(json: update)?.first as? RapidSubscriptionBatch {
            
            handler.receivedSubscriptionEvent(valResponse)
            handler.receivedSubscriptionEvent(updateResponse)
            
            waitForExpectations(timeout: 15, handler: nil)
        }
        else {
            XCTFail("Wrong response")
            promise.fulfill()
        }
    }
    
    func testCollectionFetch() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true

        mutate(documentID: "1", value: ["name": "testUpdate"]) { _ in

            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe { result in
                guard case .success(let documents) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
                XCTAssertGreaterThan(documents.count, 0, "No documentss")
                
                if initialValue {
                    initialValue = false
                    let docs = documents
                    
                    self.rapid.collection(named: self.testCollectionName).fetch(completion: { result in
                        guard case .success(let fetched) = result else {
                            XCTFail("Error")
                            promise.fulfill()
                            return
                        }
                        
                        if docs == fetched {
                            promise.fulfill()
                        }
                        else{
                            XCTFail("Fetched collection is different")
                            promise.fulfill()
                        }
                    })
                }
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDocumentFetch() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true
        
        mutate(documentID: "1", value: ["name": "testUpdate"]) { result in
        
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch(completion: { result in
                guard case .success(let document) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
                XCTAssertEqual(document.value?["name"] as? String, "testUpdate", "Wrong document")
                promise.fulfill()
            })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnauthorizedCollectionFetch() {
        let promise = expectation(description: "Subscription update")
        rapid.deauthorize()
        
        self.rapid.collection(named: "fakeCollectionName").fetch(completion: { result in
            if case .failure(let error) = result, case RapidError.permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Fetch passed")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnauthorizedDocumentFetch() {
        let promise = expectation(description: "Subscription update")
        rapid.deauthorize()
        
        self.rapid.collection(named: "fakeCollectionName").document(withID: "1").fetch(completion: { result in
            if case .failure(let error) = result, case RapidError.permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Fetch passed")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testDotConventionFilter() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true
        
        mutate(documentID: "1", value: ["car": ["type": "Skoda", "model": "Octavia"]]) { result in
        
            self.rapid.collection(named: self.testCollectionName).filter(by: RapidFilter.equal(keyPath: "car.type", value: "Skoda")).fetch { result in
                guard case .success(let documents) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
                XCTAssertGreaterThan(documents.count, 0, "No documentss")
                
                for document in documents {
                    let car = document.value?["car"] as? [AnyHashable: Any]
                    XCTAssertEqual(car?["type"] as? String, "Skoda", "Wrong document")
                }
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDotConventionOrder() {
        let promise = expectation(description: "Subscription update")
        
        rapid.isCacheEnabled = true
        
        mutate(documentID: "1", value: ["car": ["type": "Skoda", "model": "Octavia"]])
        mutate(documentID: "2", value: ["car": ["type": "Skoda", "model": "Fabia"]]) { _ in
            
            self.rapid.collection(named: self.testCollectionName).order(by: RapidOrdering(keyPath: "car.model", ordering: .ascending)).fetch { result in
                guard case .success(let documents) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
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
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDecodableDocument() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["name": "First document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch { result in
                guard case .success(let document) = result, document.value != nil else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
                let testStruct = try? document.decode(toType: RapidTestStruct.self)
                
                XCTAssertEqual(testStruct?.name, "First document", "Wrong document")
                XCTAssertEqual(testStruct?.id, document.id)
                XCTAssertEqual(testStruct?.collection, document.collectionName)
                XCTAssertEqual(testStruct?.etag, document.etag)
                XCTAssertEqual(testStruct?.createdAt, document.createdAt)
                XCTAssertEqual(testStruct?.modifiedAt, document.modifiedAt)
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testFetchDecodableDocument() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["name": "First document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch(objectType: RapidTestStruct.self) { result in
                guard case .success(let testStruct) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
                XCTAssertEqual(testStruct.name, "First document", "Wrong document")
                XCTAssertEqual(testStruct.id, "1")
                XCTAssertEqual(testStruct.collection, self.testCollectionName)
                XCTAssertNotNil(testStruct.etag)
                XCTAssertNotNil(testStruct.createdAt)
                XCTAssertNotNil(testStruct.modifiedAt)
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testFetchDecodableDocumentUndecodable() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["noName": "First document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch(objectType: RapidTestStruct.self) { result in
                guard case .failure(let error) = result else {
                    XCTFail("Succeeded")
                    promise.fulfill()
                    return
                }
                
                guard case .decodingFailed = error else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                    return
                }
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testSubscribeToDecodableDocument() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["name": "First document"]) { _ in
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").subscribe(objectType: RapidTestStruct.self) { result in
                guard initialValue else {
                    return
                }
                
                initialValue = false
                
                guard case .success(let testStruct) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
                XCTAssertEqual(testStruct.name, "First document", "Wrong document")
                XCTAssertEqual(testStruct.id, "1")
                XCTAssertEqual(testStruct.collection, self.testCollectionName)
                XCTAssertNotNil(testStruct.etag)
                XCTAssertNotNil(testStruct.createdAt)
                XCTAssertNotNil(testStruct.modifiedAt)
                
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testSubscribeToDecodableDocumentUndecodable() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["noName": "First document"]) { _ in
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").subscribe(objectType: RapidTestStruct.self) { result in
                guard initialValue else {
                    return
                }
                
                initialValue = false
                
                guard case .failure(let error) = result else {
                    XCTFail("Succeeded")
                    promise.fulfill()
                    return
                }
                
                guard case .decodingFailed = error else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                    return
                }

                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testDecodableDocumentArray() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["name": "First document"])
        mutate(documentID: "2", value: ["name": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .fetch { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    guard documents.count == 2 else {
                        XCTFail("Wrong number of documents")
                        promise.fulfill()
                        return
                    }
                    
                    let testArray = try? documents.decode(toType: RapidTestStruct.self)
                    let testFlatArray = documents.flatDecode(toType: RapidTestStruct.self)
                    
                    XCTAssertEqual(testArray?[0].name, "First document", "Wrong document")
                    XCTAssertEqual(testArray?[1].name, "Second document", "Wrong document")
                    
                    if testFlatArray.count == 2 {
                        XCTAssertEqual(testFlatArray[0].name, "First document", "Wrong document")
                        XCTAssertEqual(testFlatArray[1].name, "Second document", "Wrong document")
                    }
                    else {
                        XCTFail("Document array not flattened correctly")
                    }
                    
                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testFetchDecodableCollection() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["name": "First document"])
        mutate(documentID: "2", value: ["name": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .fetch(objectType: RapidTestStruct.self) { result in
                    guard case .success(let testArray) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    guard testArray.count == 2 else {
                        XCTFail("Wrong number of documents")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertEqual(testArray[0].name, "First document", "Wrong document")
                    XCTAssertEqual(testArray[1].name, "Second document", "Wrong document")
                    
                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testFetchDecodableCollectionUndecodable() {
        let promise = expectation(description: "Subscription update")
        
        mutate(documentID: "1", value: ["noName": "First document"])
        mutate(documentID: "2", value: ["noName": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .fetch(objectType: RapidTestStruct.self) { result in
                    guard case .failure(let error) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    guard case .decodingFailed = error else {
                        XCTFail("Wrong error")
                        promise.fulfill()
                        return
                    }
                    
                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testSubscribeToDecodableCollection() {
        let promise = expectation(description: "Subscription update")
        
        var initial = true
        
        mutate(documentID: "1", value: ["name": "First document"])
        mutate(documentID: "2", value: ["name": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .subscribe(objectType: RapidTestStruct.self) { result in
                    guard initial else {
                        return
                    }
                    
                    initial = false
                    
                    guard case .success(let testArray) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    guard testArray.count == 2 else {
                        XCTFail("Wrong number of documents")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertEqual(testArray[0].name, "First document", "Wrong document")
                    XCTAssertEqual(testArray[1].name, "Second document", "Wrong document")
                    
                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testSubscribeWithChangesToDecodableCollection() {
        let promise = expectation(description: "Subscription update")
        
        var initial = true
        
        mutate(documentID: "1", value: ["name": "First document"])
        mutate(documentID: "2", value: ["name": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .subscribeWithChanges(objectType: RapidTestStruct.self) { result in
                    guard initial else {
                        return
                    }
                    
                    initial = false
                    
                    guard case .success(let tuple) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    guard tuple.documents.count == 2 else {
                        XCTFail("Wrong number of documents")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertEqual(tuple.documents[0].name, "First document", "Wrong document")
                    XCTAssertEqual(tuple.documents[1].name, "Second document", "Wrong document")
                    
                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testSubscribeToDecodableCollectionUndecodable() {
        let promise = expectation(description: "Subscription update")
        
        var initial = true
        
        mutate(documentID: "1", value: ["noName": "First document"])
        mutate(documentID: "2", value: ["noName": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .subscribe(objectType: RapidTestStruct.self) { result in
                    guard initial else {
                        return
                    }
                    
                    initial = false
                    
                    guard case .failure(let error) = result else {
                        XCTFail("Success")
                        promise.fulfill()
                        return
                    }
                    
                    guard case .decodingFailed = error else {
                        XCTFail("Wrong error")
                        promise.fulfill()
                        return
                    }

                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testSubscribeWithChangesToDecodableCollectionUndecodable() {
        let promise = expectation(description: "Subscription update")
        
        var initial = true
        
        mutate(documentID: "1", value: ["noName": "First document"])
        mutate(documentID: "2", value: ["noName": "Second document"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by:
                    RapidFilter.or(
                        [
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "1"),
                            RapidFilter.equal(keyPath: RapidFilter.docIdKey, value: "2")
                        ]
                )).order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .ascending))
                .subscribeWithChanges(objectType: RapidTestStruct.self) { result in
                    guard initial else {
                        return
                    }
                    
                    initial = false
                    
                    guard case .failure(let error) = result else {
                        XCTFail("Success")
                        promise.fulfill()
                        return
                    }
                    
                    guard case .decodingFailed = error else {
                        XCTFail("Wrong error")
                        promise.fulfill()
                        return
                    }

                    promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
}

// MARK: Helper methods
extension RapidTests {
    
    func mutate(documentID: String?, value: [AnyHashable: Any]?, completion: RapidDocumentMutationCompletion? = nil) {
        if let id = documentID, let value = value {
            self.rapid.collection(named: testCollectionName).document(withID: id).mutate(value: value, completion: completion)
        }
        else if let id = documentID {
            self.rapid.collection(named: testCollectionName).document(withID: id).delete(completion: completion)
        }
        else {
            self.rapid.collection(named: testCollectionName).newDocument().mutate(value: value ?? [:], completion: completion)
        }
    }
    
}

struct RapidTestStruct: Codable {
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case id = "$documentId"
        case collection = "$collectionName"
        case createdAt = "$createdAt"
        case modifiedAt = "$modifiedAt"
        case etag = "$etag"
    }
    
    let name: String
    let id: String
    let collection: String
    let createdAt: Date
    let modifiedAt: Date
    let etag: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(String.self, forKey: .id)
        collection = try container.decode(String.self, forKey: .collection)
        createdAt = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: .createdAt))
        modifiedAt = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: .modifiedAt))
        etag = try container.decode(String.self, forKey: .etag)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
    
    init(name: String) {
        self.name = name
        self.id = Rapid.uniqueID
        self.etag = Rapid.uniqueID
        self.collection = "collection"
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// MARK: Mock subscription handler delegate
class MockSubHandlerDelegate: RapidSubscriptionManagerDelegate, RapidCacheHandler {
    
    let websocketQueue: OperationQueue
    let parseQueue: OperationQueue
    var cache: RapidCache?
    let unsubscriptionHandler: (_ handler: RapidUnsubscriptionManager) -> Void
    var authorization: RapidAuthorization?
    
    var cacheHandler: RapidCacheHandler? {
        return self
    }
    
    init(authorization: RapidAuthorization? = nil, unsubscriptionHandler: @escaping (_ handler: RapidUnsubscriptionManager) -> Void) {
        self.websocketQueue = OperationQueue()
        websocketQueue.name = "Websocket queue"
        websocketQueue.maxConcurrentOperationCount = 1

        self.parseQueue = OperationQueue()
        parseQueue.name = "Parse queue"
        parseQueue.maxConcurrentOperationCount = 1
        
        self.unsubscriptionHandler = unsubscriptionHandler
        self.authorization = authorization
    }
    
    func unsubscribe(handler: RapidUnsubscriptionManager) {
        self.unsubscriptionHandler(handler)
    }
    
    func loadSubscriptionValue(forSubscription subscription: RapidColSubManager, completion: @escaping ([RapidCachableObject]?) -> Void) {
        cache?.loadDataset(forKey: subscription.subscriptionHash, secret: authorization?.token, completion: completion)
    }
    
    func storeDataset(_ dataset: [RapidCachableObject], forSubscription subscription: RapidSubscriptionHashable) {
        cache?.save(dataset: dataset, forKey: subscription.subscriptionHash, secret: authorization?.token)
    }
    
    func storeObject(_ object: RapidCachableObject) {
        cache?.save(object: object, withSecret: authorization?.token)
    }
    
    func loadObject(withGroupID groupID: String, objectID: String, completion: @escaping (RapidCachableObject?) -> Void) {
        cache?.loadObject(withGroupID: groupID, objectID: objectID, secret: authorization?.token, completion: completion)
    }
    
    func removeObject(withGroupID groupID: String, objectID: String) {
        cache?.removeObject(withGroupID: groupID, objectID: objectID)
    }

}
