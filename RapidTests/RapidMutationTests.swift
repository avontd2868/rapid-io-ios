//
//  RapidMutationTests.swift
//  Rapid
//
//  Created by Jan on 05/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testMutationTimeout() {
        let rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Mutation timeout")
        
        rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { error in
            if let error = error as? RapidError, case .timeout = error {
                promise.fulfill()
            }
            else {
                XCTFail("Request did not timed out")
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testMergeTimeout() {
        let rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Merge timeout")
        
        rapid.collection(named: "users").newDocument().merge(value: ["name": "Jan"]) { error in
            if let error = error as? RapidError, case .timeout = error {
                promise.fulfill()
            }
            else {
                XCTFail("Request did not timed out")
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDeleteTimeout() {
        let rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Delete timeout")
        
        rapid.collection(named: "users").document(withID: "1").delete() { error in
            if let error = error as? RapidError, case .timeout = error {
                promise.fulfill()
            }
            else {
                XCTFail("Request did not timed out")
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCreateAndDelete() {
        let promise = expectation(description: "Delete document")
        
        let document = self.rapid.collection(named: testCollectionName).newDocument()
        
        document.mutate(value: ["name": "delete"], completion: { error in
            if error == nil {
                self.rapid.collection(named: self.testCollectionName).document(withID: document.documentID).delete(completion: { (error) in
                    if error == nil {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Document not deleted")
                    }
                })
            }
            else {
                XCTFail("Document not created")
            }
        })
        
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testMerge() {
        let promise = expectation(description: "Merge document")

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"])
        
        runAfter(1) { 
            var initial = true
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").subscribe { (_, value) in
                if initial {
                    initial = false
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").merge(value: ["desc": "desc", "bla": 6])
                }
                else if let dict = value.value, dict == ["name": "mergeTest", "desc": "desc", "bla": 6] {
                    promise.fulfill()
                }
                else {
                    XCTFail("Values doesn't match")
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCreateAndDeleteSafeWithEtag() {
        let promise = expectation(description: "Delete document")
        
        let document = self.rapid.collection(named: testCollectionName).newDocument()
        
        document.concurrencySafeMutate(value: ["name": "delete"], etag: nil, completion: { error in
            if error == nil {
                self.rapid.collection(named: self.testCollectionName).document(withID: document.documentID).readOnce(completion: { (_, document) in
                    self.rapid.collection(named: self.testCollectionName).document(withID: document.id).concurrencySafeDelete(etag: document.etag!, completion: { (error) in
                        if error == nil {
                            promise.fulfill()
                        }
                        else {
                            XCTFail("Document not deleted")
                        }
                    })
                })
            }
            else {
                XCTFail("Document not created")
            }
        })
        
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testCreateAndDeleteSafeWithBlock() {
        let promise = expectation(description: "Delete document")
        
        let document = self.rapid.collection(named: testCollectionName).newDocument()
        
        document.concurrencySafeMutate(concurrencyBlock: { current -> RapidConOptResult in
            XCTAssertNil(current, "Document exists")
            return .write(value: ["name": "delete"])
        }) { (_) in
            document.concurrencySafeDelete(concurrencyBlock: { value -> RapidConOptResult in
                if let dict = value, dict["name"] as? String == "delete" {
                    return .delete()
                }
                else {
                    XCTFail("Wrong value")
                    return .abort()
                }
            }, completion: { error in
                XCTAssertNil(error, "Delete error")
                promise.fulfill()
            })
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testMergeSafeWithEtag() {
        let promise = expectation(description: "Merge document")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"])
        
        runAfter(1) {
            var initial = true
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").subscribe { (_, value) in
                if initial {
                    initial = false
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").concurrencySafeMerge(value: ["desc": "desc", "bla": 6], etag: value.etag) { error in
                        XCTAssertNil(error, "Merge error")
                    }
                }
                else if let dict = value.value, dict == ["name": "mergeTest", "desc": "desc", "bla": 6] {
                    promise.fulfill()
                }
                else {
                    XCTFail("Values doesn't match")
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMergeSafeWithBlock() {
        let promise = expectation(description: "Merge document")

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"])
        
        runAfter(1) {
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").concurrencySafeMerge(
                concurrencyBlock: { (value) -> RapidConOptResult in
                    
                    return .write(value: ["desc": "desc", "bla": 6])
                },
                completion: { (_) in
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").readOnce(completion: { (_, value) in
                        if let dict = value.value, dict == ["name": "mergeTest", "desc": "desc", "bla": 6] {
                            promise.fulfill()
                        }
                        else {
                            XCTFail("Values doesn't match")
                        }
                    })
                })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMergeSafeRetry() {
        let promise = expectation(description: "Merge document")
        
        let conflictMessageForID: (String) -> String = { eventID in
            let json = [
                "err": [
                    "evt-id": eventID,
                    "err-type": "etag-conflict",
                    "err-msg": "Conflict"
                ]
            ]
            
            return (try? json.jsonString()) ?? ""
        }
        
        let mockHandler = MockNetworkHandler(socketURL: socketURL, writeCallback: { (handler, event, eventID) in
            if event is RapidDocumentMerge {
                handler.websocketDidReceiveMessage(socket: WebSocket(url: self.socketURL), text: conflictMessageForID(eventID))
            }
            else {
                handler.writeToSocket(event: event, withID: eventID)
            }
        })
        
        let manager = RapidSocketManager(networkHandler: mockHandler)
        
        let auth = RapidAuthRequest(accessToken: self.testAuthToken)
        manager.authorize(authRequest: auth)
        
        let mutate = RapidDocumentMutation(collectionID: testCollectionName, documentID: "1", value: ["name": "mergeTest", "desc": "description"], cache: nil) { error in
            XCTAssertNil(error, "Error occured")
            
            var firstTry = true
            let merge = RapidConOptDocumentMutation(collectionID: self.testCollectionName, documentID: "1", type: .merge, delegate: manager, concurrencyBlock: { (value) -> RapidConOptResult in
                if firstTry {
                    firstTry = false
                    return .write(value: ["desc": "desc", "bla": 6])
                }
                else {
                    return .abort()
                }
            }, completion: { error in
                if let error = error as? RapidError,
                    case RapidError.concurrencyWriteFailed(let reason) = error,
                    case RapidError.ConcurrencyWriteError.aborted = reason {
                    
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                }
            })
            
            manager.concurrencyOptimisticMutate(mutation: merge)
        }
        
        manager.mutate(mutationRequest: mutate)
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"])
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMutateSefeWithWrongEtag() {
        let promise = expectation(description: "Safe mutate")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "testMutateSefeWithWrongEtag"]) { error in
            XCTAssertNil(error, "Error occured")
            
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").concurrencySafeMutate(value: ["name": "errorTest"], etag: Rapid.uniqueID) { error in
                if let error = error as? RapidError,
                    case RapidError.concurrencyWriteFailed(let reason) = error,
                    case RapidError.ConcurrencyWriteError.writeConflict = reason {
                    
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").readOnce(completion: { (_, document) in
                        XCTAssertEqual(document.id, "1", "Wrong ID")
                        XCTAssertEqual(document.value?["name"] as? String, "testMutateSefeWithWrongEtag", "Wrong value")
                        promise.fulfill()
                    })
                }
                else {
                    XCTFail("Wrong error")
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
