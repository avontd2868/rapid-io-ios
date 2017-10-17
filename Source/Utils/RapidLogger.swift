//
//  RapidLogger.swift
//  Rapid
//
//  Created by Jan on 21/04/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

/// Logger singleton
class RapidLogger {
    
    static let developerLogging = false
    static var level: RapidLogLevel = .critical
    
    class func log(message: String, level: RapidLogLevel) {
        if level.rawValue <= self.level.rawValue {
            NSLog("RapidSDK - \(message)")
        }
    }
    
    class func developerLog(message: String) {
        if developerLogging && level == .debug {
            print("RapidSDK - \(message)")
        }
    }

}
