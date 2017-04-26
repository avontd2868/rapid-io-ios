//
//  RapidCacheTests.swift
//  Rapid
//
//  Created by Jan on 18/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation
import XCTest
@testable import Rapid

extension RapidTests {
    
    func testCacheForEmptyString() {
        XCTAssertNil(RapidCache(apiKey: ""), "Cache created")
        XCTAssertNil(RapidCache(apiKey: apiKey, timeToLive: -1), "Cache created")
        XCTAssertNil(RapidCache(apiKey: apiKey, maxSize: -5), "Cache created")
        XCTAssertNotNil(RapidCache(apiKey: apiKey, timeToLive: nil, maxSize: nil), "Cache not created")
    }
    
    func testRemoteURLSize() {
        XCTAssertNil(socketURL.memorySize, "Size not nil")
    }
    
    func testSizeOfNonexistingFile() {
        XCTAssertNil(URL(string: "file:///Users/djlffkslfj/fake")!.memorySize, "Size not nil")
    }
    
    func testFileSize() {
        let plistURL = Bundle(for: RapidTests.self).url(forResource: "Info", withExtension: "plist")
        XCTAssertGreaterThan(plistURL?.memorySize ?? 0, 0, "Zero size")
    }
    
    func testDirectorySize() {
        let bundleURL = Bundle(for: RapidTests.self).bundleURL
        XCTAssertGreaterThan(bundleURL.memorySize ?? 0, 0, "Zero size")
    }
    
    func testFrequencies() {
        let testString = "#abc~#&_±±±b~#"
        let frequencies = testString.characters.frequencies
        
        for (character, frequency) in frequencies {
            switch character {
            case "#":
                XCTAssertEqual(frequency, 3)
                
            case "a":
                XCTAssertEqual(frequency, 1)
                
            case "b":
                XCTAssertEqual(frequency, 2)
                
            case "c":
                XCTAssertEqual(frequency, 1)
                
            case "~":
                XCTAssertEqual(frequency, 2)
                
            case "&":
                XCTAssertEqual(frequency, 1)
                
            case "_":
                XCTAssertEqual(frequency, 1)
                
            case "±":
                XCTAssertEqual(frequency, 3)
                
            default:
                break
            }
        }
    }
    
    func testASCIIValues() {
        let testString = "#abc~&_±"
        
        for character in testString.characters {
            switch character {
            case "#":
                XCTAssertEqual(character.asciiValue, 35)
                
            case "a":
                XCTAssertEqual(character.asciiValue, 97)
                
            case "b":
                XCTAssertEqual(character.asciiValue, 98)
                
            case "c":
                XCTAssertEqual(character.asciiValue, 99)
                
            case "~":
                XCTAssertEqual(character.asciiValue, 126)
                
            case "&":
                XCTAssertEqual(character.asciiValue, 38)
                
            case "_":
                XCTAssertEqual(character.asciiValue, 95)
                
            case "±":
                XCTAssertNil(character.asciiValue)
                
            default:
                break
            }
        }
    }
    
    func testCreateCacheDir() {
        let cacheURL = RapidCache.cacheURL(forAPIKey: apiKey)!
        
        do {
            try FileManager.default.removeItem(at: cacheURL)
        }
        catch {
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                XCTFail("Cache not deleted")
            }
        }
        
        _ = RapidCache(apiKey: apiKey)
        
