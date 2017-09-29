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
    
    typealias Event = RapidSerializable & RapidClientMessage
    typealias Request = RapidClientRequest & Event
    
    /// Network communication handler
    let networkHandler: RapidNetworkHandler
    
    weak var cacheHandler: RapidDocCacheHandler?
    
    /// Optional timeout for timeoutable requests
    var timeout: TimeInterval?
    
    /// State of a websocket connection
    internal var state: RapidConnectionState = .disconnected
    
    internal(set) var auth: RapidAuthorization?
    
    /// Dedicated threads
    internal let websocketQueue: OperationQueue
    internal let parseQueue: OperationQueue
    internal let mainQueue = DispatchQueue.main
    
    /// Queue of events that are about to be sent to the server
    internal var eventQueue: [Event] = []
    
    /// Dictionary of events that have been already sent to the server and a response is awaited. Events are identified by an event ID.
    internal var pendingRequests: [String: (request: Request, timestamp: TimeInterval)] = [:]
    
    /// Dictionary of registered subscriptions. Either active or those that are waiting for acknowledgement from the server. Subscriptions are identified by a subscriptioon hash
    internal var activeSubscriptions: [String: RapidSubscriptionManager] = [:]
    
    internal var pendingFetches: [String: RapidFetchInstance] = [:]
    
    internal var pendingExecutionRequests: [String: RapidExecution] = [:]
    
    internal var pendingTimeRequests: [RapidTimeOffset] = []
    
    internal var onConnectActions: [String: RapidOnConnectAction] = [:]
    
    internal var onDisconnectActions: [String: RapidOnDisconnectAction] = [:]
    
    /// Timer that limits maximum time without any websocket communication to reveal disconnections
    internal var nopTimer: Timer?
    
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
            
            if let state = self?.state, state != .connected {
                self?.state = .connecting
            }
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
        mutationRequest.register(delegate: self)
        
        websocketQueue.async { [weak self] in
            self?.post(event: mutationRequest)
        }
    }
    
    func publish(publishRequest: RapidChannelPublish) {
        websocketQueue.async { [weak self] in
            self?.post(event: publishRequest)
        }
    }
    
    func execute<T: RapidExecution>(execution: T) {
        websocketQueue.async { [weak self] in
            self?.pendingExecutionRequests[execution.identifier] = execution
            
            self?.fetch(execution.fetchRequest)
        }
    }
    
    func fetch(_ fetch: RapidFetchInstance) {
        websocketQueue.async { [weak self] in
            self?.pendingFetches[fetch.fetchID] = fetch
            
            self?.post(event: fetch)
        }
    }
    
    func requestTimestamp(_ request: RapidTimeOffset) {
        websocketQueue.async { [weak self] in
            self?.pendingTimeRequests.append(request)
            
            self?.post(event: request)
        }
    }
    
    func registerOnConnectAction(_ action: RapidOnConnectAction) {
        let actionID = Rapid.uniqueID
        
        action.register(actionID: actionID, delegate: self)

        websocketQueue.async { [weak self] in
            self?.onConnectActions[actionID] = action
            
            if self?.state == .connected {
                self?.post(event: action)
            }
        }
    }
    
    func registerOnDisconnectAction(_ action: RapidOnDisconnectAction) {
        let actionID = Rapid.uniqueID
        
        action.register(actionID: actionID, delegate: self)
        
        websocketQueue.async { [weak self] in
            self?.onDisconnectActions[actionID] = action
            
            self?.post(event: action)
        }
    }
    
    /// Send register collection subscription event
    ///
    /// - Parameter subscription: Subscription object
    func subscribe(toCollection subscription: RapidColSubInstance) {
        subscription.registerUnsubscribeHandler { [weak self] (subscription) in
            self?.websocketQueue.async {
                self?.unsubscribe(subscription)
            }
        }
        
        websocketQueue.async { [weak self] in

            // If a subscription that listens to the same set of data has been already registered just register the new listener locally
            if let activeSubscription = self?.activeSubscription(withHash: subscription.subscriptionHash) as? RapidColSubManager {
                activeSubscription.registerSubscription(subscription: subscription)
            }
            else {
                // Create an unique ID that identifies the subscription
                let subscriptionID = Rapid.uniqueID
                
                // Create a handler for the subscription
                let subscriptionHandler = RapidColSubManager(withSubscriptionID: subscriptionID, subscription: subscription, delegate: self)
                
                // Add handler to the dictionary of registered subscriptions
                self?.activeSubscriptions[subscriptionID] = subscriptionHandler
                
                self?.post(event: subscriptionHandler)
            }
        }
    }
    
    /// Send register channel subscription event
    ///
    /// - Parameter subscription: Subscription object
    func subscribe(toChannel subscription: RapidChanSubInstance) {
        subscription.registerUnsubscribeHandler { [weak self] (subscription) in
            self?.websocketQueue.async {
                self?.unsubscribe(subscription)
            }
        }
        
        websocketQueue.async { [weak self] in
            
            // If a subscription that listens to the same set of data has been already registered just register the new listener locally
            if let activeSubscription = self?.activeSubscription(withHash: subscription.subscriptionHash) as? RapidChanSubManager {
                activeSubscription.registerSubscription(subscription: subscription)
            }
            else {
                // Create an unique ID that identifies the subscription
                let subscriptionID = Rapid.uniqueID
                
                // Create a handler for the subscription
                let subscriptionHandler = RapidChanSubManager(withSubscriptionID: subscriptionID, subscription: subscription, delegate: self)
                
                // Add handler to the dictionary of registered subscriptions
                self?.activeSubscriptions[subscriptionID] = subscriptionHandler
                
                self?.post(event: subscriptionHandler)
            }
        }
    }
    
    /// Remove all subscriptions
    func unsubscribeAll() {
        websocketQueue.async { [weak self] in
            for (_, subscription) in self?.activeSubscriptions ?? [:] {
                let handler = RapidUnsubscriptionManager(subscription: subscription)
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
    func activeSubscription(withHash hash: String) -> RapidSubscriptionManager? {
        for (_, subscription) in activeSubscriptions where subscription.subscriptionHash == hash {
            return subscription
        }
        
        return nil
    }
    
    /// Get an event ID for a request that has been sent to the server
    ///
    /// - Parameter request: Request that has been sent to the server
    /// - Returns: Event ID of the request
    func eventID(forPendingRequest request: RapidClientRequest) -> String? {
        let pendingTuples = pendingRequests.filter({ $0.value.request === request })
        return pendingTuples.first?.key
    }
    
}

// MARK: internal methods
internal extension RapidSocketManager {
    
    func handleDidConnect() {
        for (_, action) in onConnectActions {
            post(event: action)
        }
    }
    
    /// Handle a situation when socket was unintentionally disconnected
    func handleDidDisconnect(withError error: RapidError?) {
        RapidLogger.developerLog(message: "Did disconnect with error \(String(describing: error))")
        
        // Get all relevant events that were about to be sent
        let currentQueue = eventQueue.filter({
            // Do not include requests that are relevant to one physical websocket connection
            return $0.shouldSendOnReconnect
        })
        
        // Get all relevant requests that had been sent, but they were still waiting for an acknowledgement
        let pendingArray = (Array(pendingRequests.values) as [(request: Request, timestamp: TimeInterval)]).filter({
            // Do not include requests that are relevant to one physical websocket connection
            return $0.request.shouldSendOnReconnect
        })
        let sortedPendingArray = pendingArray.sorted(by: { $0.timestamp < $1.timestamp }).map({ $0.request }) as [Event]
        
        eventQueue.removeAll(keepingCapacity: true)
        pendingRequests.removeAll()
        
        // Resubscribe all subscriptions
        let resubscribe = activeSubscriptions.map({ $0.value })
        for handler in resubscribe {
            eventQueue.append(handler)
        }
        
        // Re-register all on-disconnect actions
        let reregister = onDisconnectActions.map({ $0.value }) as [Event]
        eventQueue.append(contentsOf: reregister)

        // Then append requests that had been sent, but they were still waiting for an acknowledgement
        eventQueue.append(contentsOf: sortedPendingArray)

        // Finally append events that were waiting to be sent
        eventQueue.append(contentsOf: currentQueue)
        
        // Create new connection
        networkHandler.goOnline()
        
        state = .connecting
    }
}

// MARK: Socket communication methods
internal extension RapidSocketManager {
    
    /// Create abstract connection
    ///
    /// When socket is connected physically, the client still needs to identify itself by its connection ID.
    /// This creates an abstract connection which is not dependent on a physical one
    func sendConnectionRequest() {
        let authorization: RapidAuthRequest?

        let connection = RapidConnectionRequest(connectionID: Rapid.uniqueID, delegate: self)
        
        // Client needs to reauthorize when creating a new connection
        if let token = self.auth?.token {
            authorization = RapidAuthRequest(token: token)
        }
        else {
            authorization = nil
        }

        post(event: connection, prioritize: true)
        
        if let authorization = authorization,
            !eventQueue.contains(where: { authorization.auth.token == ($0 as? RapidAuthRequest)?.auth.token }) {
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
        let acknowledgement = RapidClientAcknowledgement(eventID: eventID)
        
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
    func unsubscribe(_ handler: RapidUnsubscriptionManager) {
        RapidLogger.log(message: "Unsubscribe \(handler.subscription.subscriptionHash)", level: .info)
        
        activeSubscriptions[handler.subscription.subscriptionID] = nil
        
        // If the subscription is still in queue just remove it
        // Otherwise, send usubscription request
        if let subscriptionIndex = eventQueue.flatMap({ $0 as? RapidSubscriptionManager }).index(where: { $0.subscriptionID == handler.subscription.subscriptionID }) {
            eventQueue.remove(at: subscriptionIndex)
        }
        else {
            post(event: handler)
        }
    }
    
    func cancel(request: Request) {
        let index = eventQueue.index(where: {
            if let queuedRequest = $0 as? RapidClientRequest {
                return request === queuedRequest
            }
            
            return false
        })
        
        if let index = index {
            eventQueue.remove(at: index)
        }
        
        let pending = pendingRequests.filter({
            return $0.value.request === request
        })
        
        if let (eventID, _) = pending.first {
            pendingRequests[eventID] = nil
        }
        
        request.eventFailed(withError: RapidErrorInstance(eventID: Rapid.uniqueID, error: .cancelled))
    }
    
    /// Enque a event to the queue
    ///
    /// - Parameter serializableRequest: Request to be queued
    func post(event: Event, prioritize: Bool = false) {
        
        // Inform a timoutable request that it should start a timeout count down
        // User events can be timeouted only if user sets `Rapid.timeout`
        // System events work always with timeout and they use either a custom `Rapid.timeout` if set or a default `Rapid.defaultTimeout`
        if let timeoutRequest = event as? RapidTimeoutRequest, let timeout = timeout {
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
            let eventID = Rapid.uniqueID
            
            if let request = event as? Request {
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
    func registerPendingRequest(_ request: Request, withID eventID: String) {
        pendingRequests[eventID] = (request, Date().timeIntervalSince1970)
    }
    
    /// Handle an event sent from the server
    ///
    /// - Parameter response: Event sent from the server
    func handle(message: RapidServerMessage) {
        switch message {
        // Event failed
        case let message as RapidErrorInstance:
            let tuple = pendingRequests[message.eventID]
            tuple?.request.eventFailed(withError: message)
            
            // If subscription registration failed remove if from the list of active subscriptions
            if let subscription = tuple?.request as? RapidSubscriptionManager {
                activeSubscriptions[subscription.subscriptionID] = nil
            }
            // If fetch failed remove it from the list of pending fetches
            else if let fetch = tuple?.request as? RapidFetchInstance {
                pendingFetches[fetch.fetchID] = nil
            }
            // If time request failed remove it from the list of pending time requests
            else if tuple?.request is RapidTimeOffset && pendingTimeRequests.count > 0 {
                pendingTimeRequests.removeFirst()
            }
            // If on disconnect action failed remove it from the list of pending disconnect actions
            else if let action = tuple?.request as? RapidOnDisconnectAction, let actionID = action.actionID {
                onDisconnectActions[actionID] = nil
            }
            // If on connect action failed because of permission denied remove it from the list of pending connect actions
            else if let action = tuple?.request as? RapidOnConnectAction, let actionID = action.actionID, case .permissionDenied = message.error {
                onDisconnectActions[actionID] = nil
            }
            else if let request = tuple?.request as? RapidAuthRequest, self.auth?.token == request.auth.token {
                self.auth = nil
            }
            
            pendingRequests[message.eventID] = nil
        
        // Event acknowledged
        case let message as RapidServerAcknowledgement:
            let tuple = pendingRequests[message.eventID]
            tuple?.request.eventAcknowledged(message)
            pendingRequests[message.eventID] = nil
        
        // Subscription event
        case let message as RapidSubscriptionBatch:
            if let subscription = activeSubscriptions[message.subscriptionID] as? RapidColSubManager {
                subscription.receivedSubscriptionEvent(message)
            }
            
        // Subscription cancel
        case let message as RapidSubscriptionCancelled:
            let subscription = activeSubscriptions[message.subscriptionID]
            let eventID = message.eventIDsToAcknowledge.first ?? Rapid.uniqueID
            let error = RapidErrorInstance(eventID: eventID, error: .permissionDenied(message: "No longer authorized to read data"))
            subscription?.eventFailed(withError: error)
            activeSubscriptions[message.subscriptionID] = nil
            
        // On-disconnect action cancelled
        case let message as RapidOnDisconnectActionCancelled:
            let action = onDisconnectActions[message.actionID]
            let eventID = message.eventIDsToAcknowledge.first ?? Rapid.uniqueID
            let error = RapidErrorInstance(eventID: eventID, error: .permissionDenied(message: "No longer authorized to write data"))
            action?.eventFailed(withError: error)
            onDisconnectActions[message.actionID] = nil
            
        // Fetch response
        case let message as RapidFetchResponse:
            let fetch = pendingFetches[message.fetchID]
            fetch?.receivedData(message.documents)
            pendingFetches[message.fetchID] = nil
            
        // Channel message
        case let message as RapidChannelMessage:
            if let subscription = activeSubscriptions[message.subscriptionID] as? RapidChanSubManager {
                subscription.receivedMessage(message)
            }
            
        // Server timestamp
        case let message as RapidServerTimestamp:
            if pendingTimeRequests.count > 0 {
                let request = pendingTimeRequests.removeFirst()
                request.receivedTimestamp(message)
            }
        
        default:
            RapidLogger.developerLog(message: "Unrecognized response")
        }
        
        if let event = message as? RapidServerEvent {
            for eventID in event.eventIDsToAcknowledge {
                acknowledge(eventWithID: eventID)
            }
        }
    }
}

// MARK: Subscription handler delegate
extension RapidSocketManager: RapidSubscriptionManagerDelegate {
    
    func unsubscribe(handler: RapidUnsubscriptionManager) {
        websocketQueue.async { [weak self] in
            self?.unsubscribe(handler)
        }
    }
}

// MARK: Mutation request delegate
extension RapidSocketManager: RapidMutationRequestDelegate {
    
    func cancelMutationRequest<T>(_ request: T) where T : RapidMutationRequest {
        websocketQueue.async { [weak self] in
            self?.cancel(request: request)
        }
    }
}

// MARK: On-connect action delegate
extension RapidSocketManager: RapidOnConnectActionDelegate {
    
    func cancelOnConnectAction(withActionID actionID: String) {
        websocketQueue.async { [weak self] in
            if let action = self?.onConnectActions[actionID] {
                self?.onConnectActions[actionID] = nil
                self?.cancel(request: action)
            }
        }
    }
}

// MARK: On-disconnect action delegate
extension RapidSocketManager: RapidOnDisconnectActionDelegate {
    
    func cancelOnDisconnectAction(withActionID actionID: String) {
        websocketQueue.async { [weak self] in
            if let action = self?.onDisconnectActions[actionID] {
                self?.onDisconnectActions[actionID] = nil
                self?.cancel(request: action)
                self?.post(event: action.cancelRequest())
            }
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
        RapidLogger.log(message: "Rapid connected", level: .info)
    }
    
    /// Connection request failed
    ///
    /// - Parameters:
    ///   - request: Connection request that failed
    ///   - error: Reason of failure
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance) {
        RapidLogger.log(message: "Rapid connection failed", level: .info)
        
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
        RapidLogger.developerLog(message: "Request timeout \(request)")
        
        websocketQueue.async { [weak self] in
            // If the request is pending complete it with timeout error
            // Otherwise, if the request is still in the queue move it to pending requests and complete it with timeout error
            if let eventID = self?.eventID(forPendingRequest: request) {
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.handle(message: error)
            }
            else if let index = self?.eventQueue.flatMap({ $0 as? Request }).index(where: { request === $0 }), let request = request as? Request {
                self?.eventQueue.remove(at: index)
                
                let eventID = Rapid.uniqueID
                self?.registerPendingRequest(request, withID: eventID)
                
                let error = RapidErrorInstance(eventID: eventID, error: .timeout)
                self?.handle(message: error)
            }
        }
    }
}

// MARK: Concurrency optimistic mutation delegate
extension RapidSocketManager: RapidExectuionDelegate {
    
    func executionCompleted(_ execution: RapidExecution) {
        websocketQueue.async { [weak self] in
            self?.pendingExecutionRequests[execution.identifier] = nil
        }
    }
    
    func sendMutationRequest<T: RapidMutationRequest>(_ request: T) {
        mutate(mutationRequest: request)
    }
    
    func sendFetchRequest(_ request: RapidFetchInstance) {
        fetch(request)
    }
}

// MARK: Network manager delegate
extension RapidSocketManager: RapidNetworkHandlerDelegate {
    
    func socketDidConnect() {
        websocketQueue.async { [weak self] in
            self?.sendConnectionRequest()
            
            self?.state = .connected
            
            self?.handleDidConnect()
            
            self?.flushQueue()
        }
    }
    
    func socketDidDisconnect(withError error: RapidError?) {
        websocketQueue.async { [weak self] in
            self?.state = .disconnected
            
            self?.handleDidDisconnect(withError: error)
        }
    }
    
    func handlerDidReceive(message: RapidServerMessage) {
        websocketQueue.async { [weak self] in
            
            // Restart heartbeat timer
            self?.rescheduleHeartbeatTimer()
            
            self?.handle(message: message)
        }
    }
}
