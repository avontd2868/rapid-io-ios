//
//  AppDelegate.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Set log level
        Rapid.logLevel = .info
        
        // Configure shared singleton with API key
        Rapid.configure(withApiKey: "MTQwdDAxZTFqNm5vZnh0dC5hcHAtcmFwaWQuaW8=")
        // Enable data cache
        Rapid.isCacheEnabled = true
        
        return true
    }
    
}

