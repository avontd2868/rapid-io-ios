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
    
    typealias Request = RapidRequest & RapidSerializable
    
    /// ID that identifies a websocket connection to this client for reconnecting purposes
    fileprivate(set) var connectionID: String
    
    /// State of a websocket connection
    fileprivate var state: Rapid.ConnectionState = .disconnected {
        didSet {
            let state = self.state
            DispatchQueue.main.async { [weak self] in
                self?.connectionStateDelegate?.connectionStateChanged(currentState: state)
            }
        }
    }
    /// Delegate for informing about connection state change
    weak var connectionStateDelegate: RapidConnectionStateChangeDelegate?
    
    /// Dedicated threads
    fileprivate let websocketQueue: DispatchQueue
    fileprivate let parseQueue: DispatchQueue
    
    /// Websocket object
    fileprivate let socket: WebSocket
    
    /// Queue of events that are about to be sent to the server
    fileprivate var requestQueue: [Request] = []
    
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
    
    init(socketURL: URL) {
        self.websocketQueue = DispatchQueue(label: "RapidWebsocketQueue-\(socketURL.lastPathComponent)", attributes: [])
        self.parseQueue = DispatchQueue(label: "RapidParseQueue-\(socketURL.lastPathComponent)", attributes: [])
        self.connectionID = Generator.uniqueID
        self.socket = WebSocket(url: socketURL)
        self.socket.delegate = self
        
        websocketQueue.async { [weak self] in
            self?.createConnection()
        }
    }
    
    deinit {
        destroySocket()
    }
    
    /// Send mutation event
    ///
    /// - Parameter mutationRequest: Mutation object
    func mutate<T: RapidMutationRequest>(mutationRequest: T) {
        websocketQueue.async { [weak self] in
            self?.postEvent(serializableRequest: mutationRequest)
        }
    }
    
    /// Send merge event
    ///
    /// - Parameter mergeRequest: Merge object
    func merge<T: RapidMergeRequest>(mergeRequest: T) {
        websocketQueue.async { [weak self] in
            self?.postEvent(serializableRequest: mergeRequest)
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
                
                self?.postEvent(serializableRequest: subscriptionHandler)
            }
        }
    }
    
    /// Reconnect previously configured websocket
    func goOnline() {
        websocketQueue.async { [weak self] in
            if let state = self?.state, state == .disconnected {
                self?.createConnection()
            }
        }
    }
    
    /// Disconnect existing websocket
    func goOffline() {
        websocketQueue.async { [weak self] in
            if let state = self?.state, state != .disconnected {
                self?.socketTerminated = true
                self?.state = .disconnected
                
                self?.disconnectSocket()
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
        let currentQueue = requestQueue.filter({
            // Do not include connection requests and heartbeats that are relevant to one physical websocket connection
            switch $0 {
            case is RapidConnectionRequest, is RapidHeartbeat:
                return false
                
            default:
                return true
            }
        })
        
        requestQueue.removeAll(keepingCapacity: true)
        
        // If abstract connection to the server was terminated
        if let error = error, case RapidError.connectionTerminated = error {
            //Because an abstract connection expired a new connection with a new connection ID needs to be established
            connectionID = Generator.uniqueID

            // Add to the request queue those subscriptions that were already acknowledged by the server
            requestQueue = activeSubscriptions
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
        requestQueue.append(contentsOf: Array(pendingRequests.values))
        // Finally append relevant requests that were waiting to be sent
        requestQueue.append(contentsOf: currentQueue)
        
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
        DispatchQueue.main.async { [weak self] in
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
        sendDisconnectionRequest()
        
        socketTerminated = true
        
        disconnectSocket()
    }
    
    /// Create abstract connection
    ///
    /// When socket is connected physically, the client still needs to identify itself by its connection ID.
    /// This creates an abstract connection which is not dependent on a physical one
    func sendConnectionRequest() {
        let connection = RapidConnectionRequest(connectionID: connectionID, delegate: self)

        // Inform the connection request that it should start a timeout count down
        connection.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)

        writeEvent(serializableRequest: connection)
    }
    
    /// Destroy abstract connection
    ///
    /// Inform the server that it no longer needs to keep an abstract connection with the client
    func sendDisconnectionRequest() {
        postEvent(serializableRequest: RapidDisconnectionRequest())
    }
    
    /// Acknowledge a server event
    ///
    /// - Parameter eventID: Event ID of the event to be acknowledged
    func acknowledge(eventWithID eventID: String) {
        let acknowledgement = RapidSocketAcknowledgement(eventID: eventID)
        
        postEvent(serializableRequest: acknowledgement)
    }
    
    /// Unregister subscription
    ///
    /// - Parameter handler: Unsubscription handler
    func unsubscribe(_ handler: RapidUnsubscriptionHandler) {
        activeSubscriptions[handler.subscription.subscriptionID] = nil
        
        postEvent(serializableRequest: handler)
    }
    
    /// Enque a request to the queue
    ///
    /// - Parameter serializableRequest: Request to be queued
    func postEvent(serializableRequest: Request) {
        
        // Inform a timoutable request that it should start a timeout count down
        // User events can be timeouted only if user sets `Rapid.timeout`
        // System events work always with timeout and they use either a custom `Rapid.timeout` if set or a default `Rapid.defaultTimeout`
        if let timeoutRequest = serializableRequest as? RapidTimeoutRequest, let timeout = Rapid.timeout {
            timeoutRequest.requestSent(withTimeout: timeout, delegate: self)
        }
        else if let timeoutRequest = serializableRequest as? RapidTimeoutRequest, timeoutRequest.alwaysTimeout {
            timeoutRequest.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)
        }
        
        requestQueue.append(serializableRequest)
        flushQueue()
    }
    
    /// SenD all requests in the queue
    func flushQueue() {
        // Check connection state
        guard state == .connected else {
            return
        }
        
        let queueCopy = requestQueue
        
        // Empty the queue
        requestQueue.removeAll()

        for request in queueCopy {
            writeEvent(serializableRequest: request)
        }
    }
    
    /// Post event to websocket
    ///
    /// - Parameter serializableRequest: Request which is going to be sent
    func writeEvent(serializableRequest: Request) {
        // Generate unique event ID
        let eventID = Generator.uniqueID
        
        registerPendingRequest(serializableRequest, withID: eventID)
        
        do {
            let jsonString = try serializableRequest.serialize(withIdentifiers: [RapidSerialization.EventID.name: eventID])
            
            socket.write(string: jsonString)
        }
        catch {
            completeRequest(withResponse: RapidErrorInstance(eventID: eventID, error: .invalidData))
        }
    }
    
    /// Add request among pending requests which wait for an acknowledgement from server
    ///
    /// - Parameters:
    ///   - request: Sent request
    ///   - eventID: Event ID associated with the request
    func registerPendingRequest(_ request: Request, withID eventID: String) {
        // Do not include requests that do not need to be acknowledged
        if request.needsAcknowledgement {
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
        case let response as RapidSubscriptionEvent:
            let subscription = activeSubscriptions[response.subscriptionID]
            subscription?.receivedSubscriptionEvent(response)
            acknowledge(eventWithID: response.eventID)
        
        default:
            print("Unrecognized response")
        }
    }
}

// MARK: Connection request delegate
extension SocketManager: RapidConnectionRequestDelegate {
    
    /// Connection request was acknowledged
    ///
    /// - Parameter request: Connection request that was acknowledged
    func connectionEstablished(_ request: RapidConnectionRequest) {
        websocketQueue.async { [weak self] in
            self?.state = .connected
            
            self?.flushQueue()
            self?.sendHeartbeat()
        }
    }
    
    /// Connection request failed
    ///
    /// - Parameters:
    ///   - request: Connection request that failed
    ///   - error: Reason of failure
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance) {
        websocketQueue.async { [weak self] in
            self?.restartSocket(afterError: error.error)
        }
    }
}

