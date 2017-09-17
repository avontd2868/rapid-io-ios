//
//  Helpers.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

struct UserDefaultsManager {
    
    static var username: String {
        get {
            return UserDefaults.standard.string(forKey: "RapiChatUsername") ?? ""
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "RapiChatUsername")
            UserDefaults.standard.synchronize()
        }
    }
    
    static func lastReadMessage(inChannel channelID: String) -> String? {
        if let readIDs = UserDefaults.standard.dictionary(forKey: "RapiChatReadMessages") as? [String: String] {
            return readIDs[channelID]
        }
        
        return nil
    }
    
    static func readMessage(withID messageID: String, inChannel channelID: String) {
        var readIDs = UserDefaults.standard.dictionary(forKey: "RapiChatReadMessages") ?? [:]
        readIDs[channelID] = messageID
        UserDefaults.standard.set(readIDs, forKey: "RapiChatReadMessages")
        UserDefaults.standard.synchronize()
    }
}
