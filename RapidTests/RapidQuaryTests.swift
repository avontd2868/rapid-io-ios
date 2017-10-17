//
//  RapidQuaryTests.swift
//  Rapid
//
//  Created by Jan on 13/04/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testContainsFilter() {
        let promise = expectation(description: "Contains")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "testy2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "testy4"]) { _ in
        
            let subscription = self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.contains(keyPath: "name", subString: "sty"))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertGreaterThan(documents.count, 1, "No documents")
                    
                    for document in documents {
                        guard let name = document.value?["name"] as? String, name.contains("sty") else {
                            XCTFail("String doesn't contain substring")
                            break
                        }
                    }
                    
                    promise.fulfill()
                })
            
            if let instance = subscription as? RapidSubscriptionInstance {
                XCTAssertEqual(instance.subscriptionHash, "collection#\(self.testCollectionName)#name-cnt-sty##")
            }
            else {
                XCTFail("No hash")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testStartsWithFilter() {
        let promise = expectation(description: "Contains")

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "ttest1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "ttest4"]) { _ in
        
            let subscription = self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.startsWith(keyPath: "name", prefix: "tt"))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertGreaterThan(documents.count, 1, "No documents")
                    
                    for document in documents {
                        guard let name = document.value?["name"] as? String, name.hasPrefix("tt") else {
                            XCTFail("String doesn't contain substring")
                            break
                        }
                    }
                    
                    promise.fulfill()
                })
            
            if let instance = subscription as? RapidSubscriptionInstance {
                XCTAssertEqual(instance.subscriptionHash, "collection#\(self.testCollectionName)#name-pref-tt##")
            }
            else {
                XCTFail("No hash")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 25, handler: nil)
    }
    
    func testEndsWithFilter() {
        let promise = expectation(description: "Contains")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2tt"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3tt"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"]) { _ in
        
            let subscription = self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.endsWith(keyPath: "name", suffix: "tt"))
                .subscribe(block: { result in
                    
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertGreaterThan(documents.count, 1, "No documents")
                    
                    for document in documents {
                        guard let name = document.value?["name"] as? String, name.hasSuffix("tt") else {
                            XCTFail("String doesn't contain substring")
                            break
                        }
                    }
                    
                    promise.fulfill()
                })
            
            if let instance = subscription as? RapidSubscriptionInstance {
                XCTAssertEqual(instance.subscriptionHash, "collection#\(self.testCollectionName)#name-suf-tt##")
            }
            else {
                XCTFail("No hash")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testArrayContainsFilter() {
        let promise = expectation(description: "Contains")

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1", "tags": [1,2,3]])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2", "tags": [1,3]])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3", "tags": [1,3]])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4", "tags": [1,2,3]]) { _ in
        
            let subscription = self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.arrayContains(keyPath: "tags", value: 2))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertGreaterThan(documents.count, 1, "No documents")
                    
                    for document in documents {
                        guard let tags = document.value?["tags"] as? [Int], tags.contains(2) else {
                            XCTFail("Array doesn't contain value")
                            break
                        }
                    }
                    
                    promise.fulfill()
                })
            
            if let instance = subscription as? RapidSubscriptionInstance {
                XCTAssertEqual(instance.subscriptionHash, "collection#\(self.testCollectionName)#tags-arr-cnt-2##")
            }
            else {
                XCTFail("No hash")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testOrderingAsc() {
        let promise = expectation(description: "Ordering")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"]) { _ in
        
            self.rapid.collection(named: self.testCollectionName)
                .order(by: RapidOrdering(keyPath: "name", ordering: .ascending))
                .fetch(completion: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertGreaterThan(documents.count, 1, "No documents")
                    
                    var lastName = ""
                    for document in documents {
                        XCTAssertGreaterThanOrEqual(document.value?["name"] as? String ?? "", lastName, "Wrong order")
                        lastName = document.value?["name"] as? String ?? ""
                    }
                    
                    promise.fulfill()
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testOrderingDesc() {
        let promise = expectation(description: "Ordering")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"])
        
        rapid.collection(named: testCollectionName)
            .order(by: RapidOrdering(keyPath: "name", ordering: .descending))
            .subscribe(block: { result in
                guard case .success(let documents) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
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
            })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testOrderByID() {
        let promise = expectation(description: "Ordering")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"])
        
        rapid.collection(named: testCollectionName)
            .order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .descending))
            .subscribe(block: { result in
                
                guard case .success(let documents) = result else {
                    XCTFail("Error")
                    promise.fulfill()
                    return
                }
                
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
            })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testOrderingUpdates() {
        let promise = expectation(description: "Ordering")
        
        var updateNumber = 0
        var numberOfDocuments = 0

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").delete()
        rapid.collection(named: testCollectionName).document(withID: "5").mutate(value: ["name": "test5"]) { _ in

            self.rapid.collection(named: self.testCollectionName)
                .order(by: RapidOrdering(keyPath: "name", ordering: .descending))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertGreaterThan(documents.count, 1, "No documents")
                    
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
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testLimit() {
        let promise = expectation(description: "Limit")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"]) { _ in
        
            self.rapid.collection(named: self.testCollectionName)
                .limit(to: 2)
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    XCTAssertEqual(documents.count, 2, "No documents")
                    
                    promise.fulfill()
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testIdKey() {
        let promise = expectation(description: "$id")

        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"]) { _ in
        
            self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.lessThan(keyPath: RapidFilter.docIdKey, value: "4"))
                .order(by: RapidOrdering(keyPath: RapidOrdering.docIdKey, ordering: .descending))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    var lastID: String?
                    for document in documents {
                        if let lastID = lastID {
                            XCTAssertLessThanOrEqual(document.id, lastID, "Wrong order")
                        }
                        else {
                            lastID = document.id
                        }
                        
                        XCTAssertLessThan(document.id, "4", "Wrong filter")
                    }
                    
                    promise.fulfill()
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCreatedKey() {
        let promise = expectation(description: "$created")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.greaterThan(keyPath: RapidFilter.docCreatedAtKey, value: 0))
                .order(by: RapidOrdering(keyPath: RapidOrdering.docCreatedAtKey, ordering: .descending))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    var lastTimestamp: TimeInterval?
                    for document in documents {
                        if let lastTimestamp = lastTimestamp {
                            XCTAssertLessThanOrEqual(document.createdAt?.timeIntervalSince1970 ?? TimeInterval.greatestFiniteMagnitude, lastTimestamp, "Wrong order")
                        }
                        else {
                            lastTimestamp = document.createdAt?.timeIntervalSince1970 ?? -1
                        }
                        XCTAssertGreaterThan(document.createdAt?.timeIntervalSince1970 ?? 0, 0, "Wrong filter")
                    }
                    
                    promise.fulfill()
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testModifiedKey() {
        let promise = expectation(description: "$modified")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "test1"])
        rapid.collection(named: testCollectionName).document(withID: "2").mutate(value: ["name": "test2"])
        rapid.collection(named: testCollectionName).document(withID: "3").mutate(value: ["name": "test3"])
        rapid.collection(named: testCollectionName).document(withID: "4").mutate(value: ["name": "test4"]) { _ in
            
            self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.greaterThan(keyPath: RapidFilter.docModifiedAtKey, value: 0))
                .order(by: RapidOrdering(keyPath: RapidOrdering.docModifiedAtKey, ordering: .descending))
                .subscribe(block: { result in
                    guard case .success(let documents) = result else {
                        XCTFail("Error")
                        promise.fulfill()
                        return
                    }
                    
                    var lastTimestamp: TimeInterval?
                    for document in documents {
                        if let lastTimestamp = lastTimestamp {
                            XCTAssertLessThanOrEqual(document.modifiedAt?.timeIntervalSince1970 ?? TimeInterval.greatestFiniteMagnitude, lastTimestamp, "Wrong order")
                        }
                        else {
                            lastTimestamp = document.modifiedAt?.timeIntervalSince1970 ?? -1
                        }
                        XCTAssertGreaterThan(document.modifiedAt?.timeIntervalSince1970 ?? 0, 0, "Wrong filter")
                    }
                    
                    promise.fulfill()
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testIncludeNewDoc() {
        let promise = expectation(description: "Include")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["orderingNumber": 1]) { _ in
            
            var initial = true
            self.rapid.collection(named: self.testCollectionName)
                .order(by: RapidOrdering(keyPath: "orderingNumber", ordering: .ascending))
                .subscribe(block: { result in
                    if initial {
                        initial = false
                        self.rapid.collection(named: self.testCollectionName).document(withID: "1").mutate(value: ["orderingNumber": 0])
                    }
                    else {
                        if case .success(let documents) = result, let index = documents.index(where: { $0.id == "1" }) {
                            XCTAssertEqual(documents[index].value?["orderingNumber"] as? Int ?? -1, 0, "Wrong value")
                        }
                        else {
                            XCTFail("Document not included")
                        }
                        promise.fulfill()
                    }
            })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testIncludeZeroFilter() {
        let promise = expectation(description: "Include")
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["filterNumber": 1]) { _ in
            
            var initial = true
            self.rapid.collection(named: self.testCollectionName)
                .filter(by: RapidFilter.lessThan(keyPath: "filterNumber", value: 2))
                .subscribe(block: { result in
                    if initial {
                        initial = false
                        self.rapid.collection(named: self.testCollectionName).document(withID: "1").mutate(value: ["filterNumber": 0])
                    }
                    else {
                        if case .success(let documents) = result, let index = documents.index(where: { $0.id == "1" }) {
                            XCTAssertEqual(documents[index].value?["filterNumber"] as? Int ?? -1, 0, "Wrong value")
                        }
                        else {
                            XCTFail("Document not included")
                        }
                        promise.fulfill()
                    }
                })
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
}
