//
//  SocketManager.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Delegate for informing about connection state change
protocol RapidConnectionStateChangeDelegate: class {
    func connectionStateChanged(currentState: Rapid.ConnectionState)
}

/// Class for websocket communication management
class SocketManager {
    
    typealias Event = RapidSocketEvent & RapidSerializable
    typealias Request = RapidRequest & Event
    
    /// Time interval between heartbeats
    fileprivate let heartbeatInterval: TimeInterval = 30
    
    /// ID that identifies a websocket connection to this client for reconnecting purposes
    fileprivate(set) var connectionID: String?
    
    /// State of a websocket connection
    fileprivate var state: Rapid.ConnectionState = .disconnected {
        didSet {
            let state = self.state
            mainQueue.async { [weak self] in
                self?.connectionStateDelegate?.connectionStateChanged(currentState: state)
            }
        }
    }
    /// Delegate for informing about connection state change
    weak var connectionStateDelegate: RapidConnectionStateChangeDelegate?
    
    /// Dedicated threads
    fileprivate let websocketQueue: DispatchQueue
    fileprivate let parseQueue: DispatchQueue
    fileprivate let mainQueue = DispatchQueue.main
    
    /// Websocket object
    fileprivate let socket: WebSocket
    
    /// Queue of events that are about to be sent to the server
    fileprivate var eventQueue: [Event] = []
    
    /// Dictionary of events that have been already sent to the server and a response is awaited. Events are identified by an event ID.
    fileprivate var pendingRequests: [String: Request] = [:]
    
    /// Dictionary of registered subscriptions. Either active or those that are waiting for acknowledgement from the server. Subscriptions are identified by a subscriptioon ID
    fileprivate var activeSubscriptions: [String: RapidSubscriptionHandler] = [:]
    
    /// Socket was intentionally terminated
    fileprivate var socketTerminated = false
    
    /// Error that led to forced websocket reconnection
    fileprivate var reconnectionError: RapidError?
    
    /// Timer that limits maximum time span when websocket connection is trying to be established
    fileprivate var socketConnectTimer: Timer?
    
    /// Timer that limits maximum time without any websocket communication to reveal disconnections
    fileprivate var heartbeatTimer: Timer?
    
    init(socketURL: URL) {
        self.websocketQueue = DispatchQueue(label: "RapidWebsocketQueue-\(socketURL.lastPathComponent)", attributes: [])
        self.parseQueue = DispatchQueue(label: "RapidParseQueue-\(socketURL.lastPathComponent)", attributes: [])
        self.socket = WebSocket(url: socketURL)
        self.socket.delegate = self
        
        websocketQueue.async { [weak self] in
            self?.createConnection()
        }
    }
    
    deinit {
        deinitialize()
    }
    
    func deinitialize() {
        sendDisconnectionRequest()
        destroySocket()
    }
    
    /// Send mutation event
    ///
    /// - Parameter mutationRequest: Mutation object
    func mutate<T: RapidMutationRequest>(mutationRequest: T) {
        websocketQueue.async { [weak self] in
            self?.post(event: mutationRequest)
        }
    }
    
    /// Send merge event
    ///
    /// - Parameter mergeRequest: Merge object
    func merge<T: RapidMergeRequest>(mergeRequest: T) {
        websocketQueue.async { [weak self] in
            self?.post(event: mergeRequest)
        }
    }
    
    /// Send register subscription event
    ///
    /// - Parameter subscription: Subscription object
    func subscribe(_ subscription: RapidSubscriptionInstance) {
        websocketQueue.async { [weak self] in
            guard let queue = self?.parseQueue else {
                return
            }
            
            // If a subscription that listens to the same set of data has been already registered just register the new listener locally
            if let activeSubscription = self?.activeSubscription(withHash: subscription.subscriptionHash) {
                activeSubscription.registerSubscription(subscription: subscription)
            }
            else {
                // Create an unique ID that identifies the subscription
                let subscriptionID = Generator.uniqueID
                
                // Create a handler for the subscription
                let subscriptionHandler = RapidSubscriptionHandler(withSubscriptionID: subscriptionID, subscription: subscription, dispatchQueue: queue, unsubscribeHandler: { [weak self] handler in
                    self?.websocketQueue.async {
                        self?.unsubscribe(handler)
                    }
                })
                
                // Add handler to the dictionary of registered subscriptions
                self?.activeSubscriptions[subscriptionID] = subscriptionHandler
                
                self?.post(event: subscriptionHandler)
            }
        }
    }
    
    /// Remove all subscriptions
    func unsubscribeAll() {
        websocketQueue.async { [weak self] in
            for (_, subscripiton) in self?.activeSubscriptions ?? [:] {
                let handler = RapidUnsubscriptionHandler(subscription: subscripiton)
                self?.unsubscribe(handler)
            }
        }
    }
    
