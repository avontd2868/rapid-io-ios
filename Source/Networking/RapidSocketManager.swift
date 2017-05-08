//
//  SocketManager.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Class for websocket communication management
class RapidSocketManager {
    
    typealias Event = RapidSocketEvent & RapidSerializable
    typealias Request = RapidRequest & Event
    
    /// Network communication handler
    let networkHandler: RapidNetworkHandler
    
    weak var cacheHandler: RapidCacheHandler?
    
    /// State of a websocket connection
    fileprivate var state: Rapid.ConnectionState = .disconnected
    
    /// ID that identifies a websocket connection to this client for reconnecting purposes
    fileprivate(set) var connectionID: String?
    
    fileprivate(set) var auth: RapidAuthorization?
    
    /// Dedicated threads
    internal let websocketQueue: OperationQueue
    internal let parseQueue: OperationQueue
    fileprivate let mainQueue = DispatchQueue.main
    
    /// Queue of events that are about to be sent to the server
    fileprivate var eventQueue: [Event] = []
    
    /// Dictionary of events that have been already sent to the server and a response is awaited. Events are identified by an event ID.
    fileprivate var pendingRequests: [String: (request: Request, timestamp: TimeInterval)] = [:]
    
    /// Dictionary of registered subscriptions. Either active or those that are waiting for acknowledgement from the server. Subscriptions are identified by a subscriptioon ID
    fileprivate var activeSubscriptions: [String: RapidSubscriptionHandler] = [:]
    
    /// Timer that limits maximum time without any websocket communication to reveal disconnections
    fileprivate var nopTimer: Timer?
    
    init(networkHandler: RapidNetworkHandler) {
        self.websocketQueue = OperationQueue()
        self.websocketQueue.name = "RapidWebsocketQueue-\(networkHandler.socketURL.lastPathComponent)"
        self.websocketQueue.maxConcurrentOperationCount = 1
        self.websocketQueue.underlyingQueue = DispatchQueue(label: "RapidWebsocketQueue-\(networkHandler.socketURL.lastPathComponent)", attributes: [])
        
        self.parseQueue = OperationQueue()
        self.parseQueue.name = "RapidParseQueue-\(networkHandler.socketURL.lastPathComponent)"
        self.parseQueue.maxConcurrentOperationCount = 1
        self.parseQueue.underlyingQueue = DispatchQueue(label: "RapidParseQueue-\(networkHandler.socketURL.lastPathComponent)", attributes: [])

        self.networkHandler = networkHandler
        
        self.networkHandler.delegate = self        
        self.networkHandler.goOnline()
        self.state = .connecting
    }
    
    deinit {
        sendDisconnectionRequest()
    }
    
    func authorize(authRequest: RapidAuthRequest) {
        websocketQueue.async { [weak self] in
            self?.auth = authRequest.auth
            self?.post(event: authRequest)
        }
    }
    
    func deauthorize(deauthRequest: RapidDeauthRequest) {
        websocketQueue.async { [weak self] in
            self?.auth = nil
            self?.post(event: deauthRequest)
        }
    }
    
    /// Reconnect previously configured websocket
    func goOnline() {
        websocketQueue.async { [weak self] in
            self?.networkHandler.goOnline()
            self?.state = .connecting
        }
    }
    
    /// Disconnect existing websocket
    func goOffline() {
        websocketQueue.async { [weak self] in
            self?.networkHandler.goOffline()
            self?.state = .disconnected
        }
    }
    
    /// Send mutation event
    ///
    /// - Parameter mutationRequest: Mutation object
    func mutate<T: RapidMutationRequest>(mutationRequest: T) {
        websocketQueue.async { [weak self] in
            self?.post(event: mutationRequest)
        }
    }
    
