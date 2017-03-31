//
//  RapidTests.swift
//  RapidTests
//
//  Created by Jan Schwarz on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

func ==(lhs: [AnyHashable: Any], rhs: [AnyHashable: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

class RapidTests: XCTestCase {
    
    let apiKey = "ws://13.64.77.202:8080"
    let fakeAPIKey = "ws://13.64.77.202:80805/fake"
    let fakeSocketURL = URL(string: "ws://12.13.14.15:1111/fake")!
    let testCollectionName = "iosUnitTests"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        Rapid.deinitialize()

        super.tearDown()
    }
    
    // MARK: Test general stuff
    
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
    }
    
    func testConnectionStates() {
        Rapid.configure(withAPIKey: apiKey+"5/fake")

        let promise = expectation(description: "Rapid forced disconnect")
        
        runAfter(1) {
            XCTAssertEqual(Rapid.connectionState, Rapid.ConnectionState.connecting, "Rapid is not connecting")
            
            do {
                try Rapid.shared().goOffline()
            }
            catch {
                XCTFail("Shared Instance not configured")
            }
            
            runAfter(1) {
                if Rapid.connectionState == .disconnected {
                    
                    do {
                        try Rapid.shared().goOnline()
                    }
                    catch {
                        XCTFail("Shared Instance not configured")
                    }
                    
                    runAfter(1, closure: {
                        if Rapid.connectionState == .connecting {
                            promise.fulfill()
                        }
                        else {
                            XCTFail("Rapid is not connecting")
                        }
                    })
                }
                else {
                    XCTFail("Rapid is not disconnected")
                }
            }
        }
        
        waitForExpectations(timeout: 4, handler: nil)
        
    }
    
    func testReconnect() {
        Rapid.configure(withAPIKey: apiKey)
        
        let promise = expectation(description: "Reconnect")
        
        runAfter(1) { 
            do {
                try Rapid.shared().handler.socketManager.disconnectSocket()
                
                runAfter(2, closure: {

                    if Rapid.connectionState == .connected {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Rapid didn't reconnect")
                    }
                })
            }
            catch {
                XCTFail("Shared Instance not configured")
            }
        }
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testReconnectWithFullQueue() {
        let socket = WebSocket(url: fakeSocketURL)
        let handler = RapidHandler(apiKey: fakeAPIKey)!
        
        let promise = expectation(description: "Reconnect")
        
        runAfter(1) {
            let mutation = RapidDocumentMutation(collectionID: self.testCollectionName, documentID: "1", value: ["name": "testReconnectWithFullQueue"], callback: nil)
            
            handler.socketManager.mutate(mutationRequest: mutation)
            
            handler.socketManager.disconnectSocket(withError: .connectionTerminated(message: "Test"))
            handler.socketManager.websocketDidDisconnect(socket: socket, error: nil)
                
            runAfter(2, closure: {
                
                if handler.state == .connecting {
                    promise.fulfill()
                }
                else {
                    XCTFail("Rapid didn't reconnect")
                }
            })
        }
        
        waitForExpectations(timeout: 4, handler: nil)
    }
}