    /// Reconnect previously configured websocket
    func goOnline() {
        websocketQueue.async { [weak self] in
            self?.socketTerminated = false
            
            if let state = self?.state, state == .disconnected {
                self?.createConnection()
            }
        }
    }
    
    /// Disconnect existing websocket
    func goOffline() {
        websocketQueue.async { [weak self] in
            if let state = self?.state, state != .disconnected {
                self?.destroySocket()
            }
        }
    }
    
    /// Get a subscription handler if exists
    ///
    /// Every subscription is identified by a hash. Subscriptions that listens to the same set of data have equal hashes.
    ///
    /// - Parameter hash: Subscription hash
    /// - Returns: Subscription handler that takes care about subscriptions with specified hash
    func activeSubscription(withHash hash: String) -> RapidSubscriptionHandler? {
        for (_, subscription) in activeSubscriptions where subscription.subscriptionHash == hash {
            return subscription
        }
        
        return nil
    }
    
    /// Get an event ID for a request that has been sent to the server
    ///
    /// - Parameter request: Request that has been sent to the server
    /// - Returns: Event ID of the request
    func eventID(forPendingRequest request: RapidRequest) -> String? {
        let pendingTuples = pendingRequests.filter({ $0.value === request })
        return pendingTuples.first?.key
    }
    
}

// MARK: Fileprivate methods
fileprivate extension SocketManager {
    
    /// Handle a situation when socket was unintentionally disconnected
    func socketDidDisconnect(withError error: RapidError?) {
        print("Did disconnect with error \(String(describing: error))")
        
        // Get all relevant events that were about to be sent
        let currentQueue = eventQueue.filter({
            // Do not include connection requests and heartbeats that are relevant to one physical websocket connection
            switch $0 {
            case is RapidConnectionRequest, is RapidEmptyRequest, is RapidReconnectionRequest:
                // If the request is timeoutable then invalidate it
                if let timeout = $0 as? RapidTimeoutRequest {
                    timeout.invalidateTimer()
                }
                return false
                
            default:
                return true
            }
        })
        
        eventQueue.removeAll(keepingCapacity: true)
        
        // If abstract connection to the server was terminated
        if let error = error, case RapidError.connectionTerminated = error {
            //Because an abstract connection expired a new connection with a new connection ID needs to be established
            connectionID = nil

            // Add to the request queue those subscriptions that were already acknowledged by the server
            eventQueue = activeSubscriptions
                .map({ $0.value })
                .filter({ subscription in
                    guard let subscription = subscription as? RapidSubscriptionHandler else {
                        return true
                    }
                    
                    let toBeSent = currentQueue.contains(where: { (request) -> Bool in
                        if let request = request as? RapidSubscriptionHandler {
                            return request.subscriptionID == subscription.subscriptionID
                        }
                        else {
                            return false
                        }
                    })
                    
                    let toBeAcknowledged = pendingRequests.values.contains(where: { (request) -> Bool in
                        if let request = request as? RapidSubscriptionHandler {
                            return request.subscriptionID == subscription.subscriptionID
                        }
                        else {
                            return false
                        }
                    })
                    
                    return !toBeSent && !toBeAcknowledged
                })
        }

        // Then append requests that had been sent, but they were still waiting for an acknowledgement
        let eventArray = Array(pendingRequests.values) as [Event]
        eventQueue.append(contentsOf: eventArray)
        // Finally append relevant requests that were waiting to be sent
        eventQueue.append(contentsOf: currentQueue)
        
        // Create new connection
        createConnection()
    }
}

