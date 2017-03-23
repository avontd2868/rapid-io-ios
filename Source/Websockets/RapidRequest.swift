//
//  RapidRequest.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidSerializable {
    func serialize(withIdentifiers identifiers: [AnyHashable: Any]) throws -> String
}

protocol RapidRequest {
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement)
    func eventFailed(withError error: RapidErrorInstance)
}

protocol RapidConnectionRequestDelegate: class {
    func connectionEstablished(_ request: RapidConnectionRequest)
    func connectingFailed(_ request: RapidConnectionRequest, error: RapidErrorInstance)
}

protocol RapidHeartbeatDelegate: class {
    func connectionExpired(_ heartbeat: RapidHeartbeat)
    func connectionAlive(_ heartbeat: RapidHeartbeat)
}

struct RapidConnectionRequest: RapidRequest, RapidSerializable {
    
    let connectionID: String
    fileprivate weak var delegate: RapidConnectionRequestDelegate?
    
    init(connectionID: String, delegate: RapidConnectionRequestDelegate) {
        self.connectionID = connectionID
        self.delegate = delegate
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(connection: self, withIdentifiers: identifiers)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        delegate?.connectionEstablished(self)
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        delegate?.connectingFailed(self, error: error)
    }
}

struct RapidDisconnectionRequest: RapidSerializable, RapidRequest {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(disconnection: self, withIdentifiers: identifiers)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
    }
}

struct RapidHeartbeat: RapidSerializable, RapidRequest {
    
    fileprivate weak var delegate: RapidHeartbeatDelegate?
    
    init(delegate: RapidHeartbeatDelegate) {
        self.delegate = delegate
    }
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(heartbeat: self, withIdentifiers: identifiers)
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        delegate?.connectionExpired(self)
    }
    
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement) {
        delegate?.connectionAlive(self)
    }
}