        if !FileManager.default.fileExists(atPath: cacheURL.path) {
            XCTFail("Cache not created")
        }
    }
    
    func testOverrideFileWithCacheDir() {
        let cacheURL = RapidCache.cacheURL(forAPIKey: apiKey)!
        
        do {
            try FileManager.default.removeItem(at: cacheURL)
        }
        catch {
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                XCTFail("Cache not deleted")
            }
        }
        
        FileManager.default.createFile(atPath: cacheURL.path, contents: Data(), attributes: nil)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: cacheURL.path, isDirectory: &isDir) {
            XCTAssertFalse(isDir.boolValue, "File not created")
        }
        else {
            XCTFail("File not created")
        }

        _ = RapidCache(apiKey: apiKey)
        
        if FileManager.default.fileExists(atPath: cacheURL.path, isDirectory: &isDir) {
            XCTAssertTrue(isDir.boolValue, "Directory not created")
        }
        else {
            XCTFail("Cache not created")
        }
    }
    
    func testSaveCache() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "testString" as NSString, forKey: "testKey")
        
        cache?.cache(forKey: "testKey", completion: { (value) in
            if let value = value as? NSString, value.isEqual(to: "testString") {
                promise.fulfill()
            }
            else{
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testOverwriteCache() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "testString" as NSString, forKey: "testKey")
        cache?.save(data: "testtest" as NSString, forKey: "testKey")
        
        cache?.cache(forKey: "testKey", completion: { (value) in
            if let value = value as? NSString, value.isEqual(to: "testtest") {
                promise.fulfill()
            }
            else{
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testHasCache() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "testString" as NSString, forKey: "testKey")
        cache?.save(data: "testString2" as NSString, forKey: "testKey2")
        
        cache?.hasCache(forKey: "testKey", completion: { (has) in
            XCTAssertTrue(has, "No cache")
        })
        
        cache?.hasCache(forKey: "testKey2", completion: { (has) in
            XCTAssertTrue(has, "No cache")
        })
        
        cache?.clearCache(forKey: "testKey")
        
        cache?.hasCache(forKey: "testKey", completion: { (has) in
            XCTAssertFalse(has, "No cache")
            
            cache?.clearCache()
            
            cache?.hasCache(forKey: "testKey2", completion: { (has) in
                XCTAssertFalse(has, "No cache")
                
                promise.fulfill()
            })
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testClearCache() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "testString" as NSString, forKey: "testKey")
        cache?.save(data: "testString2" as NSString, forKey: "testKey2")
        
        cache?.clearCache(forKey: "testKey")
        
        cache?.cache(forKey: "testKey", completion: { (value) in
            if value != nil {
                XCTFail("Cache not cleared")
            }
            else {
                cache?.clearCache()
                
                cache?.cache(forKey: "testString2", completion: { (value) in
                    if value == nil {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Cache not cleared")
                    }
                })
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testClearCacheClassMethod() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "testString" as NSString, forKey: "testKey")
        cache?.save(data: "testString2" as NSString, forKey: "testKey2")
        
        RapidCache.clearCache(forAPIKey: apiKey)
        
        cache?.cache(forKey: "testKey", completion: { (value) in
            if value != nil {
                XCTFail("Cache not cleared")
            }
            else {
                cache?.cache(forKey: "testString2", completion: { (value) in
                    if value == nil {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Cache not cleared")
                    }
                })
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testHashFunction() {
        let cache = RapidCache(apiKey: apiKey)
        
        let numberOfTests = 10000
        let maxLength = 100
        
        var strings = [String]()
        
        for _ in 0 ..< numberOfTests {
            let length = Int(arc4random_uniform(UInt32(maxLength))) + 1
            
            strings.append(randomString(withLength: length))
        }
        
        var hashes = Set<UInt64>()
        var numberOfColisions = 0
        
        for string in strings {
            guard let hash = cache?.hash(forKey: string) else {
                continue
            }
            
            XCTAssertNotEqual(hash, 0)
            
            if !hashes.contains(hash) {
                hashes.insert(hash)
            }
            else {
                numberOfColisions += 1
            }
        }
        
        XCTAssertLessThan(numberOfColisions, numberOfTests / 20)
    }
    
    func testCollidingKeys() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        let key1 = "`]cCyVAlN^]h>x,>&nE_iE,0x;\"[jF1j0Biu0*ew3D/dl^V1}J~S]X]\\wrxr/6Y./N8}*0Yrw$K]37n%3H^Vscg50hary>"
        let key2 = ".de:3uKF:L5{Y;§gq@g,J\"KWp}h~>GN{(+^M$?_k#@ZcwMkMz|Uv2,90±TaQID9'aE6]S~_EL6VvknU<~+0^"
        
        XCTAssertEqual(cache?.hash(forKey: key1), cache?.hash(forKey: key2))
        
        cache?.save(data: "test1" as NSString, forKey: key1)
        cache?.save(data: "test2" as NSString, forKey: key2)
        
        cache?.cache(forKey: key1, completion: { (value) in
            if !((value as? NSString)?.isEqual(to: "test1") ?? false) {
                XCTFail("Cache not loaded")
            }
        })
        
        cache?.cache(forKey: key2, completion: { (value) in
            if let value = value as? NSString, value.isEqual(to: "test2") {
                promise.fulfill()
            }
            else{
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRemoveCollidingKeys() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        let key1 = "`]cCyVAlN^]h>x,>&nE_iE,0x;\"[jF1j0Biu0*ew3D/dl^V1}J~S]X]\\wrxr/6Y./N8}*0Yrw$K]37n%3H^Vscg50hary>"
        let key2 = ".de:3uKF:L5{Y;§gq@g,J\"KWp}h~>GN{(+^M$?_k#@ZcwMkMz|Uv2,90±TaQID9'aE6]S~_EL6VvknU<~+0^"
        
        XCTAssertEqual(cache?.hash(forKey: key1), cache?.hash(forKey: key2))
        
        cache?.save(data: "test1" as NSString, forKey: key1)
        cache?.save(data: "test2" as NSString, forKey: key2)
        
        cache?.clearCache(forKey: key1)
        
        cache?.cache(forKey: key2, completion: { (value) in
            if let value = value as? NSString, value.isEqual(to: "test2") {
                promise.fulfill()
            }
            else{
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testOutdatedFilesPruning() {
        let promise = expectation(description: "Load cache")
        
        var cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "test1" as NSString, forKey: "testKey")
        
        runAfter(1.5) {
            cache = RapidCache(apiKey: self.apiKey, timeToLive: 1)
            
            cache?.cache(forKey: "testKey", completion: { (value) in
                if value == nil {
                    cache?.save(data: "test1" as NSString, forKey: "testKey")
                    
                    cache?.cache(forKey: "testKey", completion: { (value) in
                        if let value = value as? NSString, value.isEqual(to: "test1") {
                            promise.fulfill()
                        }
                        else{
                            XCTFail("Cache not loaded")
                        }
                    })
                }
                else {
                    XCTFail("Cache not pruned")
                }
            })
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSizePruning() {
        let promise = expectation(description: "Load cache")
        
        var cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "test1" as NSString, forKey: "testKey")
        cache?.save(data: "test2" as NSString, forKey: "testKey2")
        
        runAfter(1.5) {
            cache = RapidCache(apiKey: self.apiKey, maxSize: 0.000000000000001)
            
            cache?.cache(forKey: "testKey", completion: { (value) in
                if value == nil {
                    cache?.save(data: "test1" as NSString, forKey: "testKey")
                    
                    cache?.cache(forKey: "testKey", completion: { (value) in
                        if let value = value as? NSString, value.isEqual(to: "test1") {
                            promise.fulfill()
                        }
                        else{
                            XCTFail("Cache not loaded")
                        }
                    })
                }
                else {
                    XCTFail("Cache not pruned")
                }
            })
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSaveEncryptedCache() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        let secret = Rapid.uniqueID
        
        cache?.save(data: "testString" as NSString, forKey: "testKey", secret: secret)
        
        cache?.cache(forKey: "testKey", secret: secret, completion: { (value) in
            if let value = value as? NSString, value.isEqual(to: "testString") {
                promise.fulfill()
            }
            else{
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testLoadEncryptedCacheError() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(data: "testString" as NSString, forKey: "testKey", secret: Rapid.uniqueID)
        
        cache?.cache(forKey: "testKey", secret: Rapid.uniqueID, completion: { (value) in
            if value == nil {
                promise.fulfill()
            }
            else{
                XCTFail("Did access cache")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testLoadingSubscriptionFromCache() {
        let promise = expectation(description: "Load cached data")
        Rapid.debugLoggingEnabled = true
        rapid.isCacheEnabled = true
        
        var socketManager: RapidSocketManager!
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "testLoadingSubscriptionFromCache"]) { (_, _) in
            
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe(completion: { (_, docs) in
                XCTAssertGreaterThan(docs.count, 0, "No documents")
                
                if initialValue {
                    initialValue = false
                    let documents = docs
                    let networkHanlder = RapidNetworkHandler(socketURL: self.fakeSocketURL)
                    socketManager = RapidSocketManager(networkHandler: networkHanlder)
                    socketManager.authorize(authRequest: RapidAuthRequest(accessToken: self.testAuthToken))
                    socketManager.cacheHandler = self.rapid.handler
                    
                    let subscription = RapidCollectionSub(collectionID: self.testCollectionName, filter: nil, ordering: nil, paging: nil, callback: { (_, cachedDocuments) in
                        if cachedDocuments == documents {
                            promise.fulfill()
                        }
                        else {
                            XCTFail("Documents not equal")
                        }
                    }, callbackWithChanges: nil)
                    
                    socketManager.subscribe(subscription)
                }
            })
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

extension RapidTests {
    
    func randomString(withLength length: Int) -> String {
        
        var randomString = ""
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+[]{};'\\:\"|,./<>?`~§±"
        
        for _ in 0 ..< length {
            
            let randomIndex = Int(arc4random_uniform(UInt32(letters.characters.count)))
            let randomCharacter = Array(letters.characters)[randomIndex]
            randomString += String(randomCharacter)
        }

        return randomString
    }
}
//Yv<#|M@e,§16)d@60}"Ir|$p,6|>q1_Vb>v'PRw*l]%*Oh#
//F32o%'><$GZdTEPpH;s%:'d?3Ea^6Y;b~{QV>mOqO>0l1
