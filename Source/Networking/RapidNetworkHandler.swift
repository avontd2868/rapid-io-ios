//
//  RapidNetworkHandler.swift
//  Rapid
//
//  Created by Jan on 11/04/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

protocol RapidNetworkHandlerDelegate: class {
    func socketDidConnect()
    func socketDidDisconnect(withError error: RapidError?)
    func handlerDidReceive(message: RapidServerMessage)
}

class RapidNetworkHandler {
    
    /// Websocket URL
    let socketURL: URL
    
    /// Websocket object
    internal let socket: WebSocket
    
    /// State of a websocket connection
    internal(set) var state: RapidConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                onConnectionStateChanged?(state)
            }
        }
    }
    
    /// Socket was intentionally terminated
    internal var socketTerminated = false
    
    /// Timer that limits maximum time span when websocket connection is trying to be established
    internal var socketConnectTimer: Timer?
    
    /// Error that led to forced websocket reconnection
    internal var reconnectionError: RapidError?
    
    /// Dedicated threads
    internal let parseQueue: DispatchQueue
    internal let mainQueue = DispatchQueue.main
    
    /// Network handler delegate
    weak var delegate: RapidNetworkHandlerDelegate?
    
    /// Connection state changed handler
    var onConnectionStateChanged: ((RapidConnectionState) -> Void)?
    
    init(socketURL: URL) {
        self.parseQueue = DispatchQueue(label: "RapidParseQueue-\(socketURL.lastPathComponent)", attributes: [])
        self.socketURL = socketURL
        self.socket = WebSocket(url: socketURL)
        
        self.socket.delegate = self
    }
    
    deinit {
        destroySocket()
    }
    
    /// Reconnect previously configured websocket
    func goOnline() {
        mainQueue.async { [weak self] in
            self?.socketTerminated = false
            
            if let state = self?.state, state != .connected {
                self?.createConnection()
            }
        }
    }
    
    /// Disconnect existing websocket
    func goOffline() {
        mainQueue.async { [weak self] in
            if let state = self?.state, state != .disconnected {
                self?.destroySocket()
            }
        }
    }
    
    /// Force connection restart
    func restartSocket(afterError error: RapidError?) {
        mainQueue.async { [weak self] in
            RapidLogger.developerLog(message: "Restart socket")
            
            // If socket is connected, disconnect it
            // If socket is not connected and it wasn't intentionally closed, then call reconnection handler directly
            if let socket = self?.socket, socket.isConnected {
                self?.disconnectSocket(withError: error)
            }
            else if let terminated = self?.socketTerminated, !terminated {
                self?.state = .disconnected
                
                self?.delegate?.socketDidDisconnect(withError: error)
            }
        }
    }
    
    /// Post event to websocket
    ///
    /// - Parameter serializableRequest: Request which is going to be sent
    func write(event: RapidSocketManager.Event, withID eventID: String) {
        parseQueue.async { [weak self] in
            do {
                let jsonString = try event.serialize(withIdentifiers: [RapidSerialization.EventID.name: eventID])
                
                let sizeLimit: Int
                switch event {
                case is RapidChannelPublish:
                    sizeLimit = 3072
                    
                default:
                    sizeLimit = 10240
                }
                
                let size = jsonString.data(using: .utf8)?.count ?? 0
                
                guard size <= sizeLimit else {
                    let message: String
                    switch event {
                    case is RapidChannelPublish:
                        message = "Message is too large - \(size) B. Message size limit is \(Int(sizeLimit/1024)) kB"
                        
                    default:
                        message = "Document is too large - \(size) B. Document size limit is \(Int(sizeLimit/1024)) kB"
                    }
                    throw RapidError.invalidRequest(message: message)
                }
                
                RapidLogger.developerLog(message: "Write request \(jsonString)")
                
                self?.mainQueue.async {
                    self?.socket.write(string: jsonString)
                }
            }
            catch let rapidError as RapidError {
                self?.delegate?.handlerDidReceive(message: RapidErrorInstance(eventID: eventID, error: rapidError))
            }
            catch let error {
                self?.delegate?.handlerDidReceive(message: RapidErrorInstance(eventID: eventID, error: .invalidData(reason: .serializationFailure(message: error.localizedDescription))))
            }
        }
    }
    
}

// MARK: Private methods
internal extension RapidNetworkHandler {
    
    /// Create a websocket connection
    func createConnection() {
        // Start the timer that limits maximum time span when websocket connection is trying to be established
        RapidLogger.developerLog(message: "Create connection")
        
        state = .connecting
        
        socketConnectTimer?.invalidate()
        socketConnectTimer = Timer.scheduledTimer(timeInterval: Rapid.defaultTimeout, userInfo: nil, repeats: false, block: { [weak self] (_) in
            self?.connectSocketTimout()
        })
        
        connectSocket()
    }
    
    // Destroy existing socket connection
    func destroySocket() {
        RapidLogger.developerLog(message: "Destroy socket")
        
        socketTerminated = true
        
        disconnectSocket()
        
        state = .disconnected
    }
    
    func connectSocket() {
        socket.connect()
    }
    
    func disconnectSocket(withError error: RapidError? = nil) {
        reconnectionError = error
        
        socket.disconnect(forceTimeout: 0.5)
    }
    
    /// Websocket connection hasn't been established for too long
    func connectSocketTimout() {
        socketConnectTimer = nil

        restartSocket(afterError: .timeout)
    }
    
    /// Parse message received from websocket
    ///
    /// - Parameter message: Message received from websocket
    func parse(message: String) {
        RapidLogger.developerLog(message: "Received message \(message)")
        
        if let data = message.data(using: .utf8) {
            parse(data: data)
        }
    }
    
    /// Parse data received from websocket
    ///
    /// - Parameter data: Data received from websocket
    func parse(data: Data) {
        let json = try? data.json()
        
        parseQueue.async { [weak self] in
            if let json = json, let responses = RapidSerialization.parse(json: json) {
                self?.mainQueue.async {
                    for response in responses {
                        self?.delegate?.handlerDidReceive(message: response)
                    }
                }
            }
        }
    }
    
}

// MARK: Websocket delegate
extension RapidNetworkHandler: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        mainQueue.async {
            guard !self.socketTerminated else {
                self.destroySocket()
                return
            }
            
            RapidLogger.developerLog(message: "Socket did connect")
            
            // Invalidate connection timer
            self.socketConnectTimer?.invalidate()
            self.socketConnectTimer = nil
            
            self.state = .connected
            
            self.delegate?.socketDidConnect()
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        mainQueue.async {
            RapidLogger.developerLog(message: "Socket did disconnect \(String(describing: error))")
            
            // Invalidate connection timer
            self.socketConnectTimer?.invalidate()
            self.socketConnectTimer = nil
            
            switch self.state {
            case .connected:
                self.state = .connecting
                
            default:
                self.state = .disconnected
            }
            
            // If the connection wasn't terminated intentionally reconnect it
            if !self.socketTerminated {
                let error = self.reconnectionError
                
                // Wait for socket to be closed
                runAfter(1, queue: self.mainQueue, closure: { [weak self] in
                    self?.delegate?.socketDidDisconnect(withError: error)
                })
            }
            
            self.reconnectionError = nil
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        mainQueue.async {
            self.parse(data: data)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        mainQueue.async {
            self.parse(message: text)
        }
    }
}
