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
        Rapid.logLevel = .debug
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
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSubscribeToChannels() {
        Rapid.logLevel = .debug
        let promise = expectation(description: "Subscribe to channel")
        
        rapid.channels(nameStartingWith: testChannelName).subscribe { result in
            if case .success(let message) = result {
                XCTAssertEqual(message.message["message"] as? String, "test", "Wrong message")
                XCTAssertEqual(message.channelID, "\(self.testChannelName)test", "Wrong message")
            }
            else {
                XCTFail("Wrong message")
            }
            promise.fulfill()
        }
        
        runAfter(1) {
            self.rapid.channel(named: "\(self.testChannelName)test").publish(message: ["message": "test"])
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
