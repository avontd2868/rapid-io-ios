//
//  RapidConnectionRequests.swift
//  Rapid
//
//  Created by Jan on 28/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

// MARK: Connect

/// Delegate for informing about connection request result
protocol RapidConnectionRequestDelegate: class {
    func connectionEstablished(_ request: RapidConnectionRequest)
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance)
}

/// Connection request
class RapidConnectionRequest {
    
    /// Request should timeout even if `Rapid.timeout` is `nil`
    let alwaysTimeout = true
    
    /// Requst waits for acknowledgement
    let needsAcknowledgement = true
    
    /// ID associated with an abstract connection
    let connectionID: String
    
    /// Connection result delegate
    fileprivate weak var delegate: RapidConnectionRequestDelegate?
    
    /// Timout delegate
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    init(connectionID: String, delegate: RapidConnectionRequestDelegate) {
        self.connectionID = connectionID
        self.delegate = delegate
    }
    
}

extension RapidConnectionRequest: RapidTimeoutRequest {
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
        // Start timeout
        self.timoutDelegate = delegate
        
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                self?.timer = Timer.scheduledTimer(timeInterval: timeout, target: strongSelf, selector: #selector(strongSelf.requestTimeout), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func requestTimeout() {
        timer = nil
        
        timoutDelegate?.requestTimeout(self)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.delegate?.connectionEstablished(self)
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.delegate?.connectingFailed(self, error: error)
        }
    }

}

extension RapidConnectionRequest: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(connection: self, withIdentifiers: identifiers)
    }
    
}

// MARK: Disconnect

/// Disconnection request
class RapidDisconnectionRequest {
    
    /// Requst doesn't wait for acknowledgement
    let needsAcknowledgement = false
}

extension RapidDisconnectionRequest: RapidSerializable {
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(disconnection: self, withIdentifiers: identifiers)
    }
}

extension RapidDisconnectionRequest: RapidRequest {
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {}
    func eventFailed(withError error: RapidErrorInstance) {}
}

// MARK: Heartbeat

/// Delegate for informing about heartbeat request result
protocol RapidHeartbeatDelegate: class {
    func connectionDead(_ heartbeat: RapidHeartbeat, error: RapidErrorInstance)
    func connectionAlive(_ heartbeat: RapidHeartbeat)
}

/// Heartbeat request
class RapidHeartbeat {
    
    /// Request should timeout even if `Rapid.timeout` is `nil`
    let alwaysTimeout = true
    
    /// Requst waits for acknowledgement
    let needsAcknowledgement = true
    
    /// Connection result delegate
    fileprivate weak var delegate: RapidHeartbeatDelegate?
    
    /// Timout delegate
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    init(delegate: RapidHeartbeatDelegate) {
        self.delegate = delegate
    }
    
}

extension RapidHeartbeat: RapidTimeoutRequest {
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
        // Start timeout
        self.timoutDelegate = delegate
        
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                self?.timer = Timer.scheduledTimer(timeInterval: timeout, target: strongSelf, selector: #selector(strongSelf.requestTimeout), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func requestTimeout() {
        timer = nil
        
        timoutDelegate?.requestTimeout(self)
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            switch error.error {
            case .timeout, .connectionTerminated:
                self.delegate?.connectionDead(self, error: error)
                
            default:
                break
            }
        }
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            
            self.delegate?.connectionAlive(self)
        }
    }
    
}

extension RapidHeartbeat: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(heartbeat: self, withIdentifiers: identifiers)
    }
    
}
