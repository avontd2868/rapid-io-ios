//
//  RapidConditionedActionsProtocols.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

protocol RapidOnConnectActionDelegate: class {
    func cancelOnConnectAction(withActionID actionID: String)
}

protocol RapidOnConnectAction: RapidClientRequest, RapidSerializable {
    var actionID: String? { get }
    func register(actionID: String, delegate: RapidOnConnectActionDelegate)
}

extension RapidOnConnectAction {
    var shouldSendOnReconnect: Bool {
        return false
    }
}

protocol RapidOnDisconnectActionDelegate: class {
    func cancelOnDisconnectAction(withActionID actionID: String)
}

protocol RapidOnDisconnectAction: RapidClientRequest, RapidSerializable {
    var actionID: String? { get }
    func actionJSON() throws -> [AnyHashable: Any]
    func register(actionID: String, delegate: RapidOnDisconnectActionDelegate)
    func cancelRequest() -> RapidCancelOnDisconnectAction
}

extension RapidOnDisconnectAction {
    var shouldSendOnReconnect: Bool {
        return false
    }
}
