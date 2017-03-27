//
//  RapidTests.swift
//  RapidTests
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

class RapidTests: XCTestCase {
    
    let apiKey = "ws://13.64.77.202:8080"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWrongAPIKey() {
        let rapid = Rapid.getInstance(withAPIKey: "")
        
        XCTAssertNil(rapid, "Rapid with wrong API key initialized")
    }
    
    func testUnconfiguredSingleton() {
        XCTAssertThrowsError(
            try Rapid.shared().collection(named: "users").subscribe { (_, _) in
            }
        )
    }
    
    func testConfiguredSingleton() {
        Rapid.configure(withAPIKey: apiKey)
        let subscription = try? Rapid.shared().collection(named: "users").subscribe { (_, _) in
        }
        
        XCTAssertNotNil(subscription, "Subscription not returned")
        
        Rapid.deinitialize()
    }
    
    func testInstanceHandling() {
        let rapid = Rapid.getInstance(withAPIKey: apiKey)
        let newInstance = Rapid.getInstance(withAPIKey: apiKey)
        
        XCTAssertEqual(rapid?.description, newInstance?.description, "Different instances for one database")
    }
    
    func testInstanceWeakReferencing() {
        var rapid = Rapid.getInstance(withAPIKey: apiKey)
        
        let instanceDescription = rapid?.description
        rapid = nil
        
        rapid = Rapid.getInstance(withAPIKey: apiKey)
        
        XCTAssertNotEqual(instanceDescription, rapid?.description, "Instance wasn't released")
    }
    
    func testRequestTimeout() {
        Rapid.timeout = 2
        Rapid.configure(withAPIKey: apiKey+"5/fake")
        
        let promise = expectation(description: "Mutation timeout")

        Rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { (error, _) in
            if let error = error as? RapidError, case .timeout = error {
                promise.fulfill()
            }
            else {
                XCTFail("Request did not timed out")
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        
        Rapid.deinitialize()
    }
}
