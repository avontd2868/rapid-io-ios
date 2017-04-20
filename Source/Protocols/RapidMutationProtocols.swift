//
//  RapidMutateProtocol.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Protocol describing mutation request
protocol RapidMutationRequest: RapidTimeoutRequest, RapidSerializable {
}

/// Protocol describing merge request
protocol RapidMergeRequest: RapidTimeoutRequest, RapidSerializable {
}
