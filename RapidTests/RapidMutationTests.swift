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
        
        rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { (error, _) in
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
        
        rapid.collection(named: "users").newDocument().merge(value: ["name": "Jan"]) { (error, _) in
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
        
        document.mutate(value: ["name": "delete"], completion: { error, value in
            if let dict = value as? [AnyHashable: Any], dict["name"] as? String == "delete" {
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

        rapid.authorize(withAccessToken: testAuthToken)
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
}
