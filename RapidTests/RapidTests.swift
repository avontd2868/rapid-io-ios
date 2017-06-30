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
    
    let apiKey = "ZGV2LXdzLXNlcnZpY2UucmFwaWQuaW8="
    let localApiKey = "bG9jYWxob3N0OjgwODA="
    let fakeApiKey = "MTMuNjQuNzcuMjAyOjgwODA1L2Zha2U="
    let socketURL = URL(string: "wss://dev-ws-service.rapid.io")!
    let fakeSocketURL = URL(string: "ws://12.13.14.15:1111/fake")!
    let testCollectionName = "iosUnitTests"
    let testChannelName = "iosUnitTestsChannel"
    
    let testAuthToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJydWxlcyI6W3siY2hhbm5lbCI6eyJwYXR0ZXJuIjoiXmlvcy4qIn0sInJlYWQiOnRydWUsIndyaXRlIjp0cnVlfSx7ImNvbGxlY3Rpb24iOnsicGF0dGVybiI6Il5pb3MuKiJ9LCJyZWFkIjp0cnVlLCJjcmVhdGUiOnRydWUsInVwZGF0ZSI6dHJ1ZSwiZGVsZXRlIjp0cnVlfV19.8fZjAjt4mRq7yUfWWQ4paw93-2ZiKMVM1Y4gstkyULs"
    
    override func setUp() {
        super.setUp()

        rapid = Rapid(apiKey: apiKey)!
        
        rapid.authorize(withToken: testAuthToken)
    }
    
    override func tearDown() {
        Rapid.timeout = 10
        Rapid.defaultTimeout = 300
        Rapid.heartbeatInterval = 30
        rapid.isCacheEnabled = false
        rapid.goOffline()
        rapid = nil
        
        super.tearDown()
    }
    
    // MARK: Test general stuff
    
    func testWrongApiKey() {
        let rapid = Rapid.getInstance(withApiKey: "")
        
        XCTAssertNil(rapid, "Rapid with wrong API key initialized")
    }
    
    func testUnconfiguredSingleton() {
        XCTAssertThrowsError(
            try Rapid.shared().collection(named: "users").subscribe(block: { _ in
                
            })
        )
    }
    
    func testConfiguredSingleton() {
        Rapid.configure(withApiKey: fakeApiKey)
        
        XCTAssertNotNil(Rapid.connectionState, "Wrong connection state")
        
        Rapid.goOffline()
        Rapid.goOnline()
        
        Rapid.unsubscribeAll()
        
        XCTAssertNotNil(Rapid.collection(named: testCollectionName), "Collection not returned")
        
        Rapid.deinitialize()
    }
    
    func testInstanceHandling() {
        let rapid = Rapid.getInstance(withApiKey: apiKey)
        let newInstance = Rapid.getInstance(withApiKey: apiKey)
        
        XCTAssertEqual(rapid?.description, newInstance?.description, "Different instances for one database")
    }
    
    func testInstanceWeakReferencing() {
        var rapid = Rapid.getInstance(withApiKey: fakeApiKey)
        
        let instanceDescription = rapid?.description
        rapid = nil
        
        rapid = Rapid.getInstance(withApiKey: fakeApiKey)
        
        XCTAssertNotEqual(instanceDescription, rapid?.description, "Instance wasn't released")
    }
    
    func testMultipleInstances() {
        let rapid = Rapid.getInstance(withApiKey: apiKey)
        let newInstance = Rapid.getInstance(withApiKey: fakeApiKey)
        
        XCTAssertNotEqual(rapid?.description, newInstance?.description, "Same instances for different databases")
    }
    
    func testConnectionStates() {
        let rapid = Rapid.getInstance(withApiKey: fakeApiKey)!
        
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
        let collection = RapidCollectionRef(id: testCollectionName, handler: nil)
        
        XCTAssertThrowsError(try collection.getSocketManager(), "Collection didn't throw")
        XCTAssertThrowsError(try collection.document(id: "1"), "Collection didn't throw")
    }
    
    func testDocumentWithoutHandler() {
        let document = RapidDocumentRef(id: "1", inCollection: testCollectionName, handler: nil)
        
        XCTAssertThrowsError(try document.getSocketManager(), "Document didn't throw")
    }
    
    func testDocumentsInitialization() {
        XCTAssertNil(RapidDocument(existingDocJson: [1,2,3], collectionID: "1"), "Documents initialized")
        XCTAssertNil(RapidDocument(existingDocJson: ["id": 6], collectionID: "1"), "Documents initialized")
        
        let doc = [
            "id": "1",
            "crt": "a",
            "crt-ts": 0.0,
            "mod-ts": 0.0,
            "etag": "1234",
            "body": [
                "name": "testDocumentsInitialization"
            ]
            ] as [String : Any]
        let document = RapidDocument(existingDocJson: doc, collectionID: "1")
        
        XCTAssertEqual(document?.id, "1", "Wrong Document")
        XCTAssertEqual(document?.collectionName, "1", "Wrong Document")
        XCTAssertEqual(document?.etag, "1234", "Wrong Document")
        XCTAssertEqual(document?.value?["name"] as? String, "testDocumentsInitialization", "Wrong document")
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
        
        let mockHandler = MockNetworkHandler(socketURL: socketURL, writeCallback: { (handler, event, eventID) in
            if event is RapidEmptyRequest && (try? event.serialize(withIdentifiers: [:])) != nil {
                promise.fulfill()
            }
            else {
                handler.writeToSocket(event: event, withID: eventID)
            }
        })
        
        let socketManager = RapidSocketManager(networkHandler: mockHandler)
        socketManager.goOnline()
        
        waitForExpectations(timeout: 6, handler: nil)
    }
    
    func testServerOffset() {
        let promise = expectation(description: "Server timestamp")
        
        rapid.serverTimeOffset { result in
            if case .success(let offset) = result {
                XCTAssertLessThan(abs(offset), 10, "Offset too large")
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testConnectionRequestTimeout() {
        Rapid.timeout = nil
        Rapid.defaultTimeout = 2
        
        let promise = expectation(description: "Events request")
        
        let socket = WebSocket(url: fakeSocketURL)
        
        var connectionID: String?
        let mockHandler = MockNetworkHandler(socketURL: self.fakeSocketURL, writeCallback: { (handler, event, eventID) in
            if let event = event as? RapidConnectionRequest, let conID = connectionID {
                XCTAssertNotEqual(conID, event.connectionID, "Same connection ID")
                promise.fulfill()
            }
            else if let event = event as? RapidConnectionRequest {
                connectionID = event.connectionID
            }
        }, goOnlineCallback: { handler in
            handler.websocketDidConnect(socket: socket)
        })
        
        let manager = RapidSocketManager(networkHandler: mockHandler)
        
        runAfter(1) {
            XCTAssertEqual(manager.networkHandler.state, .connected)
        }
        
        waitForExpectations(timeout: 6, handler: nil)
    }
    
    func testSendingEventsInQueueAfterReconnect() {
        let promise = expectation(description: "Nop request")
        
        let socket = WebSocket(url: fakeSocketURL)
        
        var firstOnlineRequest = true
        
        var conReq = false
        var subReq = false
        var mutReq = false
        var merReq = false
        
        let mockHandler = MockNetworkHandler(socketURL: self.fakeSocketURL, writeCallback: { (handler, event, eventID) in
            if event is RapidConnectionRequest {
                if conReq {
                    XCTFail("Second connection request")
                }
                else {
                    conReq = true
                }
            }
            else if event is RapidSubscriptionManager {
                if conReq && !subReq {
                    subReq = true
                }
                else {
                    XCTFail("Wrong order")
                }
            }
            else if event is RapidDocumentMutation {
                if conReq && subReq && !mutReq {
                    mutReq = true
                }
                else {
                    XCTFail("Wrong order")
                }
            }
            else if event is RapidDocumentMerge {
                if conReq && subReq && mutReq && !merReq {
                    merReq = true
                    runAfter(1, closure: {
                        conReq = false
                        promise.fulfill()
                    })
                }
                else {
                    XCTFail("Wrong order")
                }
            }
            else if conReq && subReq && mutReq && merReq {
                XCTFail("More requests")
            }
        }, goOnlineCallback: { handler in
            if firstOnlineRequest {
                firstOnlineRequest = false
                runAfter(2, closure: {
                    handler.delegate?.socketDidDisconnect(withError: nil)
                })
            }
            else {
                handler.websocketDidConnect(socket: socket)
            }
        })
        
        let manager = RapidSocketManager(networkHandler: mockHandler)
        
        let subscription = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil, handlerWithChanges: nil)
        manager.subscribe(toCollection: subscription)
        manager.subscribe(toCollection: RapidDocumentSub(collectionID: testCollectionName, documentID: "1", handler: nil))
        manager.mutate(mutationRequest: RapidDocumentMutation(collectionID: testCollectionName, documentID: "2", value: [:], cache: nil, completion: nil))
        manager.mutate(mutationRequest: RapidDocumentMerge(collectionID: testCollectionName, documentID: "3", value: [:], cache: nil, completion: nil))
        manager.sendEmptyRequest()
        subscription.unsubscribe()
        
        waitForExpectations(timeout: 6, handler: nil)
    }

    func testSubscriptionReregistration() {
        let promise = expectation(description: "Register request")
        
        let socket = WebSocket(url: fakeSocketURL)
        
        var shouldConnect = true
        
        let subscription1 = RapidDocumentSub(collectionID: testCollectionName, documentID: "1", handler: nil)
        let subscription2 = RapidCollectionSub(collectionID: testCollectionName, filter: nil, ordering: nil, paging: nil, handler: nil, handlerWithChanges: nil)
        let subscription3 = RapidDocumentSub(collectionID: testCollectionName, documentID: "2", handler: nil)
        let subHash = subscription2.subscriptionHash
        let mutatationDocumentID = "2"
        var acknowledgeAll = false
        
        var lastSubscription: RapidSubscriptionManager?
        var lastMutation: RapidDocumentMutation?
        
        let mockHandler = MockNetworkHandler(socketURL: self.fakeSocketURL, writeCallback: { (handler, event, eventID) in
            if acknowledgeAll {
                if let subscription = event as? RapidSubscriptionManager {
                    switch subscription.subscriptionHash {
                    case subscription1.subscriptionHash:
                        XCTAssertNil(lastSubscription, "wrong order")
                        XCTAssertNil(lastMutation, "wrong order")
                        lastSubscription = subscription
                        lastMutation = nil
                        
                    case subscription2.subscriptionHash:
                        XCTAssertEqual(lastSubscription?.subscriptionHash, subscription1.subscriptionHash, "wrong order")
                        lastSubscription = subscription
                        lastMutation = nil
                        
                    case subscription3.subscriptionHash:
                        XCTAssertEqual(lastMutation?.documentID, "3", "wrong order")
                        lastSubscription = subscription
                        lastMutation = nil
                        promise.fulfill()
                        
                    default:
                        XCTFail("Another subscription")
                    }
                }
                else if let mutation = event as? RapidDocumentMutation {
                    switch mutation.documentID {
                    case "2":
                        XCTAssertEqual(lastSubscription?.subscriptionHash, subHash, "wrong order")
                        lastSubscription = nil
                        lastMutation = mutation
                        
                    case "3":
                        XCTAssertEqual(lastMutation?.documentID, "2", "wrong order")
                        lastSubscription = nil
                        lastMutation = mutation
                        
                    default:
                        XCTFail("Another mutation")
                    }
                }
            }
            else {
                if let subscription = event as? RapidSubscriptionManager {
                    if subscription.subscriptionHash != subHash {
                        handler.delegate?.handlerDidReceive(message: RapidServerAcknowledgement(eventID: eventID))
                    }
                }
                else if let mutation = event as? RapidDocumentMutation {
                    if mutation.documentID != mutatationDocumentID {
                        handler.delegate?.handlerDidReceive(message: RapidServerAcknowledgement(eventID: eventID))
                    }
                }
                else {
                    handler.delegate?.handlerDidReceive(message: RapidServerAcknowledgement(eventID: eventID))
                }
            }
        }, goOnlineCallback: { handler in
            if shouldConnect {
                handler.websocketDidConnect(socket: socket)
            }
        })
        
        let manager = RapidSocketManager(networkHandler: mockHandler)
        
        runAfter(0.5) { 
            manager.subscribe(toCollection: subscription1)
            manager.mutate(mutationRequest: RapidDocumentMutation(collectionID: self.testCollectionName, documentID: "1", value: [:], cache: nil, completion: nil))
            manager.subscribe(toCollection: subscription2)
            manager.mutate(mutationRequest: RapidDocumentMutation(collectionID: self.testCollectionName, documentID: mutatationDocumentID, value: [:], cache: nil, completion: nil))
            manager.goOffline()
            runAfter(0.5, closure: {
                manager.mutate(mutationRequest: RapidDocumentMutation(collectionID: self.testCollectionName, documentID: "3", value: [:], cache: nil, completion: nil))
                manager.subscribe(toCollection: subscription3)
                shouldConnect = false
                manager.goOnline()
                runAfter(0.5, closure: {
                    shouldConnect = true
                    acknowledgeAll = true
                    mockHandler.delegate?.socketDidDisconnect(withError: RapidError.connectionTerminated(message: "Termiantion"))
                })
            })
        }
        
        waitForExpectations(timeout: 6, handler: nil)
    }
    
    func testDictionaryMerge() {
        var dictionary: [AnyHashable: Any] = [
            "att1": "val",
            "att2": [1,2,3],
            "att3": [
                "att1": "val",
                "att2": [432]
            ]
        ]
        
        dictionary.merge(with: [
            "att2": [2,3,4],
            "att4": true
            ])
        
        XCTAssertTrue(dictionary == [
            "att1": "val",
            "att2": [2,3,4],
            "att4": true,
            "att3": [
                "att1": "val",
                "att2": [432]
            ]
            ], "Wrong merge")
        
        dictionary.merge(with: ["att1": NSNull()])
        
        XCTAssertTrue(dictionary == [
            "att2": [2,3,4],
            "att4": true,
            "att3": [
                "att1": "val",
                "att2": [432]
            ]
            ], "Wrong merge")
        
        dictionary.merge(with: [
            "att3": [
                "att3": true
            ]
            ])
        
        XCTAssertTrue(dictionary == [
            "att2": [2,3,4],
            "att4": true,
            "att3": [
                "att1": "val",
                "att2": [432],
                "att3": true
            ]
            ], "Wrong merge")
    }
}

protocol MockNetworkHandlerDelegate: class {
    func didWrite(event: RapidSocketManager.Event, withID eventID: String)
}

class MockNetworkHandler: RapidNetworkHandler {
    
    let writeCallback: ((_ handler: MockNetworkHandler, _ event: RapidSocketManager.Event, _ id: String) -> Void)?
    let goOnlineCallback: ((_ handler: MockNetworkHandler) -> Void)?
    let goOfflineCallback: ((_ handler: MockNetworkHandler) -> Void)?
    
    init(socketURL: URL,
         writeCallback: ((_ handler: MockNetworkHandler, _ event: RapidSocketManager.Event, _ id: String) -> Void)? = nil,
         goOnlineCallback: ((_ handler: MockNetworkHandler) -> Void)? = nil,
         goOfflineCallback: ((_ handler: MockNetworkHandler) -> Void)? = nil) {
        
        self.writeCallback = writeCallback
        self.goOnlineCallback = goOnlineCallback
        self.goOfflineCallback = goOfflineCallback
        
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
    
    func writeToSocket(event: RapidSocketManager.Event, withID eventID: String) {
        super.write(event: event, withID: eventID)
    }
    
    override func goOnline() {
        if let callback = goOnlineCallback {
            callback(self)
        }
        else {
            super.goOnline()
        }
    }
    
    override func goOffline() {
        if let callback = goOfflineCallback {
            callback(self)
        }
        else {
            super.goOffline()
        }
    }
}

class MockNetworkHandlerDelegateObject: RapidNetworkHandlerDelegate {
    
    let connectCallback: (() -> Void)?
    let disconnectCallback: ((_ error: RapidError?) -> Void)?
    let responseCallback: ((_ message: RapidServerMessage) -> Void)?
    
    init(connectCallback: (() -> Void)? = nil, disconnectCallback: ((_ error: RapidError?) -> Void)? = nil, responseCallback: ((_ message: RapidServerMessage) -> Void)? = nil) {
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
    
    func handlerDidReceive(message: RapidServerMessage) {
        responseCallback?(message)
    }
}
