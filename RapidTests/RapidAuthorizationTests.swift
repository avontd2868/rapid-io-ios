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
        
        XCTAssertEqual(rapid.authorization?.accessToken, testAuthToken)
        
        rapid.collection(named: testCollectionName).subscribe { (error, _) in
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
        
        var initialValue = true
        
        rapid.collection(named: testCollectionName).subscribe { (error, _) in
            if initialValue {
                initialValue = false
                
                if error == nil {
                    self.rapid.deauthorize()
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
    
    func testDeauthorizeFail() {
        let promise = expectation(description: "Fail unauth")
        
        let mockHandler = MockNetworkHandler(socketURL: self.socketURL, writeCallback: { (handler, event, eventID) in
            if event is RapidDeauthRequest {
                handler.delegate?.handlerDidReceive(response: RapidErrorInstance(eventID: eventID, error: .permissionDenied(message: "test")))
            }
            else {
                handler.writeToSocket(event: event, withID: eventID)
            }
        })
        
        let socketManager = RapidSocketManager(networkHandler: mockHandler)
        
        let deauth = RapidDeauthRequest { (success, error) in
            if !success, let error = error as? RapidError, case .permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Did unauthorize")
            }
        }
        
        socketManager.deauthorize(deauthRequest: deauth)
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
