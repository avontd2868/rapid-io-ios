//
//  RapidAuthorization.swift
//  Rapid
//
//  Created by Jan on 20/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Rapid authorization
public struct RapidAuthorization {
    
    /// Authorization access token
    public let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
}
