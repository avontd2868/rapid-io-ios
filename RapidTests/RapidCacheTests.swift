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
        #if os(OSX)
            let plistURL = Bundle(for: RapidTests.self).bundleURL.appendingPathComponent("Contents", isDirectory: true).appendingPathComponent("Info.plist")
            XCTAssertGreaterThan(plistURL.memorySize ?? 0, 0, "Zero size")
        #elseif os(iOS)
            let plistURL = Bundle(for: RapidTests.self).url(forResource: "Info", withExtension: "plist")
            XCTAssertGreaterThan(plistURL?.memorySize ?? 0, 0, "Zero size")
        #elseif os(tvOS)
            let plistURL = Bundle(for: RapidTests.self).url(forResource: "Info", withExtension: "plist")
            XCTAssertGreaterThan(plistURL?.memorySize ?? 0, 0, "Zero size")
        #endif
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
        let cacheURL = RapidCache.cacheURL(forApiKey: apiKey)!
        
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
        let cacheURL = RapidCache.cacheURL(forApiKey: apiKey)!
        
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
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey")
        
        cache?.loadDataset(forKey: "testKey", completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "testString") && arr.count == 1 {
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
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey")
        cache?.save(dataset: ["testtest" as NSString], forKey: "testKey")
        
        cache?.loadDataset(forKey: "testKey", completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "testtest") && arr.count == 1 {
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
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey")
        cache?.save(dataset: ["testString2" as NSString], forKey: "testKey2")
        
        cache?.hasData(forKey: "testKey", completion: { (has) in
            XCTAssertTrue(has, "No cache")
        })
        
        cache?.hasData(forKey: "testKey2", completion: { (has) in
            XCTAssertTrue(has, "No cache")
        })
        
        cache?.clearCache(forKey: "testKey")
        
        cache?.hasData(forKey: "testKey", completion: { (has) in
            XCTAssertFalse(has, "No cache")
            
            cache?.clearCache()
            
            cache?.hasData(forKey: "testKey2", completion: { (has) in
                XCTAssertFalse(has, "No cache")
                
                promise.fulfill()
            })
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testClearCache() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey")
        cache?.save(dataset: ["testString2" as NSString], forKey: "testKey2")
        
        cache?.clearCache(forKey: "testKey")
        
        cache?.loadDataset(forKey: "testKey", completion: { (value) in
            if value != nil {
                XCTFail("Cache not cleared")
            }
            else {
                cache?.clearCache()
                
                cache?.loadDataset(forKey: "testString2", completion: { (value) in
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
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey")
        cache?.save(dataset: ["testString2" as NSString], forKey: "testKey2")
        
        RapidCache.clearCache(forApiKey: apiKey)
        
        cache?.loadDataset(forKey: "testKey", completion: { (value) in
            if value != nil {
                XCTFail("Cache not cleared")
            }
            else {
                cache?.loadDataset(forKey: "testString2", completion: { (value) in
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
        
        var hashes = Set<String>()
        var numberOfColisions = 0
        
        for string in strings {
            guard let hash = cache?.hash(forKey: string) else {
                continue
            }
            
            XCTAssertNotEqual(hash, "0")
            
            if !hashes.contains(hash) {
                hashes.insert(hash)
            }
            else {
                numberOfColisions += 1
            }
        }
        
        XCTAssertLessThan(numberOfColisions, numberOfTests / 20)
    }
    
    func testHashFunctionForUnique() {
        let cache = RapidCache(apiKey: apiKey)
        
        let numberOfTests = 10000
        let maxLength = 100
        
        var strings = Set<String>()
        
        for _ in 0 ..< numberOfTests {
            let length = Int(arc4random_uniform(UInt32(maxLength))) + 1
            
            strings.insert(randomIDString(withLength: length))
        }
        
        var hashes = Set<String>()
        
        for string in strings {
            guard let hash = cache?.hash(forKey: string, unique: true) else {
                continue
            }
            
            XCTAssertNotEqual(hash, "0")
            
            if !hashes.contains(hash) {
                hashes.insert(hash)
            }
            else {
                XCTFail("Not unique")
                break
            }
        }
        
        XCTAssertEqual(hashes.count, strings.count)
    }
    
    func testCollidingKeys() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        let key1 = "`]cCyVAlN^]h>x,>&nE_iE,0x;\"[jF1j0Biu0*ew3D/dl^V1}J~S]X]\\wrxr/6Y./N8}*0Yrw$K]37n%3H^Vscg50hary>"
        let key2 = ".de:3uKF:L5{Y;§gq@g,J\"KWp}h~>GN{(+^M$?_k#@ZcwMkMz|Uv2,90±TaQID9'aE6]S~_EL6VvknU<~+0^"
        
        XCTAssertEqual(cache?.hash(forKey: key1), cache?.hash(forKey: key2))
        
        cache?.save(dataset: ["test1" as NSString], forKey: key1)
        cache?.save(dataset: ["test2" as NSString], forKey: key2)
        
        cache?.loadDataset(forKey: key1, completion: { (value) in
            guard let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "test1") && arr.count == 1 else {
                XCTFail("Cache not loaded")
                return
            }
        })
        
        cache?.loadDataset(forKey: key2, completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "test2") && arr.count == 1 {
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
        
        cache?.save(dataset: ["test1" as NSString], forKey: key1)
        cache?.save(dataset: ["test2" as NSString], forKey: key2)
        
        cache?.clearCache(forKey: key1)
        
        cache?.loadDataset(forKey: key2, completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "test2") && arr.count == 1 {
                promise.fulfill()
            }
            else{
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRemoveJustSoftLinkWhenRCNot0() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        let key1 = "`]cCyVAlN^]h>x,>&nE_iE,0x;\"[jF1j0Biu0*ew3D/dl^V1}J~S]X]\\wrxr/6Y./N8}*0Yrw$K]37n%3H^Vscg50hary>"
        let key2 = ".de:3uKF:L5{Y;§gq@g,J\"KWp}h~>GN{(+^M$?_k#@ZcwMkMz|Uv2,90±TaQID9'aE6]S~_EL6VvknU<~+0^"
        
        let testData = "test1" as NSString
        
        XCTAssertEqual(cache?.hash(forKey: key1), cache?.hash(forKey: key2))
        
        cache?.save(dataset: [testData], forKey: key1)
        cache?.save(dataset: [testData], forKey: key2)
        
        cache?.clearCache(forKey: key1)
        
        cache?.loadDataset(forKey: key2, completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "test1") && arr.count == 1 {
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
        
        cache?.save(dataset: ["test1" as NSString], forKey: "testKey")
        
        runAfter(1.5) {
            cache = RapidCache(apiKey: self.apiKey, timeToLive: 1)
            
            cache?.loadDataset(forKey: "testKey", completion: { (value) in
                if value == nil {
                    cache?.save(dataset: ["test1" as NSString], forKey: "testKey")
                    
                    cache?.loadDataset(forKey: "testKey", completion: { (value) in
                        if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "test1") && arr.count == 1 {
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
        
        cache?.save(dataset: ["test1" as NSString], forKey: "testKey")
        cache?.save(dataset: ["test2" as NSString], forKey: "testKey2")
        
        runAfter(1.5) {
            cache = RapidCache(apiKey: self.apiKey, maxSize: 0.000000000000001)
            
            cache?.loadDataset(forKey: "testKey", completion: { (value) in
                if value == nil {
                    cache?.save(dataset: ["test1" as NSString], forKey: "testKey")
                    
                    cache?.loadDataset(forKey: "testKey", completion: { (value) in
                        if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "test1") && arr.count == 1 {
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
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey", secret: secret)
        
        cache?.loadDataset(forKey: "testKey", secret: secret, completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "testString") && arr.count == 1 {
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
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey", secret: Rapid.uniqueID)
        
        cache?.loadDataset(forKey: "testKey", secret: Rapid.uniqueID, completion: { (value) in
            if value == nil || value?.count == 0 {
                promise.fulfill()
            }
            else{
                XCTFail("Did access cache")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testLoadAndRemoveCachedObject() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        let testString = "testString" as NSString
        
        cache?.save(dataset: [testString], forKey: "testKey")
        
        cache?.loadObject(withGroupID: testString.groupID, objectID: testString.objectID, completion: { (object) in
            if let string = object as? NSString, string.isEqual("testString") {
                cache?.removeObject(withGroupID: testString.groupID, objectID: testString.objectID)
                cache?.loadObject(withGroupID: testString.groupID, objectID: testString.objectID, completion: { (object) in
                    if object == nil {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Cache not removed")
                    }
                })
            }
            else {
                XCTFail("Cache not loaded")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testUpdateCacheWithEmptyArray() {
        let promise = expectation(description: "Load cache")
        
        let cache = RapidCache(apiKey: apiKey)
        
        cache?.save(dataset: ["testString" as NSString], forKey: "testKey")
        
        cache?.loadDataset(forKey: "testKey", completion: { (value) in
            if let arr = value as? [NSString], let value = arr.first, value.isEqual(to: "testString") && arr.count == 1 {
                cache?.save(dataset: [], forKey: "testKey")
                
                cache?.loadDataset(forKey: "testKey", completion: { (value) in
                    if let arr = value, arr.count == 0 {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Cache not updated")
                    }
                })
            }
            else{
                XCTFail("No cache")
            }
        })
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testLoadingSubscriptionFromCache() {
        let promise = expectation(description: "Load cached data")

        rapid.isCacheEnabled = false
        rapid.isCacheEnabled = true
        
        XCTAssertEqual(rapid.isCacheEnabled, true)
        
        var socketManager: RapidSocketManager!
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "testLoadingSubscriptionFromCache"]) { _ in
            
            var initialValue = true
            self.rapid.collection(named: self.testCollectionName).subscribe(block: { result in
                guard case .success(let docs) = result else {
                    XCTFail("Error")
                    return
                }
                
                XCTAssertGreaterThan(docs.count, 0, "No documents")
                
                if initialValue {
                    initialValue = false
                    let documents = docs
                    let networkHanlder = RapidNetworkHandler(socketURL: self.fakeSocketURL)
                    socketManager = RapidSocketManager(networkHandler: networkHanlder)
                    socketManager.authorize(authRequest: RapidAuthRequest(token: self.testAuthToken))
                    socketManager.cacheHandler = self.rapid.handler
                    
                    self.rapid.collection(named: self.testCollectionName).document(withID: "1").merge(value: ["desc": "Description"], completion: { _ in
                        runAfter(1, closure: {
                            let subscription = RapidCollectionSub(collectionID: self.testCollectionName, filter: nil, ordering: nil, paging: nil, handler: { result in
                                guard case .success(let cachedDocuments) = result else {
                                    XCTFail("Error")
                                    return
                                }
                                
                                if cachedDocuments == documents {
                                    XCTFail("Cache not updated")
                                }
                                else {
                                    for document in documents {
                                        if let index = cachedDocuments.index(where: { $0.id == document.id }) {
                                            let cached = cachedDocuments[index]
                                            if cached.id == "1" {
                                                XCTAssertEqual(cached.value?["name"] as? String, document.value?["name"] as? String, "Merge failed")
                                                XCTAssertEqual(cached.value?["desc"] as? String, "Description", "Cache not updated")
                                            }
                                            else {
                                                XCTAssertTrue(cached == document, "Documents not equal")
                                            }
                                        }
                                        else {
                                            XCTFail("Missing document")
                                        }
                                    }
                                    
                                    promise.fulfill()
                                }
                            }, handlerWithChanges: nil)
                            
                            socketManager.subscribe(toCollection: subscription)
                        })
                    })
                }
            })
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRemovingCachedValuesOnFailure() {
        let promise = expectation(description: "Load cached data")
        
        rapid.isCacheEnabled = false
        rapid.isCacheEnabled = true
        
        XCTAssertEqual(rapid.isCacheEnabled, true)
        
        rapid.collection(named: testCollectionName).document(withID: "1").mutate(value: ["name": "testLoadingSubscriptionFromCache"]) { _ in
            
            var initialValue = true
            var hash = ""
            let sub = self.rapid.collection(named: self.testCollectionName).subscribe(block: { result in
                if initialValue {
                    initialValue = false
                    
                    guard case .success(let docs) = result else {
                        XCTFail("Error")
                        return
                    }
                    
                    XCTAssertGreaterThan(docs.count, 0, "No documents")
                    
                    self.rapid.deauthorize()
                }
                else {
                    self.rapid.handler.cache?.loadDataset(forKey: hash, secret: self.testAuthToken, completion: { objects in
                        XCTAssertNotNil(objects, "No objects")
                        XCTAssertEqual(objects?.count ?? -1, 0, "Wrong count of objects")
                        
                        promise.fulfill()
                    })
                }
            })
            
            hash = sub.subscriptionHash
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
    
    func randomIDString(withLength length: Int) -> String {
        
        var randomString = ""
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
        
        for _ in 0 ..< length {
            
            let randomIndex = Int(arc4random_uniform(UInt32(letters.characters.count)))
            let randomCharacter = Array(letters.characters)[randomIndex]
            randomString += String(randomCharacter)
        }
        
        return randomString
    }
    
}

extension NSString: RapidCachableObject {
    public var groupID: String {
        return self as String
    }
    
    public var objectID: String {
        return self as String
    }
}
