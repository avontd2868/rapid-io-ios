//
//  PNManager.swift
//  RapiChat
//
//  Created by Jan on 08/09/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class PNManager {
    
    static let shared = PNManager()
    
    private let sender = AzureHubSender()
    private var notificationsRegistered = false
    private var channels: [String] = []
    
    fileprivate let notificationHub: SBNotificationHub = {
        return SBNotificationHub(connectionString: "Endpoint=sb://rapichat.servicebus.windows.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=C2ecROm6T2pZa25KgLSfACDlilFL+3FD5jGmXQqmVLU=", notificationHubPath: "RapiChat")
    }()
    
    func listenToChannels(withNames names: [String]) {
        channels = names
        if notificationsRegistered {
            register()
        }
    }

    func register() {
        notificationsRegistered = true
        if let token = UserDefaultsManager.deviceToken {
            let tags = Set(channels)
            
            notificationHub.registerNative(withDeviceToken: token, tags: tags) { error in
                print(error)
            }
        }
    }
    
    func sendNotification(toChannel channel: String, withText text: String) {
        sender.sendNotification(text, toChannel: channel)
    }
}
