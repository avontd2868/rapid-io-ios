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
        let rapid = Rapid.getInstance(withApiKey: fakeApiKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Mutation timeout")
        
        rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { result in
            if case .failure(let error) = result, case .timeout = error {
                promise.fulfill()
            }
            else {
                XCTFail("Request did not timed out")
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testMergeTimeout() {
        let rapid = Rapid.getInstance(withApiKey: fakeApiKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Merge timeout")
        
        rapid.collection(named: "users").newDocument().merge(value: ["name": "Jan"]) { result in
            if case .failure(let error) = result, case .timeout = error {
                promise.fulfill()
            }
            else {
                XCTFail("Request did not timed out")
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDeleteTimeout() {
        let rapid = Rapid.getInstance(withApiKey: fakeApiKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Delete timeout")
        
        rapid.collection(named: "users").document(withID: "1").delete() { result in
            if case .failure(let error) = result, case .timeout = error {
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
        
        document.mutate(value: ["name": "delete"], completion: { result in
            if case .success = result {
                self.rapid.collection(named: self.testCollectionName).document(withID: document.documentID).delete(completion: { result in
                    if case .success = result {
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

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"]) { result in
        
            var initial = true
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").subscribe { result in
                if initial {
                    initial = false
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").merge(value: ["desc": "desc", "bla": 6])
                }
                else if case .success(let doc) = result, let dict = doc.value, dict == ["name": "mergeTest", "desc": "desc", "bla": 6] {
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
        
        document.mutate(value: ["name": "delete"], etag: nil, completion: { result in
            if case .success = result {
                self.rapid.collection(named: self.testCollectionName).document(withID: document.documentID).fetch(completion: { result in
                    if case .success(let document) = result {
                        self.rapid.collection(named: self.testCollectionName).document(withID: document.id).delete(etag: document.etag!, completion: { result in
                            if case .success = result {
                                promise.fulfill()
                            }
                            else {
                                XCTFail("Document not deleted")
                            }
                        })
                    }
                    else {
                        XCTFail("Document not fetched")
                    }
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
        
        document.execute(block: { current -> RapidExecutionResult in
            XCTAssertNil(current.value, "Document exists")
            return .write(value: ["name": "delete"])
        }) { (_) in
            document.execute(block: { doc -> RapidExecutionResult in
                if let dict = doc.value, dict["name"] as? String == "delete" {
                    return .delete
                }
                else {
                    XCTFail("Wrong value")
                    return .abort
                }
            }, completion: { result in
                if case .failure = result {
                    XCTFail("Error occured")
                }
                
                promise.fulfill()
            })
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testMergeSafeWithEtag() {
        let promise = expectation(description: "Merge document")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"]) { result in
        
            var initial = true
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").subscribe { result in
                if case .success(let doc) = result {
                    if initial {
                        initial = false
                        self.rapid.collection(named: self.testCollectionName).document(withID: "1").merge(value: ["desc": "desc", "bla": 6], etag: doc.etag) { result in
                            if case .failure = result {
                                XCTFail("Error occured")
                            }
                        }
                    }
                    else if let dict = doc.value, dict == ["name": "mergeTest", "desc": "desc", "bla": 6] {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Values doesn't match")
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMergeSafeWithBlock() {
        let promise = expectation(description: "Merge document")

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"])
        
        runAfter(1) {
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").execute(
                block: { doc -> RapidExecutionResult in
                    var newValue = doc.value ?? [:]
                    
                    newValue["desc"] = "desc"
                    newValue["bla"] = 6
                    
                    return .write(value: newValue)
                },
                completion: { (_) in
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch(completion: { result in
                        if case .success(let doc) = result, let dict = doc.value, dict == ["name": "mergeTest", "desc": "desc", "bla": 6] {
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
        
        var firstMutation = true
        let mockHandler = MockNetworkHandler(socketURL: socketURL, writeCallback: { (handler, event, eventID) in
            if event is RapidDocumentMutation && firstMutation {
                firstMutation = false
                handler.writeToSocket(event: event, withID: eventID)
            }
            else if event is RapidDocumentMutation {
                handler.websocketDidReceiveMessage(socket: WebSocket(url: self.socketURL), text: conflictMessageForID(eventID))
            }
            else {
                handler.writeToSocket(event: event, withID: eventID)
            }
        })
        
        let manager = RapidSocketManager(networkHandler: mockHandler)
        
        let auth = RapidAuthRequest(token: self.testAuthToken)
        manager.authorize(authRequest: auth)
        
        let mutate = RapidDocumentMutation(collectionID: testCollectionName, documentID: "1", value: ["name": "mergeTest", "desc": "description"], cache: nil) { result in
            if case .failure = result {
                XCTFail("Error occured")
            }
            
            var firstTry = true
            let merge = RapidDocumentExecution(collectionID: self.testCollectionName, documentID: "1", delegate: manager, block: { (value) -> RapidExecutionResult in
                if firstTry {
                    firstTry = false
                    return .write(value: ["desc": "desc", "bla": 6])
                }
                else {
                    return .abort
                }
            }, completion: { result in
                if case .failure(let error) = result,
                    case RapidError.executionFailed(let reason) = error,
                    case RapidError.ExecutionError.aborted = reason {
                    
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                }
            })
            
            manager.execute(execution: merge)
        }
        
        manager.mutate(mutationRequest: mutate)
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "mergeTest", "desc": "description"])
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMutateSefeWithWrongEtag() {
        let promise = expectation(description: "Safe mutate")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "testMutateSefeWithWrongEtag"]) { result in
            if case .failure = result {
                XCTFail("Error occured")
            }
            
            self.rapid.collection(named: self.testCollectionName).document(withID: "1").mutate(value: ["name": "errorTest"], etag: Rapid.uniqueID) { result in
                if case .failure(let error) = result,
                    case RapidError.executionFailed(let reason) = error,
                    case RapidError.ExecutionError.writeConflict = reason {
                    
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch(completion: { result in
                        if case .success(let document) = result {
                            XCTAssertEqual(document.id, "1", "Wrong ID")
                            XCTAssertEqual(document.value?["name"] as? String, "testMutateSefeWithWrongEtag", "Wrong value")
                        }
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
    
    func testConcurrencyMergeSafeWithBlock() {
        let promise = expectation(description: "Merge document")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "loadTest"])
        
        var iterations = [Int]()

        let numberOfIterations = 20
        
        runAfter(1) {
            
            for i in 0..<numberOfIterations {
                self.rapid.collection(named: self.testCollectionName).document(withID: "1").execute(
                    block: { doc -> RapidExecutionResult in
                        let count = doc.value?["counter"] as? Int ?? 0
                        return .write(value: ["counter": count+1])
                },
                    completion: { error in
                        self.rapid.collection(named: self.testCollectionName).document(withID: "1").fetch(completion: { result in
                            if case .success(let doc) = result, let counter = doc.value?["counter"] as? Int {

                                iterations.append(i)
                                if counter == numberOfIterations {
                                    runAfter(1, closure: {
                                        promise.fulfill()
                                    })
                                }
                                else if counter > numberOfIterations {
                                    XCTFail("Counter greater than expected")
                                }
                            }
                            else {
                                XCTFail("No counter")
                            }
                        })
                })
            }
        }
        
        waitForExpectations(timeout: TimeInterval(numberOfIterations), handler: { error in print(iterations.sorted())})
    }
    

}
