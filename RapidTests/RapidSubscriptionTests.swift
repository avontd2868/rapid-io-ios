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
    
    func testDuplicateSubscriptions() {
        guard let sub1 = self.rapid.collection(named: "users").document(withID: "1").subscribe(completion: { (_, _) in }) as? RapidDocumentSub else {
            XCTFail("Subscription of wrong type")
            return
        }
        
        guard let sub2 = self.rapid.collection(named: "users").filter(by: RapidFilterSimple(key: RapidFilterSimple.documentIdKey, relation: .equal, value: "1")).subscribe(completion: { (_, _) in }) as? RapidCollectionSub else {
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
        
        runAfter(1) {
            subscription.unsubscribe()
            self.mutate(documentID: "1", value: ["name": "testUnsubscriptiion"])
        }
        
        runAfter(4) { 
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
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
        
        self.rapid.collection(named: testCollectionName).order(by: [RapidOrdering(key: "name", ordering: .ascending)]).subscribe { (_, _) in
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
    
}

// MARK: Helper methods
fileprivate extension RapidTests {
    
    func mutate(documentID: String?, value: [AnyHashable: Any]?) {
        if let id = documentID {
            self.rapid.collection(named: testCollectionName).document(withID: id).mutate(value: value)
        }
        else {
            self.rapid.collection(named: testCollectionName).newDocument().mutate(value: value)
        }
    }
    
}
