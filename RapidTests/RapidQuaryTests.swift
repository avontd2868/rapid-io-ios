//
//  RapidQuaryTests.swift
//  Rapid
//
//  Created by Jan on 13/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testOrderingAsc() {
        let promise = expectation(description: "Ordering")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"])
        
        rapid.collection(named: testCollectionName).order(by: RapidOrdering(keyPath: "name", ordering: .ascending)).subscribe { (_, documents) in
            XCTAssertGreaterThan(documents.count, 1, "No documents")
            
            var lastName = ""
            for document in documents {
                XCTAssertGreaterThanOrEqual(document.value?["name"] as? String ?? "", lastName, "Wrong order")
                lastName = document.value?["name"] as? String ?? ""
            }
            
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testOrderingDesc() {
        let promise = expectation(description: "Ordering")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"])
        
        rapid.collection(named: testCollectionName).order(by: RapidOrdering(keyPath: "name", ordering: .descending)).subscribe { (_, documents) in
            XCTAssertGreaterThan(documents.count, 1, "No documents")
            
            var lastName: String?
            for document in documents {
                if let lastName = lastName {
                    XCTAssertLessThanOrEqual(document.value?["name"] as? String ?? "", lastName, "Wrong order")
                }
                else {
                    lastName = document.value?["name"] as? String ?? ""
                }
            }
            
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testOrderByID() {
        let promise = expectation(description: "Ordering")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"])
        
        rapid.collection(named: testCollectionName).order(by: RapidOrdering(keyPath: RapidOrdering.documentIdKey, ordering: .descending)).subscribe { (_, documents) in
            XCTAssertGreaterThan(documents.count, 1, "No documents")
            
            var lastID: String?
            for document in documents {
                if let lastID = lastID {
                    XCTAssertLessThanOrEqual(document.id, lastID, "Wrong order")
                }
                else {
                    lastID = document.id
                }
            }
            
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }
    
    func testOrderingUpdates() {
        let promise = expectation(description: "Ordering")
        Rapid.debugLoggingEnabled = true

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").delete()
        rapid.collection(named: testCollectionName).document(withID: "5").mutate(value: ["name": "test5"])

        var updateNumber = 0
        var numberOfDocuments = 0
        runAfter(1) { 
            self.rapid.collection(named: self.testCollectionName).order(by: RapidOrdering(keyPath: "name", ordering: .descending)).subscribe { (_, documents) in
                XCTAssertGreaterThan(documents.count, 1, "No documents")
                print(documents.map({($0.id, $0.value?["name"] as? String)}))
                var lastName: String?
                for document in documents {
                    if let lastName = lastName {
                        XCTAssertLessThanOrEqual(document.value?["name"] as? String ?? "", lastName, "Wrong order")
                    }

                    lastName = document.value?["name"] as? String ?? ""
                }

                switch updateNumber {
                case 0:
                    XCTAssertEqual(numberOfDocuments, 0, "Wrong number of documents")
                    self.rapid.collection(named: self.testCollectionName).document(withID: "4").mutate(value: ["name": "test4"])
                    
                case 1:
                    XCTAssertEqual(numberOfDocuments, documents.count - 1, "Wrong number of documents")
                    self.rapid.collection(named: self.testCollectionName).document(withID: "5").mutate(value: ["name": "test0"])
                    
                case 2:
                    XCTAssertEqual(numberOfDocuments, documents.count, "Wrong number of documents")
                    self.rapid.collection(named: self.testCollectionName).document(withID: "5").delete()
                    
                case 3:
                    XCTAssertEqual(numberOfDocuments, documents.count + 1, "Wrong number of documents")
                    promise.fulfill()
                    
                default:
                    XCTFail("More updates")
                }
                
                numberOfDocuments = documents.count
                updateNumber += 1
            }
        }
        
        waitForExpectations(timeout: 8, handler: nil)
    }

}