    /// Send register subscription event
    ///
    /// - Parameter subscription: Subscription object
    func subscribe(_ subscription: RapidSubscriptionInstance) {
        subscription.registerUnsubscribeCallback { [weak self] (subscription) in
            self?.websocketQueue.async {
                self?.unsubscribe(subscription)
            }
        }
        
        websocketQueue.async { [weak self] in

            // If a subscription that listens to the same set of data has been already registered just register the new listener locally
            if let activeSubscription = self?.activeSubscription(withHash: subscription.subscriptionHash) {
                activeSubscription.registerSubscription(subscription: subscription)
            }
            else {
                // Create an unique ID that identifies the subscription
                let subscriptionID = Generator.uniqueID
                
                // Create a handler for the subscription
                let subscriptionHandler = RapidSubscriptionHandler(withSubscriptionID: subscriptionID, subscription: subscription, delegate: self)
                
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
        let pendingTuples = pendingRequests.filter({ $0.value.request === request })
        return pendingTuples.first?.key
    }
    
}

// MARK: Fileprivate methods
fileprivate extension RapidSocketManager {
    
    /// Handle a situation when socket was unintentionally disconnected
    func handleDidDisconnect(withError error: RapidError?) {
        RapidLogger.debugLog(message: "Did disconnect with error \(String(describing: error))")
        
        // Get all relevant events that were about to be sent
        let currentQueue = eventQueue.filter({
            // If the request is timeoutable then invalidate it
            if let timeout = $0 as? RapidTimeoutRequest {
                timeout.invalidateTimer()
            }

            // Do not include connection requests and heartbeats that are relevant to one physical websocket connection
            switch $0 {
            case is RapidConnectionRequest, is RapidEmptyRequest, is RapidReconnectionRequest:
                return false
                
            default:
                return true
            }
        })
        
        eventQueue.removeAll(keepingCapacity: true)
        
        let connectionTerminated: Bool
        switch error {
        case .some(.connectionTerminated), .some(.timeout):
            connectionTerminated = true
            
        default:
            connectionTerminated = false
        }
        
        // If abstract connection to the server was terminated
        if connectionTerminated {
            //Because an abstract connection expired a new connection with a new connection ID needs to be established
            connectionID = nil

            // Add to the request queue those subscriptions that were already acknowledged by the server
            let resubscribe = activeSubscriptions
                .map({ $0.value })
                .filter({ (subscription) -> Bool in
                    
                let toBeSent = currentQueue.contains(where: { (request) -> Bool in
                    if let request = request as? RapidSubscriptionHandler {
                        return request.subscriptionID == subscription.subscriptionID
                    }

                    return false
                })
                
                let toBeAcknowledged = pendingRequests.values.contains(where: { (request, _) -> Bool in
                    if let request = request as? RapidSubscriptionHandler {
                        return request.subscriptionID == subscription.subscriptionID
                    }

                    return false
                })
                
                return !toBeSent && !toBeAcknowledged
            })
            eventQueue = resubscribe
        }

        // Then append requests that had been sent, but they were still waiting for an acknowledgement
        let pendingArray = (Array(pendingRequests.values) as [(request: Request, timestamp: TimeInterval)])
        let eventArray = pendingArray.sorted(by: { $0.timestamp < $1.timestamp }).map({ $0.request }) as [Event]
        eventQueue.append(contentsOf: eventArray)

        // Finally append relevant requests that were waiting to be sent
        eventQueue.append(contentsOf: currentQueue)
        
        // Create new connection
        networkHandler.goOnline()
        
        state = .connecting
    }
}

// MARK: Socket communication methods
fileprivate extension RapidSocketManager {
    
    /// Create abstract connection
    ///
    /// When socket is connected physically, the client still needs to identify itself by its connection ID.
    /// This creates an abstract connection which is not dependent on a physical one
    func sendConnectionRequest() {
        let connection: RapidConnectionRequest
        let authorization: RapidAuthRequest?
        
        if let connectionID = connectionID {
            connection = RapidReconnectionRequest(connectionID: connectionID, delegate: self)
            
            // No need to reauthorize when reconnecting
            authorization = nil
        }
        else {
            let connectionID = Rapid.uniqueID
            connection = RapidConnectionRequest(connectionID: connectionID, delegate: self)
            self.connectionID = connectionID
            
            // Client needs to reauthorize when creating a new connection
            if let token = self.auth?.accessToken {
                authorization = RapidAuthRequest(accessToken: token)
            }
            else {
                authorization = nil
            }
        }

        post(event: connection, prioritize: true)
        
        if let authorization = authorization,
            !eventQueue.contains(where: { authorization.auth.accessToken == ($0 as? RapidAuthRequest)?.auth.accessToken }) {
            post(event: authorization, prioritize: true)
        }
    }
    
    /// Destroy abstract connection
    ///
    /// Inform the server that it no longer needs to keep an abstract connection with the client
    func sendDisconnectionRequest() {
        networkHandler.write(event: RapidDisconnectionRequest(), withID: Rapid.uniqueID)
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
    /// When a subscription has no handler assigned yet (because of async calls) the unsubscription process is handled by this method
    ///
    /// - Parameter subscription: Subscription instance
    func unsubscribe(_ subscription: RapidSubscriptionInstance) {
        if activeSubscription(withHash: subscription.subscriptionHash) != nil {
            subscription.unsubscribe()
        }
    }
    
    /// Unregister subscription
    ///
    /// - Parameter handler: Unsubscription handler
    func unsubscribe(_ handler: RapidUnsubscriptionHandler) {
        RapidLogger.log(message: "Unsubscribe \(handler.subscription.subscriptionHash)")
        
        activeSubscriptions[handler.subscription.subscriptionID] = nil
        
        // If the subscription is still in queue just remove it
        // Otherwise, send usubscription request
        if let subscriptionIndex = eventQueue.flatMap({ $0 as? RapidSubscriptionHandler }).index(where: { $0.subscriptionID == handler.subscription.subscriptionID }) {
            eventQueue.remove(at: subscriptionIndex)
        }
        else {
            post(event: handler)
        }
    }
    
    /// Enque a event to the queue
    ///
    /// - Parameter serializableRequest: Request to be queued
    func post(event: Event, prioritize: Bool = false) {
        
        // Inform a timoutable request that it should start a timeout count down
        // User events can be timeouted only if user sets `Rapid.timeout`
        // System events work always with timeout and they use either a custom `Rapid.timeout` if set or a default `Rapid.defaultTimeout`
        if let timeoutRequest = event as? RapidTimeoutRequest, let timeout = Rapid.timeout {
            timeoutRequest.requestSent(withTimeout: timeout, delegate: self)
        }
        else if let timeoutRequest = event as? RapidTimeoutRequest, timeoutRequest.alwaysTimeout {
            timeoutRequest.requestSent(withTimeout: Rapid.defaultTimeout, delegate: self)
        }
        
        if prioritize && !eventQueue.isEmpty {
            var index = 0
            let requestPriority = (event as? RapidPriorityRequest)?.priority ?? .low
            
            while index < eventQueue.count && ((eventQueue[index] as? RapidPriorityRequest)?.priority.rawValue ?? Int.max) <= requestPriority.rawValue {
                index += 1
            }
            
            eventQueue.insert(event, at: index)
        }
        else {
            eventQueue.append(event)
        }

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
            // Generate unique event ID
            let eventID = Generator.uniqueID
            
            if let request = event as? RapidRequest {
                registerPendingRequest(request, withID: eventID)
            }
            
            networkHandler.write(event: event, withID: eventID)
        }
        
        // Restart heartbeat timer
        rescheduleHeartbeatTimer()
    }
    
    /// Add request among pending requests which wait for an acknowledgement from server
    ///
    /// - Parameters:
    ///   - request: Sent request
    ///   - eventID: Event ID associated with the request
    func registerPendingRequest(_ request: RapidRequest, withID eventID: String) {
        if let request = request as? Request {
            pendingRequests[eventID] = (request, Date().timeIntervalSince1970)
        }
    }
    
    /// Handle an event sent from the server
    ///
    /// - Parameter response: Event sent from the server
    func handle(response: RapidResponse) {
        switch response {
        // Event failed
        case let response as RapidErrorInstance:
            let tuple = pendingRequests[response.eventID]
            tuple?.request.eventFailed(withError: response)
            
            // If subscription registration failed remove if from the list of active subscriptions
            if let subscription = tuple?.request as? RapidSubscriptionHandler {
                activeSubscriptions[subscription.subscriptionID] = nil
            }
            else if let request = tuple?.request as? RapidAuthRequest, self.auth?.accessToken == request.auth.accessToken {
                self.auth = nil
            }
            
            pendingRequests[response.eventID] = nil
        
        // Event acknowledged
        case let response as RapidSocketAcknowledgement:
            let tuple = pendingRequests[response.eventID]
            tuple?.request.eventAcknowledged(response)
            pendingRequests[response.eventID] = nil
        
        // Subscription event
        case let response as RapidSubscriptionBatch:
            let subscription = activeSubscriptions[response.subscriptionID]
            subscription?.receivedSubscriptionEvent(response)
            acknowledge(eventWithID: response.eventID)
            
        // Subscription cancel
        case let response as RapidSubscriptionCancel:
            let subscription = activeSubscriptions[response.subscriptionID]
            let error = RapidErrorInstance(eventID: response.eventID, error: .permissionDenied(message: "No longer authorized to read data"))
            subscription?.eventFailed(withError: error)
            activeSubscriptions[response.subscriptionID] = nil
            acknowledge(eventWithID: response.eventID)
        
        default:
            RapidLogger.debugLog(message: "Unrecognized response")
        }
    }
}

// MARK: Subscription handler delegate
extension RapidSocketManager: RapidSubscriptionHandlerDelegate {
    
    var authorization: RapidAuthorization? {
        return auth
    }
    
    func unsubscribe(handler: RapidUnsubscriptionHandler) {
        websocketQueue.async { [weak self] in
            self?.unsubscribe(handler)
        }
    }
}

// MARK: Heartbeat
extension RapidSocketManager {
    
    /// Send empty request to test the connection
    func sendEmptyRequest() {
        websocketQueue.async { [weak self] in
            let request = RapidEmptyRequest()
            
            self?.post(event: request)
        }
    }
    
    /// Invalidate previous heartbeat timer and start a new one
    func rescheduleHeartbeatTimer() {
        mainQueue.async { [weak self] in
            self?.nopTimer?.invalidate()
            
            self?.nopTimer = Timer.scheduledTimer(timeInterval: Rapid.heartbeatInterval, userInfo: nil, repeats: false, block: { [weak self] _ in
                self?.sendEmptyRequest()
            })
        }
    }
}

// MARK: Connection request delegate
extension RapidSocketManager: RapidConnectionRequestDelegate {
    
    /// Connection request was acknowledged
    ///
    /// - Parameter request: Connection request that was acknowledged
    func connectionEstablished(_ request: RapidConnectionRequest) {
        RapidLogger.log(message: "Rapid connected")
        
        RapidLogger.debugLog(message: "Connection established")
    }
    
    /// Connection request failed
    ///
    /// - Parameters:
    ///   - request: Connection request that failed
    ///   - error: Reason of failure
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance) {
        RapidLogger.log(message: "Rapid connection failed")
        
        RapidLogger.debugLog(message: "Connection failed")
        
        websocketQueue.async { [weak self] in
            self?.networkHandler.restartSocket(afterError: error.error)
        }
    }
    
}

// MARK: Timout request delegate
extension RapidSocketManager: RapidTimeoutRequestDelegate {
    
