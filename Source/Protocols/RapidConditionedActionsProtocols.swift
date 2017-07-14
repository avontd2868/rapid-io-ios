//
//  RapidConditionedActionsProtocols.swift
//  Rapid
//
//  Created by Jan on 14/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidOnConnectActionDelegate: class {
    func mutate<T: RapidMutationRequest>(mutationRequest: T)
    func cancelOnConnectAction(withActionID actionID: String)
}

protocol RapidOnConnectAction: RapidClientRequest, RapidSerializable {
    func register(actionID: String, delegate: RapidOnConnectActionDelegate)
    func performAction()
}