// MARK: Heartbeat delegate
extension SocketManager: RapidHeartbeatDelegate {
    
    /// Heartbeat was acknowledged
    ///
    /// - Parameter heartbeat: Heartbeat request that was acknowledged
    func connectionAlive(_ heartbeat: RapidHeartbeat) {
        print("Schedule hearbeat")
        
        // If heartbeat was acknowledged schedule next one
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                Timer.scheduledTimer(timeInterval: 10, target: strongSelf, selector: #selector(strongSelf.sendHeartbeat), userInfo: nil, repeats: false)
            }
        }
    }
    
    /// Send heartbeat to the server
    @objc func sendHeartbeat() {
        print("Send hearbeat")
        
        websocketQueue.async { [weak self] in
            if let strongSelf = self, strongSelf.state == .connected {
                self?.postEvent(serializableRequest: RapidHeartbeat(delegate: strongSelf))
            }
        }
    }
    
    /// Heartbeat failed
    ///
    /// Heartbeat either timed out or the server returned `RapidError.connectionTerminated`
    ///
    /// - Parameters:
    ///   - heartbeat: Heartbeat request that failed
    ///   - error: Failure reason
    func connectionDead(_ heartbeat: RapidHeartbeat, error: RapidErrorInstance) {
        print("Connection dead")
        
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
            else if let index = self?.requestQueue.index(where: { request === $0 }), let request = request as? Request {
                self?.requestQueue.remove(at: index)
                
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
        DispatchQueue.main.async { [weak self] in
            self?.socket.connect()
        }
    }
    
    func disconnectSocket(withError error: RapidError? = nil) {
        reconnectionError = error

        DispatchQueue.main.async { [weak self] in
            self?.socket.disconnect(forceTimeout: 0.5)
        }
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("Socket did connect")
        
        // Invalidate connection timer
        DispatchQueue.main.async { [weak self] in
            self?.socketConnectTimer?.invalidate()
            self?.socketConnectTimer = nil
        }
        
        websocketQueue.async { [weak self] in
            self?.state = .connected
            
            self?.flushQueue()
            self?.sendHeartbeat()
        }
        // Establish abstract connection
        // FIXME: Send connection request
        
        /*
        websocketQueue.async { [weak self] in
            self?.sendConnectionRequest()
        }*/
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("Socket did disconnect")
        
        // Invalidate connection timer
        DispatchQueue.main.async { [weak self] in
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
