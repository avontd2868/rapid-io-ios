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

    func testSubscribeWituhoutAuthorization() {
        let promise = expectation(description: "Permission denied")
        rapid.deauthorize()
        
        rapid.collection(named: "test1").subscribe(block: { result in
            if case .failure(let error) = result, case .permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Did subscribe")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testAuthorizeAndSubscribe() {
        let promise = expectation(description: "Authorization")
        
        XCTAssertEqual(rapid.authorization?.token, testAuthToken)

        rapid.collection(named: testCollectionName).subscribe(block: { result in
            if case .success = result {
                promise.fulfill()
            }
            else {
                XCTFail("Did not subscribe")
                promise.fulfill()
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCollectionSubscriptionCancelAfterUnsubscription() {
        let promise = expectation(description: "Authorization")
        
        var initialValue = true
        
        rapid.collection(named: testCollectionName).subscribe(block: { result in
            if initialValue {
                initialValue = false
                
                if case .success = result {
                    self.rapid.deauthorize()
                }
                else {
                    XCTFail("Did not subscribe")
                    promise.fulfill()
                }
            }
            else {
                if case .failure(let error) = result, case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Still subscribed")
                    promise.fulfill()
                }
            }
        })
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testChannelSubscriptionCancelAfterUnsubscription() {
        let promise = expectation(description: "Authorization")
        
        var initialValue = true
        
        rapid.channel(named: testChannelName).subscribe { result in
            if initialValue {
                initialValue = false
                
                if case .success = result {
                    self.rapid.deauthorize()
                }
                else {
                    XCTFail("Did not subscribe")
                    promise.fulfill()
                }
            }
            else {
                if case .failure(let error) = result, case .permissionDenied = error {
                    promise.fulfill()
                }
                else {
                    XCTFail("Still subscribed")
                    promise.fulfill()
                }
            }
        }
        
        rapid.channel(named: testChannelName).publish(message: ["test": "test"])
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testInvalidAuthToken() {
        let promise = expectation(description: "Authorization")

        rapid.authorize(withToken: "fakeToken") { result in
            if case .failure(let error) = result, case RapidError.invalidAuthToken = error {
                promise.fulfill()
            }
            else {
                XCTFail("Authorization passed")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDeauthorizeFail() {
        let promise = expectation(description: "Fail unauth")
        
        let mockHandler = MockNetworkHandler(socketURL: self.socketURL, writeCallback: { (handler, event, eventID) in
            if event is RapidDeauthRequest {
                handler.delegate?.handlerDidReceive(message: RapidErrorInstance(eventID: eventID, error: .permissionDenied(message: "test")))
            }
            else {
                handler.writeToSocket(event: event, withID: eventID)
            }
        })
        
        let socketManager = RapidSocketManager(networkHandler: mockHandler)
        
        let deauth = RapidDeauthRequest { result in
            if case .failure(let error) = result, case .permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Did unauthorize")
                promise.fulfill()
            }
        }
        
        socketManager.deauthorize(deauthRequest: deauth)
        
        waitForExpectations(timeout: 15, handler: nil)
    }
}
