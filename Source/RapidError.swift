//
//  RapidError.swift
//  Rapid
//
//  Created by Jan on 16/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

enum RapidError: Error {
    case rapidInstanceNotInitialized
    
    var message: String {
        switch self {
        case .rapidInstanceNotInitialized:
            return "Rapid instance not initialized"
        }
    }
}