// MARK: Socket communication methods
fileprivate extension SocketManager {
    
    /// Create a websocket connection
    func createConnection() {
        print("Create connection")
        
        state = .connecting
        
        // Start the timer that limits maximum time span when websocket connection is trying to be established
        mainQueue.async { [weak self] in
            if let strongSelf = self {
                self?.socketConnectTimer?.invalidate()
                self?.socketConnectTimer = Timer.scheduledTimer(timeInterval: Rapid.defaultTimeout, target: strongSelf, selector: #selector(strongSelf.connectSocketTimout), userInfo: nil, repeats: false)
            }
        }
        
        connectSocket()
    }
    
    /// Force connection restart
    func restartSocket(afterError error: RapidError?) {
        print("Restart socket")
        
        // If socket is connected, disconnect it
        // If socket is not connected and it wasn't intentionally closed, then call reconnection handler directly
        if socket.isConnected {
            disconnectSocket(withError: error)
        }
        else if !socketTerminated {
            socketDidDisconnect(withError: error)
        }
    }
    
    // Destroy existing socket connection
    func destroySocket() {
        socketTerminated = true
        
        disconnectSocket()
        
        state = .disconnected
    }
    
    /// Create abstract connection
    ///
    /// When socket is connected physically, the client still needs to identify itself by its connection ID.
    /// This creates an abstract connection which is not dependent on a physical one
    func sendConnectionRequest() {
        let connection: RapidConnectionRequest
        
        if let connectionID = connectionID {
            connection = RapidReconnectionRequest(connectionID: connectionID, delegate: self)
        }
        else {
            let connectionID = Rapid.uniqueID
            connection = RapidConnectionRequest(connectionID: connectionID, delegate: self)
            self.connectionID = connectionID
        }

        // Inform the connection request that it should start a timeout count down
        connection.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)

        write(event: connection)
    }
    
    /// Destroy abstract connection
    ///
    /// Inform the server that it no longer needs to keep an abstract connection with the client
    func sendDisconnectionRequest() {
        post(event: RapidDisconnectionRequest())
    }
    
    /// Acknowledge a server event
    ///
    /// - Parameter eventID: Event ID of the event to be acknowledged
    func acknowledge(eventWithID eventID: String) {
        let acknowledgement = RapidSocketAcknowledgement(eventID: eventID)
        
        post(event: acknowledgement)
    }
    
    /// Unregister subscription
    ///
    /// - Parameter handler: Unsubscription handler
    func unsubscribe(_ handler: RapidUnsubscriptionHandler) {
        activeSubscriptions[handler.subscription.subscriptionID] = nil
        
        post(event: handler)
    }
    
    /// Enque a event to the queue
    ///
    /// - Parameter serializableRequest: Request to be queued
    func post(event: Event) {
        
        // Inform a timoutable request that it should start a timeout count down
        // User events can be timeouted only if user sets `Rapid.timeout`
        // System events work always with timeout and they use either a custom `Rapid.timeout` if set or a default `Rapid.defaultTimeout`
        if let timeoutRequest = event as? RapidTimeoutRequest, let timeout = Rapid.timeout {
            timeoutRequest.requestSent(withTimeout: timeout, delegate: self)
        }
        else if let timeoutRequest = event as? RapidTimeoutRequest, timeoutRequest.alwaysTimeout {
            timeoutRequest.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)
        }
        
        eventQueue.append(event)
        flushQueue()
    }
    
    /// SenD all requests in the queue
    func flushQueue() {
        // Check connection state
        guard state == .connected else {
            return
        }
        
        let queueCopy = eventQueue
        
        // Empty the queue
        eventQueue.removeAll()

        for event in queueCopy {
            write(event: event)
        }
        
        // Restart heartbeat timer
        rescheduleHeartbeatTimer()
    }
    
    /// Post event to websocket
    ///
    /// - Parameter serializableRequest: Request which is going to be sent
    func write(event: Event) {
        // Generate unique event ID
        let eventID = Generator.uniqueID
        
        if let request = event as? RapidRequest {
            registerPendingRequest(request, withID: eventID)
        }
        
        do {
            let jsonString = try event.serialize(withIdentifiers: [RapidSerialization.EventID.name: eventID])
            
            print("Write request \(jsonString)")
            
            socket.write(string: jsonString)
        }
        catch let rapidError as RapidError {
            completeRequest(withResponse: RapidErrorInstance(eventID: eventID, error: rapidError))
        }
        catch {
            completeRequest(withResponse: RapidErrorInstance(eventID: eventID, error: .invalidData(reason: .serializationFailure)))
        }
    }
    
    /// Add request among pending requests which wait for an acknowledgement from server
    ///
    /// - Parameters:
    ///   - request: Sent request
    ///   - eventID: Event ID associated with the request
    func registerPendingRequest(_ request: RapidRequest, withID eventID: String) {
        if let request = request as? Request {
            pendingRequests[eventID] = request
        }
    }
    
    /// Parse message received from websocket
    ///
    /// - Parameter message: Message received from websocket
    func parse(message: String) {
        print("Received message \(message)")
        
        if let data = message.data(using: .utf8) {
            parse(data: data)
        }
    }
    
    /// Parse data received from websocket
    ///
    /// - Parameter data: Data received from websocket
    func parse(data: Data) {
        let json: [AnyHashable: Any]?
        
        do {
            json = try data.json()
        }
        catch {
            json = nil
        }
        
        // Restart heartbeat timer
        rescheduleHeartbeatTimer()
        
        parseQueue.async { [weak self] in
            if let responses = RapidSerialization.parse(json: json) {
                self?.websocketQueue.async {
                    for response in responses {
                        self?.completeRequest(withResponse: response)
                    }
                }
            }
        }
    }
    
    /// Handle an event sent from the server
    ///
    /// - Parameter response: Event sent from the server
    func completeRequest(withResponse response: RapidResponse) {
        switch response {
        // Event failed
        case let response as RapidErrorInstance:
            let request = pendingRequests[response.eventID]
            request?.eventFailed(withError: response)
            
            // If subscription registration failed remove if from the list of active subscriptions
            if let subscription = request as? RapidSubscriptionHandler {
                activeSubscriptions[subscription.subscriptionID] = nil
            }
            
            pendingRequests[response.eventID] = nil
        
        // Event acknowledged
        case let response as RapidSocketAcknowledgement:
            let request = pendingRequests[response.eventID]
            request?.eventAcknowledged(response)
            pendingRequests[response.eventID] = nil
        
        // Subscription event
        case let response as RapidSubscriptionBatch:
            let subscription = activeSubscriptions[response.subscriptionID]
            subscription?.receivedSubscriptionEvent(response)
            acknowledge(eventWithID: response.eventID)
        
        default:
            print("Unrecognized response")
        }
    }
}

