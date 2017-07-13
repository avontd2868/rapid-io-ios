//
//  RapidChannelTests.swift
//  Rapid
//
//  Created by Jan on 07/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testSubscribeToChannel() {
        let promise = expectation(description: "Subscribe to channel")
        
        rapid.channel(named: testChannelName).subscribe { result in
            if case .success(let message) = result {
                XCTAssertEqual(message.message["message"] as? String, "test", "Wrong message")
            }
            else {
                XCTFail("Wrong message")
            }
            promise.fulfill()
        }
        
        runAfter(1) { 
            self.rapid.channel(named: self.testChannelName).publish(message: ["message": "test"])
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testSubscribeToChannels() {
        let promise = expectation(description: "Subscribe to channel")
        
        rapid.channels(nameStartsWith: testChannelName).subscribe { result in
            if case .success(let message) = result {
                XCTAssertEqual(message.message["message"] as? String, "test", "Wrong message")
                XCTAssertEqual(message.channelName, "\(self.testChannelName)test", "Wrong message")
            }
            else {
                XCTFail("Wrong message")
            }
            promise.fulfill()
        }
        
        runAfter(1) {
            self.rapid.channel(named: "\(self.testChannelName)test").publish(message: ["message": "test"])
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnauthorizedPublish() {
        let promise = expectation(description: "Subscribe to channel")
        self.rapid.deauthorize()
        
        self.rapid.channel(named: "fake\(self.testChannelName)").publish(message: ["message": "test"]) { result in
            if case .failure(let error) = result, case .permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong message")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnauthorizedSubscription() {
        let promise = expectation(description: "Subscribe to channel")
        rapid.deauthorize()
        
        rapid.channel(named: "fake\(self.testChannelName)").subscribe { result in
            if case .failure(let error) = result, case .permissionDenied = error {
                promise.fulfill()
            }
            else {
                XCTFail("Wrong message")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUnsubscribe() {
        let promise = expectation(description: "Subscribe to channel")
        
        var initialMessage = true
        var subscription: RapidSubscription?
        
        subscription = rapid.channel(named: testChannelName).subscribe { result in
            if initialMessage {
                initialMessage = false
                if case .success = result {
                    subscription?.unsubscribe()
                    self.rapid.channel(named: self.testChannelName).publish(message: ["message": "test"])
                    runAfter(2, closure: {
                        promise.fulfill()
                    })
                }
                else {
                    XCTFail("Wrong message")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong message")
                promise.fulfill()
            }
        }
        
        runAfter(1) {
            self.rapid.channel(named: self.testChannelName).publish(message: ["message": "test"])
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    
    func testDuplicateChannelSubscriptions() {
        let promise = expectation(description: "Subscribe to channel")
        
        var orderSub1 = 0
        var initialSub2 = true
        var subscription1: RapidChannelSub!
        var subscription2: RapidChannelSub!
        
        subscription1 = RapidChannelSub(channelID: .name(testChannelName)) { (result) in
            if orderSub1 == 0 {
                orderSub1 = 1
                if case .success(let message) = result {
                    XCTAssertEqual(message.message["message"] as? String, "test", "Wrong message")
                }
                else {
                    XCTFail("Wrong message")
                    promise.fulfill()
                }
            }
            else if orderSub1 == 1 {
                orderSub1 = 2
                if case .success(let message) = result {
                    XCTAssertEqual(message.message["message"] as? String, "testtest", "Wrong message")
                    subscription1?.unsubscribe()
                    self.rapid.channel(named: self.testChannelName).publish(message: ["message": "testy"])
                    runAfter(2, closure: {
                        promise.fulfill()
                    })
                }
                else {
                    XCTFail("Wrong message")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong message")
                promise.fulfill()
            }
        }
        subscription2 = RapidChannelSub(channelID: .name(testChannelName)) { (result) in
            if initialSub2 {
                initialSub2 = false
                if case .success(let message) = result {
                    XCTAssertEqual(message.message["message"] as? String, "test", "Wrong message")
                    subscription2?.unsubscribe()
                    self.rapid.channel(named: self.testChannelName).publish(message: ["message": "testtest"])
                }
                else {
                    XCTFail("Wrong message")
                    promise.fulfill()
                }
            }
            else {
                XCTFail("Wrong message")
                promise.fulfill()
            }
        }
        
        rapid.handler.socketManager.subscribe(toChannel: subscription1)
        rapid.handler.socketManager.subscribe(toChannel: subscription2)
        
        runAfter(1) {
            let sub1 = self.rapid.handler.socketManager.activeSubscription(withHash: subscription1.subscriptionHash)
            let sub2 = self.rapid.handler.socketManager.activeSubscription(withHash: subscription2.subscriptionHash)
            
            if sub1 !== sub2 {
                XCTFail("Different handlers")
                promise.fulfill()
            }
            
            self.rapid.channel(named: self.testChannelName).publish(message: ["message": "test"])
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
}
