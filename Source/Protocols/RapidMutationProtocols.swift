//
//  RapidMutateProtocol.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidConcurrencyOptimisticMutation {
    var identifier: String { get }
    var fetchRequest: RapidFetchInstance { get }
}

protocol RapidConOptMutationDelegate: class {
    func sendConOptRequest<Request: RapidRequest>(_ request: Request) where Request: RapidSerializable
    func conOptMutationCompleted(_ mutation: RapidConcurrencyOptimisticMutation)
}

/// Protocol describing concurrency optimistic request
protocol RapidConcOptRequest {
    var etag: String? { get set }
}

/// Protocol describing mutation request
protocol RapidMutationRequest: RapidTimeoutRequest, RapidSerializable, RapidConcOptRequest {
}
