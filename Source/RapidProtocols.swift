//
//  RapidSubscriptionReference.swift
//  Rapid
//
//  Created by Jan on 13/07/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Common protocol for channel references
public protocol RapidSubscriptionReference {
    associatedtype Result
    
    @discardableResult
    func subscribe(block: @escaping (RapidResult<Result>) -> Void) -> RapidSubscription
}

/// Common protocol for channel references
public protocol RapidFetchReference {
    associatedtype Result
    
    func fetch(completion: @escaping (RapidResult<Result>) -> Void)
}
