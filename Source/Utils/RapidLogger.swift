//
//  RapidLogger.swift
//  Rapid
//
//  Created by Jan on 21/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidLogger {
    
    enum Priority {
        case high
        case normal
    }
    
    static var logDebugMessages = false
    static var logMessages = false
    
    class func log(message: String, priority: Priority = .normal) {
        #if DEBUG
            switch priority {
            case .high:
                NSLog(message)
                
            case .normal where logMessages:
                NSLog(message)
                
            default:
                break
            }
        #else
            if priority == .high {
                NSLog(message)
            }
        #endif
    }
    
    class func debugLog(message: String) {
        #if RAPIDDEBUG
            if logDebugMessages {
                print(message)
            }
        #endif
    }
}
