//
//  RapidLogger.swift
//  Rapid
//
//  Created by Jan on 21/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class RapidLogger {
    
    public enum Level: Int {
        case off
        case critical
        case info
        case debug
    }
    
    static let developerLogging = true
    static var level: Level = .critical
    
    class func log(message: String, level: Level) {
        if level.rawValue <= self.level.rawValue {
            #if DEBUG
                NSLog("RapidSDK - \(message)")
            #else
                if level == .critical {
                    NSLog("RapidSDK - \(message)")
                }
            #endif
        }
    }
    
    class func developerLog(message: String) {
        #if RAPIDDEBUG
            if developerLogging && level == .debug {
                print("RapidSDK - \(message)")
            }
        #endif
    }

}