// MARK: Heartbeat
extension SocketManager {
    
    /// Send empty request to test the connection
    @objc func sendEmptyRequest() {
        websocketQueue.async { [weak self] in
            let request = RapidEmptyRequest()
            
            self?.post(event: request)
        }
    }
    
    /// Invalidate previous heartbeat timer and start a new one
    func rescheduleHeartbeatTimer() {
        mainQueue.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            
            if let strongSelf = self {
                self?.heartbeatTimer = Timer.scheduledTimer(timeInterval: strongSelf.heartbeatInterval, target: strongSelf, selector: #selector(strongSelf.sendEmptyRequest), userInfo: nil, repeats: false)
            }
        }
    }
}

// MARK: Connection request delegate
extension SocketManager: RapidConnectionRequestDelegate {
    
    /// Connection request was acknowledged
    ///
    /// - Parameter request: Connection request that was acknowledged
    func connectionEstablished(_ request: RapidConnectionRequest) {
        print("Connection established")
        
        websocketQueue.async { [weak self] in
            self?.state = .connected
            
            self?.flushQueue()
        }
    }
    
    /// Connection request failed
    ///
    /// - Parameters:
    ///   - request: Connection request that failed
    ///   - error: Reason of failure
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance) {
        print("Connection failed")
        
        websocketQueue.async { [weak self] in
            self?.restartSocket(afterError: error.error)
        }
    }
    
}

// MARK: Timout request delegate
extension SocketManager: RapidTimeoutRequestDelegate {
    
    /// Request timeout
    ///
    /// - Parameter request: Request that timeouted
    func requestTimeout(_ request: RapidTimeoutRequest) {
        print("Request timeout \(request)")
        
        websocketQueue.async { [weak self] in
            // If the request is pending complete it with timeout error
            // Otherwise, if the request is still in the queue move it to pending requests and complete it with timeout error
            if let eventID = self?.eventID(forPendingRequest: request) {
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.completeRequest(withResponse: error)
            }
            else if let index = self?.eventQueue.flatMap({ $0 as? Request }).index(where: { request === $0 }), let request = request as? Request {
                self?.eventQueue.remove(at: index)
                
                let eventID = Generator.uniqueID
                self?.registerPendingRequest(request, withID: eventID)
                
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.completeRequest(withResponse: error)
            }
        }
    }
    
    /// Websocket connection hasn't been established for too long
    @objc func connectSocketTimout() {
        socketConnectTimer = nil

        websocketQueue.async {
            self.restartSocket(afterError: nil)
        }
    }
}

// MARK: Websocket delegate
extension SocketManager: WebSocketDelegate {
    
    func connectSocket() {
        mainQueue.async { [weak self] in
            self?.socket.connect()
        }
    }
    
    func disconnectSocket(withError error: RapidError? = nil) {
        reconnectionError = error

        mainQueue.async { [weak self] in
            self?.socket.disconnect(forceTimeout: 0.5)
        }
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("Socket did connect")
        
        // Invalidate connection timer
        mainQueue.async { [weak self] in
            self?.socketConnectTimer?.invalidate()
            self?.socketConnectTimer = nil
        }
        
        // Establish abstract connection
        websocketQueue.async { [weak self] in
            self?.sendConnectionRequest()
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("Socket did disconnect")
        
        // Invalidate connection timer
        mainQueue.async { [weak self] in
            self?.socketConnectTimer?.invalidate()
            self?.socketConnectTimer = nil
        }
        
        websocketQueue.async { [weak self] in
            self?.state = .disconnected
            
            // If the connection wasn't terminated intentionally reconnect it
            if !(self?.socketTerminated ?? true), let queue = self?.websocketQueue {
                let error = self?.reconnectionError
                // Wait for socket to be closed
                runAfter(1, queue: queue, closure: {
                    self?.socketDidDisconnect(withError: error)
                })
            }
            
            self?.reconnectionError = nil
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        websocketQueue.async { [weak self] in
            self?.parse(data: data)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        websocketQueue.async { [weak self] in
            self?.parse(message: text)
        }
    }
}
