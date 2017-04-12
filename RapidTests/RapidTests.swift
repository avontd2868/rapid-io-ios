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
    
    var rapid: Rapid!
    
    let apiKey = "ws://13.64.77.202:8080"
    let fakeAPIKey = "ws://13.64.77.202:80805/fake"
    let socketURL = URL(string: "ws://13.64.77.202:8080")!
    let fakeSocketURL = URL(string: "ws://12.13.14.15:1111/fake")!
    let testCollectionName = "iosUnitTests"
    
    override func setUp() {
        super.setUp()
        
        rapid = Rapid(apiKey: "ws://13.64.77.202:8080")!
    }
    
    override func tearDown() {
        Rapid.timeout = 10
        Rapid.defaultTimeout = 300
        Rapid.heartbeatInterval = 30
        rapid = nil
        
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
        Rapid.configure(withAPIKey: fakeAPIKey)
        
        XCTAssertNotNil(Rapid.connectionState, "Wrong connection state")
        
        Rapid.goOffline()
        Rapid.goOnline()
        
        Rapid.unsubscribeAll()
        
        XCTAssertNotNil(Rapid.collection(named: testCollectionName), "Collection not returned")
        
        Rapid.deinitialize()
    }
    
    func testInstanceHandling() {
        let rapid = Rapid.getInstance(withAPIKey: apiKey)
        let newInstance = Rapid.getInstance(withAPIKey: apiKey)
        
        XCTAssertEqual(rapid?.description, newInstance?.description, "Different instances for one database")
    }
    
    func testInstanceWeakReferencing() {
        var rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)
        
        let instanceDescription = rapid?.description
        rapid = nil
        
        rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)
        
        XCTAssertNotEqual(instanceDescription, rapid?.description, "Instance wasn't released")
    }
    
    func testMultipleInstances() {
        let rapid = Rapid.getInstance(withAPIKey: apiKey)
        let newInstance = Rapid.getInstance(withAPIKey: fakeAPIKey)
        
        XCTAssertNotEqual(rapid?.description, newInstance?.description, "Same instances for different databases")
    }
    
    func testRequestTimeout() {
        let rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)!
        Rapid.timeout = 2
        
        let promise = expectation(description: "Mutation timeout")

        rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { (error, _) in
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
        let rapid = Rapid.getInstance(withAPIKey: fakeAPIKey)!
        
        let promise = expectation(description: "Rapid forced disconnect")
        
        runAfter(1) {
            XCTAssertEqual(rapid.connectionState, Rapid.ConnectionState.connecting, "Rapid is not connecting")
            
            rapid.goOffline()
            
            runAfter(1) {
                if rapid.connectionState == .disconnected {
                    
                    rapid.goOnline()
                    
                    runAfter(1, closure: {
                        if rapid.connectionState == .connecting {
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
        let promise = expectation(description: "Reconnect")
        
        runAfter(1) { 
            self.rapid.handler.socketManager.networkHandler.restartSocket(afterError: nil)
            
            runAfter(3, closure: {
                
                if self.rapid.connectionState == .connected {
                    promise.fulfill()
                }
                else {
                    XCTFail("Rapid didn't reconnect")
                }
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testReconnectWhenNotConnected() {
        Rapid.defaultTimeout = 2
        
        let promise = expectation(description: "Reconnect")
        
        let networkHandler = RapidNetworkHandler(socketURL: fakeSocketURL)

        let delegateObject = MockNetworkHandlerDelegateObject(connectCallback: {
            XCTFail("Socket connected")
        }, disconnectCallback: { (error) in
            if let error = error, case .timeout = error {
                networkHandler.goOnline()
                
                runAfter(1, closure: {
                    XCTAssertEqual(networkHandler.state, .connecting, "Wrong connection state")
                    promise.fulfill()
                })
            }
            else {
                XCTFail("Disconnect without error")
            }
        }) { _ in
            XCTFail("Received response")
        }
        
        networkHandler.delegate = delegateObject
        
        networkHandler.goOnline()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testReconnectionAfterTerminated() {
        let promise = expectation(description: "Reconnect")
        
        runAfter(1) {
            self.rapid.goOffline()
            
            runAfter(2, closure: {
                self.rapid.goOnline()
                
                runAfter(5, closure: {
                    
                    if self.rapid.connectionState == .connected {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Rapid didn't reconnect")
                    }
                })
            })
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCollectionWithoutHandler() {
        let collection = RapidCollection(id: testCollectionName, handler: nil)
        
        XCTAssertThrowsError(try collection.getSocketManager(), "Collection didn't throw")
        XCTAssertThrowsError(try collection.document(id: "1"), "Collection didn't throw")
    }
    
    func testDocumentWithoutHandler() {
        let document = RapidDocument(id: "1", inCollection: testCollectionName, handler: nil)
        
        XCTAssertThrowsError(try document.getSocketManager(), "Document didn't throw")
    }
    
    func testSnapshotInitialization() {
        XCTAssertNil(RapidDocumentSnapshot(json: [1,2,3]), "Snapshot initialized")
        XCTAssertNil(RapidDocumentSnapshot(json: ["id": 6]), "Snapshot initialized")
        
        let snapshot = RapidDocumentSnapshot(id: "1", value: ["name": "testSnapshotInitialization"], etag: "1234")
        
        XCTAssertEqual(snapshot.id, "1", "Wrong snapshot")
        XCTAssertEqual(snapshot.etag, "1234", "Wrong snapshot")
        XCTAssertEqual(snapshot.value?["name"] as? String, "testSnapshotInitialization", "Wrong snapshot")
    }
    
    func testErrorInstanceInitialization() {
        XCTAssertNil(RapidErrorInstance(json: [1234]), "Error initialized")
        XCTAssertNil(RapidErrorInstance(json: ["err-type": "test"]), "Error initialized")
        
        let eventID = Rapid.uniqueID
        let errorInstance = RapidErrorInstance(json: ["evt-id": eventID])
        
        guard let error = errorInstance else {
            XCTFail("Error not initialized")
            return
        }
        
        XCTAssertEqual(error.eventID, eventID, "Wrong event ID")
        
        switch error.error {
        case .default:
            break
        default:
            XCTFail("Wrong error")
        }
        
        let errorInstance2 = RapidErrorInstance(json: ["evt-id": eventID, "err-type": "internal-error", "err-msg": "test"])
        
        switch errorInstance2?.error {
        case .some(RapidError.server(let message)):
            XCTAssertEqual(message, "test", "Error messages not equal")
            
        default:
            XCTFail("Wrong error")
        }
    }
    
    func testWeakReferencedObjects() {
        var set = Set<WRO<NSDictionary>>()
        
        var dictionary = NSDictionary(dictionary: ["name": "test1"])
        set.insert(WRO(object: dictionary))
        set.insert(WRO(object: dictionary))
        set = Set(set.filter({ $0.object != nil }))
        
        XCTAssertEqual(set.count, 1)
        
        let secondDictionary = NSDictionary(dictionary: ["name": "test2"])
        set.insert(WRO(object: secondDictionary))
        set = Set(set.filter({ $0.object != nil }))
        
        XCTAssertEqual(set.count, 2)
        
        dictionary = NSDictionary()
        set.insert(WRO(object: NSDictionary(dictionary: ["name": "test3"])))
        set = Set(set.filter({ $0.object != nil }))
        
        XCTAssertEqual(set.count, 1)
    }
    
    func testNopRequest() {
        Rapid.heartbeatInterval = 3
        
        let promise = expectation(description: "Nop request")
        
        let mockHandler = MockNetworkHandler(socketURL: self.socketURL) { (handler, event, eventID) in
            if event is RapidEmptyRequest {
                promise.fulfill()
            }
            
            handler.write(event: event, withID: eventID)
        }
        
        let socketManager = RapidSocketManager(networkHandler: mockHandler)
        socketManager.goOnline()
        
        waitForExpectations(timeout: 6, handler: nil)
    }
    
    func testConnectionRequestTimeout() {
        Rapid.timeout = 3
        
        let promise = expectation(description: "Nop request")
        
        let mockHandler = MockNetworkHandler(socketURL: self.socketURL) { (handler, event, eventID) in
            if event is RapidEmptyRequest {
                promise.fulfill()
            }
        }
        
        let socketManager = RapidSocketManager(networkHandler: mockHandler)
        socketManager.goOnline()
        
        waitForExpectations(timeout: 6, handler: nil)
    }
}

protocol MockNetworkHandlerDelegate: class {
    func didWrite(event: RapidSocketManager.Event, withID eventID: String)
}

class MockNetworkHandler: RapidNetworkHandler {
    
    let writeCallback: ((_ handler: RapidNetworkHandler, _ event: RapidSocketManager.Event, _ id: String) -> Void)?
    
    init(socketURL: URL, writeCallback: @escaping (_ handler: RapidNetworkHandler, _ event: RapidSocketManager.Event, _ id: String) -> Void) {
        self.writeCallback = writeCallback
        
        super.init(socketURL: socketURL)
    }
    
    override func write(event: RapidSocketManager.Event, withID eventID: String) {
        if let callback = writeCallback {
            callback(self, event, eventID)
        }
        else {
            super.write(event: event, withID: eventID)
        }
    }
}

class MockNetworkHandlerDelegateObject: RapidNetworkHandlerDelegate {
    
    let connectCallback: (() -> Void)?
    let disconnectCallback: ((_ error: RapidError?) -> Void)?
    let responseCallback: ((_ response: RapidResponse) -> Void)?
    
    init(connectCallback: (() -> Void)? = nil, disconnectCallback: ((_ error: RapidError?) -> Void)? = nil, responseCallback: ((_ response: RapidResponse) -> Void)? = nil) {
        self.connectCallback = connectCallback
        self.disconnectCallback = disconnectCallback
        self.responseCallback = responseCallback
    }
    
    func socketDidConnect() {
        connectCallback?()
    }
    
    func socketDidDisconnect(withError error: RapidError?) {
        disconnectCallback?(error)
    }
    
    func handlerDidReceive(response: RapidResponse) {
        responseCallback?(response)
    }
}
