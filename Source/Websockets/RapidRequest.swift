//
//  RapidRequest.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidSerializable {
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String
}

protocol RapidRequest: class {
    var needsAcknowledgement: Bool { get }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement)
    func eventFailed(withError error: RapidErrorInstance)
}

protocol RapidTimeoutRequest: RapidRequest {
    var alwaysTimeout: Bool { get }
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate)
}

protocol RapidTimeoutRequestDelegate: class {
    func requestTimeout(_ request: RapidTimeoutRequest)
}

protocol RapidConnectionRequestDelegate: class {
    func connectionEstablished(_ request: RapidConnectionRequest)
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance)
}

protocol RapidHeartbeatDelegate: class {
    func connectionDead(_ heartbeat: RapidHeartbeat, error: RapidErrorInstance)
    func connectionAlive(_ heartbeat: RapidHeartbeat)
}

class RapidConnectionRequest: RapidTimeoutRequest, RapidSerializable {
    
    let alwaysTimeout = true
    let needsAcknowledgement = true
    
    let connectionID: String
    fileprivate weak var delegate: RapidConnectionRequestDelegate?
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    init(connectionID: String, delegate: RapidConnectionRequestDelegate) {
        self.connectionID = connectionID
        self.delegate = delegate
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(connection: self, withIdentifiers: identifiers)
    }
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
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

class RapidDisconnectionRequest: RapidSerializable, RapidRequest {
    
    let needsAcknowledgement = false

    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(disconnection: self, withIdentifiers: identifiers)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
    }
}

class RapidHeartbeat: RapidSerializable, RapidTimeoutRequest {
    
    fileprivate weak var delegate: RapidHeartbeatDelegate?
    fileprivate weak var timoutDelegate: RapidTimeoutRequestDelegate?
    
    fileprivate var timer: Timer?
    
    let alwaysTimeout = true
    let needsAcknowledgement = true
    
    init(delegate: RapidHeartbeatDelegate) {
        self.delegate = delegate
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(heartbeat: self, withIdentifiers: identifiers)
    }
    
    func requestSent(withTimeout timeout: TimeInterval, delegate: RapidTimeoutRequestDelegate) {
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