    /// Request timeout
    ///
    /// - Parameter request: Request that timeouted
    func requestTimeout(_ request: RapidTimeoutRequest) {
        RapidLogger.debugLog(message: "Request timeout \(request)")
        
        websocketQueue.async { [weak self] in
            // If the request is pending complete it with timeout error
            // Otherwise, if the request is still in the queue move it to pending requests and complete it with timeout error
            if let eventID = self?.eventID(forPendingRequest: request) {
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.handle(response: error)
            }
            else if let index = self?.eventQueue.flatMap({ $0 as? Request }).index(where: { request === $0 }), let request = request as? Request {
                self?.eventQueue.remove(at: index)
                
                let eventID = Generator.uniqueID
                self?.registerPendingRequest(request, withID: eventID)
                
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.handle(response: error)
            }
        }
    }
}

// MARK: Network manager delegate
extension RapidSocketManager: RapidNetworkHandlerDelegate {
    
    func socketDidConnect() {
        websocketQueue.async { [weak self] in
            self?.sendConnectionRequest()
            
            self?.state = .connected
            
            self?.flushQueue()
        }
    }
    
    func socketDidDisconnect(withError error: RapidError?) {
        websocketQueue.async { [weak self] in
            self?.state = .disconnected
            
            self?.handleDidDisconnect(withError: error)
        }
    }
    
    func handlerDidReceive(response: RapidResponse) {
        websocketQueue.async { [weak self] in
            
            // Restart heartbeat timer
            self?.rescheduleHeartbeatTimer()
            
            self?.handle(response: response)
        }
    }
}
