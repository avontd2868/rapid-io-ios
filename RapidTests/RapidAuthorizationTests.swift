//
//  RapidAuthorizationTests.swift
//  Rapid
//
//  Created by Jan on 07/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {

    func testSubscribeWithoutAuthorization() {
        let promise = expectation(description: "Permission denied")
        
        rapid.collection(named: "test1").subscribe { (error, _) in
            if let error = error as? RapidError, case .permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Did subscribe")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAuthorizeAndSubscribe() {
        let promise = expectation(description: "Authorization")
        
        rapid.authorize(withAccessToken: testAuthToken)
        
        rapid.collection(named: "test1").subscribe { (error, _) in
            if error == nil {
                promise.fulfill()
            }
            else {
                XCTFail("Did not subscribe")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSubscriptionChangeAfterUnsubscription() {
        let promise = expectation(description: "Authorization")
        
        rapid.authorize(withAccessToken: testAuthToken)
        
        var initialValue = true
        
        rapid.collection(named: "test1").subscribe { (error, _) in
            if initialValue {
                initialValue = false
                
                if error == nil {
                    self.rapid.unauthorize()
                }
                else {
                    XCTFail("Did not subscribe")
                }
            }
            else {
                if let error = error as? RapidError, case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Still subscribed")
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testInvalidAuthToken() {
        let promise = expectation(description: "Authorization")
        
        rapid.authorize(withAccessToken: "fakeToken") { (_, error) in
            if let error = error as? RapidError, case RapidError.invalidAuthToken = error {
                promise.fulfill()
            }
            else {
                XCTFail("Authorization passed")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
