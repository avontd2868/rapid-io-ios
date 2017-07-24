//
//  RapidPresenceTests.swift
//  Rapid
//
//  Created by Jan on 18/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testMutateOnDisconnect() {
        let promise = expectation(description: "Mutate")

        rapid.collection(named: testCollectionName).document(withID: "disconnect").mutate(value: ["online": true]) { result in
            if case .success = result {
                self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().mutate(value: ["online": false], completion: { result in
                    if case .success = result {
                        self.rapid.goOffline()
                        runAfter(1, closure: {
                            self.rapid.goOnline()
                            self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").fetch(completion: { result in
                                if case .success(let doc) = result {
                                    XCTAssertFalse(doc.value?["online"] as? Bool ?? true, "Wrong value")
                                }
                                else {
                                    XCTFail("Did not fetch")
                                }
                                promise.fulfill()
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMergeOnDisconnect() {
        let promise = expectation(description: "Merge")

        rapid.collection(named: testCollectionName).document(withID: "disconnect").mutate(value: ["online": true]) { result in
            if case .success = result {
                self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().merge(value: ["online": false], completion: { result in
                    if case .success = result {
                        self.rapid.goOffline()
                        runAfter(1, closure: {
                            self.rapid.goOnline()
                            self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").fetch(completion: { result in
                                if case .success(let doc) = result {
                                    XCTAssertFalse(doc.value?["online"] as? Bool ?? true, "Wrong value")
                                }
                                else {
                                    XCTFail("Did not fetch")
                                }
                                promise.fulfill()
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDeleteOnDisconnect() {
        let promise = expectation(description: "Delete")

        rapid.collection(named: testCollectionName).document(withID: "disconnect").mutate(value: ["online": true]) { result in
            if case .success = result {
                self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().delete(completion: { result in
                    if case .success = result {
                        self.rapid.goOffline()
                        runAfter(1, closure: {
                            self.rapid.goOnline()
                            self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").fetch(completion: { result in
                                if case .success(let doc) = result {
                                    XCTAssertNil(doc.value, "Wrong value")
                                }
                                else {
                                    XCTFail("Did not fetch")
                                }
                                promise.fulfill()
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCancelMutateOnDisconnect() {
        let promise = expectation(description: "Mutate")

        rapid.collection(named: testCollectionName).document(withID: "disconnect").mutate(value: ["online": true]) { result in
            if case .success = result {
                var mutateOnDisconnect: RapidWriteRequest?
                mutateOnDisconnect = self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().mutate(value: ["online": false], completion: { result in
                    if case .success = result {
                        mutateOnDisconnect?.cancel()
                        runAfter(1, closure: {
                            self.rapid.goOffline()
                            runAfter(1, closure: {
                                self.rapid.goOnline()
                                self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").fetch(completion: { result in
                                    if case .success(let doc) = result {
                                        XCTAssertTrue(doc.value?["online"] as? Bool ?? false, "Wrong value")
                                    }
                                    else {
                                        XCTFail("Did not fetch")
                                    }
                                    promise.fulfill()
                                })
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCancelMergeOnDisconnect() {
        let promise = expectation(description: "Merge")

        rapid.collection(named: testCollectionName).document(withID: "disconnect").mutate(value: ["online": true]) { result in
            if case .success = result {
                var mutateOnDisconnect: RapidWriteRequest?
                mutateOnDisconnect = self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().merge(value: ["online": false], completion: { result in
                    if case .success = result {
                        mutateOnDisconnect?.cancel()
                        runAfter(1, closure: {
                            self.rapid.goOffline()
                            runAfter(1, closure: {
                                self.rapid.goOnline()
                                self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").fetch(completion: { result in
                                    if case .success(let doc) = result {
                                        XCTAssertTrue(doc.value?["online"] as? Bool ?? false, "Wrong value")
                                    }
                                    else {
                                        XCTFail("Did not fetch")
                                    }
                                    promise.fulfill()
                                })
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCancelDeleteOnDisconnect() {
        let promise = expectation(description: "Delete")

        rapid.collection(named: testCollectionName).document(withID: "disconnect").mutate(value: ["online": true]) { result in
            if case .success = result {
                var mutateOnDisconnect: RapidWriteRequest?
                mutateOnDisconnect = self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().delete(completion: { result in
                    if case .success = result {
                        mutateOnDisconnect?.cancel()
                        runAfter(1, closure: {
                            self.rapid.goOffline()
                            runAfter(1, closure: {
                                self.rapid.goOnline()
                                self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").fetch(completion: { result in
                                    if case .success(let doc) = result {
                                        XCTAssertTrue(doc.value?["online"] as? Bool ?? false, "Wrong value")
                                    }
                                    else {
                                        XCTFail("Did not fetch")
                                    }
                                    promise.fulfill()
                                })
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMutateOnDisconnectPermissionDenied() {
        let promise = expectation(description: "Mutate")

        var initialResponse = true
        self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().mutate(value: ["online": false], completion: { result in
            if initialResponse, case .success = result {
                initialResponse = false
                self.rapid.deauthorize()
            }
            else if !initialResponse, case .failure(let error) = result {
                if case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong response")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMergeOnDisconnectPermissionDenied() {
        let promise = expectation(description: "Mutate")

        var initialResponse = true
        self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().merge(value: ["online": false], completion: { result in
            if initialResponse, case .success = result {
                initialResponse = false
                self.rapid.deauthorize()
            }
            else if !initialResponse, case .failure(let error) = result {
                if case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong response")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDeleteOnDisconnectPermissionDenied() {
        let promise = expectation(description: "Mutate")

        var initialResponse = true
        self.rapid.collection(named: self.testCollectionName).document(withID: "disconnect").onDisconnect().delete(completion: { result in
            if initialResponse, case .success = result {
                initialResponse = false
                self.rapid.deauthorize()
            }
            else if !initialResponse, case .failure(let error) = result {
                if case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong response")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMutateOnConnect() {
        let promise = expectation(description: "Mutate")

        rapid.collection(named: testCollectionName).document(withID: "connect").mutate(value: ["online": false]) { result in
            if case .success = result {
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().mutate(value: ["online": true], completion: { result in
                        if case .success = result {
                            self.rapid.goOnline()
                            runAfter(1, closure: {
                                self.rapid.collection(named: self.testCollectionName).document(withID: "connect").fetch(completion: { result in
                                    if case .success(let doc) = result {
                                        XCTAssertTrue(doc.value?["online"] as? Bool ?? false, "Wrong value")
                                    }
                                    else {
                                        XCTFail("Did not fetch")
                                    }
                                    promise.fulfill()
                                })
                            })
                        }
                        else {
                            XCTFail("Handler not registered")
                            promise.fulfill()
                        }
                    })
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMergeOnConnect() {
        let promise = expectation(description: "Merge")

        rapid.collection(named: testCollectionName).document(withID: "connect").mutate(value: ["online": false]) { result in
            if case .success = result {
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().merge(value: ["online": true], completion: { result in
                        if case .success = result {
                            self.rapid.goOnline()
                            runAfter(1, closure: {
                                self.rapid.collection(named: self.testCollectionName).document(withID: "connect").fetch(completion: { result in
                                    if case .success(let doc) = result {
                                        XCTAssertTrue(doc.value?["online"] as? Bool ?? false, "Wrong value")
                                    }
                                    else {
                                        XCTFail("Did not fetch")
                                    }
                                    promise.fulfill()
                                })
                            })
                        }
                        else {
                            XCTFail("Handler not registered")
                            promise.fulfill()
                        }
                    })
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDeleteOnConnect() {
        let promise = expectation(description: "Delete")
        
        rapid.collection(named: testCollectionName).document(withID: "connect").mutate(value: ["online": false]) { result in
            if case .success = result {
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().delete(completion: { result in
                    if case .success = result {
                        self.rapid.goOnline()
                        runAfter(1, closure: {
                            self.rapid.collection(named: self.testCollectionName).document(withID: "connect").fetch(completion: { result in
                                if case .success(let doc) = result {
                                    XCTAssertNil(doc.value, "Wrong value")
                                }
                                else {
                                    XCTFail("Did not fetch")
                                }
                                promise.fulfill()
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCancelMutateOnConnect() {
        let promise = expectation(description: "Mutate")
        
        rapid.collection(named: testCollectionName).document(withID: "connect").mutate(value: ["online": false]) { result in
            if case .success = result {
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                var mutateOnConnect: RapidWriteRequest?
                mutateOnConnect = self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().mutate(value: ["online": true], completion: { result in
                    if case .success = result {
                        mutateOnConnect?.cancel()
                        runAfter(0.5, closure: {
                            self.rapid.goOnline()
                            runAfter(1, closure: {
                                self.rapid.collection(named: self.testCollectionName).document(withID: "connect").fetch(completion: { result in
                                    if case .success(let doc) = result {
                                        XCTAssertFalse(doc.value?["online"] as? Bool ?? true, "Wrong value")
                                    }
                                    else {
                                        XCTFail("Did not fetch")
                                    }
                                    promise.fulfill()
                                })
                            })
                        })
                    }
                    else {
                        XCTFail("Handler not registered")
                        promise.fulfill()
                    }
                })
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCancelMergeOnConnect() {
        let promise = expectation(description: "Merge")
        
        rapid.collection(named: testCollectionName).document(withID: "connect").mutate(value: ["online": false]) { result in
            if case .success = result {
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    var mutateOnConnect: RapidWriteRequest?
                    mutateOnConnect = self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().merge(value: ["online": true], completion: { result in
                        if case .success = result {
                            mutateOnConnect?.cancel()
                            runAfter(0.5, closure: {
                                self.rapid.goOnline()
                                runAfter(1, closure: {
                                    self.rapid.collection(named: self.testCollectionName).document(withID: "connect").fetch(completion: { result in
                                        if case .success(let doc) = result {
                                            XCTAssertFalse(doc.value?["online"] as? Bool ?? true, "Wrong value")
                                        }
                                        else {
                                            XCTFail("Did not fetch")
                                        }
                                        promise.fulfill()
                                    })
                                })
                            })
                        }
                        else {
                            XCTFail("Handler not registered")
                            promise.fulfill()
                        }
                    })
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCancelDeleteOnConnect() {
        let promise = expectation(description: "Delete")
        
        rapid.collection(named: testCollectionName).document(withID: "connect").mutate(value: ["online": false]) { result in
            if case .success = result {
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    var mutateOnConnect: RapidWriteRequest?
                    mutateOnConnect = self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().delete(completion: { result in
                        if case .success = result {
                            mutateOnConnect?.cancel()
                            runAfter(0.5, closure: {
                                self.rapid.goOnline()
                                runAfter(1, closure: {
                                    self.rapid.collection(named: self.testCollectionName).document(withID: "connect").fetch(completion: { result in
                                        if case .success(let doc) = result {
                                            XCTAssertFalse(doc.value?["online"] as? Bool ?? true, "Wrong value")
                                        }
                                        else {
                                            XCTFail("Did not fetch")
                                        }
                                        promise.fulfill()
                                    })
                                })
                            })
                        }
                        else {
                            XCTFail("Handler not registered")
                            promise.fulfill()
                        }
                    })
                })
            }
            else {
                XCTFail("Mutation failed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMutateOnConnectPermissionDenied() {
        let promise = expectation(description: "Mutate")
        
        var initialResponse = true
        self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().mutate(value: ["online": true], completion: { result in
            if initialResponse, case .success = result {
                initialResponse = false
                self.rapid.deauthorize()
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    self.rapid.goOnline()
                })
            }
            else if !initialResponse, case .failure(let error) = result {
                if case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong response")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testMergeOnConnectPermissionDenied() {
        let promise = expectation(description: "Mutate")
        
        var initialResponse = true
        self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().merge(value: ["online": true], completion: { result in
            if initialResponse, case .success = result {
                initialResponse = false
                self.rapid.deauthorize()
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    self.rapid.goOnline()
                })
            }
            else if !initialResponse, case .failure(let error) = result {
                if case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong response")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDeleteOnConnectPermissionDenied() {
        let promise = expectation(description: "Mutate")
        
        var initialResponse = true
        self.rapid.collection(named: self.testCollectionName).document(withID: "connect").onConnect().delete(completion: { result in
            if initialResponse, case .success = result {
                initialResponse = false
                self.rapid.deauthorize()
                self.rapid.goOffline()
                runAfter(0.5, closure: {
                    self.rapid.goOnline()
                })
            }
            else if !initialResponse, case .failure(let error) = result {
                if case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Wrong error")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong response")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
}
