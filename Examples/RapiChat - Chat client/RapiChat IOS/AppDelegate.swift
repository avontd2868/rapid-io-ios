//
//  AppDelegate.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Set log level
        Rapid.logLevel = .info
        
        // Configure shared singleton with API key
        Rapid.configure(withApiKey: "<YOUR API KEY>")
        // Enable data cache
        Rapid.isCacheEnabled = true
        
        Rapid.decoder.rapidDocumentDecodingKeys.documentIdKey = "id"
        Rapid.decoder.dateDecodingStrategy = .millisecondsSince1970
        Rapid.encoder.dateEncodingStrategy = .millisecondsSince1970
        
        return true
    }
    
}

