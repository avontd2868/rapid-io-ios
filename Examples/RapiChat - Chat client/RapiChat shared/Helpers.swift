//
//  Helpers.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import Rapid

struct UserDefaultsManager {
    
    static func generateUsername(completion: @escaping (_ username: String) -> Void) {
        if let name = UserDefaults.standard.string(forKey: "RapiChatUsername") {
            completion(name)
        }
        else {
            RandomNameGenerator.randomName(completion: { username in
                UserDefaults.standard.set(username, forKey: "RapiChatUsername")
                UserDefaults.standard.synchronize()
                completion(username)
            })
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

struct RandomNameGenerator {
    
    static var task: URLSessionDataTask?
    
    static func randomName(completion: @escaping (_ username: String) -> Void) {
        var request = URLRequest(url: URL(string: "https://randomuser.me/api/")!)
        request.httpMethod = "GET"
        task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data,
                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any],
                let results = dict?["results"] as? [[AnyHashable: Any]],
                let person = results.first,
                let name = person["name"] as? [AnyHashable: Any],
                let first = name["first"] as? String,
                let last = name["last"] as? String {
                
                DispatchQueue.main.async {
                    completion("\(first) \(last)")
                }
            }
            else {
                DispatchQueue.main.async {
                    completion("john smith")
                }
            }
        }
        task?.resume()
    }
}

class Validator {
    
    class func isValid(collectionName name: String) -> Bool {
        var components = name.components(separatedBy: "-")
        
        guard components.count > 2 else {
            return false
        }
        
        let first = components.remove(at: 0)
        
        let uuid = NSUUID(uuidString: components.joined(separator: "-"))
        
        return (first == "channels" || first == "messages") && uuid != nil
    }
}

class TimeManager {
    
    static let shared = TimeManager()
    private(set) var offset: TimeInterval = 0
    
    var serverTime: Date {
        return Date().addingTimeInterval(-offset)
    }
    
    func initialize() {
        NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.getTimeOffset()
        }
        
        getTimeOffset()
    }
    
    private func getTimeOffset() {
        Rapid.serverTimeOffset { [weak self] result in
            if case .success(let offset) = result {
                self?.offset = offset
            }
        }
    }
}
