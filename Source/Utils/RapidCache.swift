//
//  RapidCache.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

class RapidCache: NSObject {
    
    fileprivate var cacheInfoURL: URL {
        return cacheDir.appendingPathComponent("0.dat")
    }
    
    fileprivate let fileManager: FileManager
    fileprivate let cacheDir: URL
    fileprivate let diskQueue: DispatchQueue
    
    fileprivate let maxSize: Int?
    fileprivate let timeToLive: TimeInterval?
    
    fileprivate var cacheInfo: [UInt64: [String: TimeInterval]]
    
    init?(apiKey: String, timeToLive: TimeInterval = 1209600, maxSize: Int? = 100) {
        guard let cacheURL = RapidCache.cacheURL(forAPIKey: apiKey) else {
            return nil
        }
        
        self.fileManager = FileManager()
        self.cacheDir = cacheURL
        
        self.maxSize = maxSize
        self.timeToLive = timeToLive
        
        var isDir: ObjCBool = false
        
        if fileManager.fileExists(atPath: cacheDir.absoluteString, isDirectory: &isDir) {
            if !isDir.boolValue {
                do {
                    try fileManager.removeItem(at: cacheURL)
                    try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    return nil
                }
            }
        }
        else {
            do {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                return nil
            }
        }
        
        if let data = try? Data(contentsOf: cacheDir.appendingPathComponent("0.dat")), let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UInt64: [String: TimeInterval]] {
            cacheInfo = info
        }
        else {
            cacheInfo = [:]
        }
        
        diskQueue = DispatchQueue(label: "io.rapid.cache.disk", qos: .background)
        
        super.init()
        
        diskQueue.async {
            self.pruneCache()
        }
    }
    
    func cache(forKey key: String, completion: @escaping (Any?) -> Void) {
        diskQueue.async {
            completion(self.cache(forKey: key))
        }
    }
    
    func save(cache: NSCoding, forKey key: String) {
        diskQueue.async {
            self.saveCache(cache, forKey: key)
        }
    }
    
    func clearCache() {
        diskQueue.async {
            do {
                self.cacheInfo.removeAll()
                
                try self.fileManager.removeItem(at: self.cacheDir)
            }
            catch {
                print("Cache wasn't cleared")
            }
        }
    }
    
    func clearCache(forKey key: String) {
        diskQueue.async {
            self.removeCache(forKey: key)
        }
    }
    
}

extension RapidCache {
    
    class func cacheURL(forAPIKey apiKey: String) -> URL? {
        let urlSafeAPIKey = apiKey.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
        
        guard let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        return URL(string: cachePath, relativeTo: URL(string: "file://"))?.appendingPathComponent("io.rapid.cache", isDirectory: true).appendingPathComponent(urlSafeAPIKey, isDirectory: true)
    }
    
    class func clearCache(forAPIKey apiKey: String) {
        guard let cacheURL = cacheURL(forAPIKey: apiKey) else {
            return
        }
        
        do {
            let manager = FileManager()
            
            try manager.removeItem(at: cacheURL)
        }
        catch { }
    }
}

fileprivate extension RapidCache {
    
    func size(ofDirectory directoryURL: URL) -> Int {
        
        var totalSize = 0
        
        let enumerator = fileManager.enumerator(at: cacheDir, includingPropertiesForKeys: [.isExcludedFromBackupKey], options: .skipsHiddenFiles) { _, _ -> Bool in
            return true
        }
        
        if let enumerator = enumerator {
            
            for fileURL in enumerator {
                
                if let fileURL = fileURL as? URL {
                    
                    do {
                        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                        let size = attributes[FileAttributeKey.size] as? Int ?? 0
                        totalSize += size
                    }
                    catch {
                        print("🔥 FILE MANAGER - error getting file size")
                    }
                    
                }
            }
        }
        
        return totalSize
    }
    
    func cache(forKey key: String) -> Any? {
        let hash = self.hash(forKey: key)

        if self.cacheInfo[hash]?[key] == nil {
            return nil
        }
        else {
            let fileDict = self.fileDictionary(forHash: hash)
            return fileDict[key]
        }
    }
    
    func fileDictionary(forHash hash: UInt64) -> [String: NSCoding] {
        let url = self.url(forHash: hash)
        
        do {
            let data = try Data(contentsOf: url)
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: NSCoding] ?? [:]
        }
        catch {
            return [:]
        }
    }
    
    func saveCache(_ cache: NSCoding, forKey key: String) {
        let hash = self.hash(forKey: key)
        
        var fileDict = fileDictionary(forHash: hash)
        fileDict[key] = cache
        
        if var dict = cacheInfo[hash] {
            dict[key] = Date().timeIntervalSince1970
        }
        else {
            cacheInfo[hash] = [key: Date().timeIntervalSince1970]
        }
        
        saveCacheInfo()
        saveCache(fileDict, forHash: hash)
    }
    
    func saveCache(_ cache: [String: NSCoding], forHash hash: UInt64) {
        do {
            let data = NSKeyedArchiver.archivedData(withRootObject: cache)
            
            try data.write(to: self.url(forHash: hash))
        }
        catch {}
    }
    
    func saveCacheInfo() {
        do {
            let data = NSKeyedArchiver.archivedData(withRootObject: cacheInfo)
            
            try data.write(to: cacheInfoURL)
        }
        catch {}
    }
    
    func removeCache(forKey key: String) {
        let hash = self.hash(forKey: key)
        
        self.cacheInfo[hash]?[key] = nil
        
        if (self.cacheInfo[hash]?.keys.count ?? 0) > 1 {
            var fileDict = self.fileDictionary(forHash: hash)
            
            fileDict[key] = nil
            
            self.saveCache(fileDict, forHash: hash)
        }
        else {
            self.removeCacheFile(forHash: hash)
        }
        
        self.saveCacheInfo()
    }
    
    func removeCacheFile(forHash hash: UInt64) {
        do {
            try fileManager.removeItem(at: url(forHash: hash))
        }
        catch {}
    }
    
    func url(forKey key: String) -> URL {
        return url(forHash: hash(forKey: key))
    }
    
    func url(forHash hash: UInt64) -> URL {
        return cacheDir.appendingPathComponent("\(hash).dat")
    }
    
    func hash(forKey key: String) -> UInt64 {
        if key.isEmpty {
            return 1
        }
        
        let metaString = key.lowercased().characters.frequencies.sorted(by: { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 < $1.1 })
        
        var hash: UInt64 = 0
        
        for (index, tuple) in metaString.enumerated() {
            hash += UInt64(index + 1) * UInt64(tuple.1) * UInt64(tuple.0.asciiValue ?? 0)
            
            if hash > UInt64(UInt32.max) {
                hash = hash % 2147483647
            }
        }
        
        return hash
    }
    
    func pruneCache() {
        pruneOutdatedFiles()
        pruneIfNecessary()
    }
    
    func pruneOutdatedFiles() {
        guard let ttl = timeToLive else {
            return
        }
        
        let referenceTimestamp = Date().timeIntervalSince1970 - ttl
        
        for (_, caches) in cacheInfo {
            for (key, timestamp) in caches where timestamp < referenceTimestamp {
                removeCache(forKey: key)
            }
        }
    }
    
    func pruneIfNecessary() {
        guard let maxSize = maxSize, (maxSize * 1024 * 1024) < self.size(ofDirectory: cacheDir) else {
            return
        }
        
        var sortedValues = cacheInfo
            .values
            .reduce([(String, TimeInterval)](), { temp, dict in
                let tuples = dict.map({ (key, value) in (key, value) })
                return temp + tuples
            })
            .sorted(by: { $0.1 < $1.1 })
        
        while size(ofDirectory: cacheDir) > (maxSize * 1024 * 1024) {
            for (key, _) in sortedValues.prefix(5) {
                removeCache(forKey: key)
            }
            
            sortedValues = Array(sortedValues.dropFirst(5))
        }
    }
}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter({$0.isASCII}).first?.value
    }
}

extension Collection where Iterator.Element: Hashable {
    var frequencies: [(Iterator.Element, Int)] {
        var seen: [Iterator.Element: Int] = [:]
        var frequencies: [(Iterator.Element, Int)] = []
        for element in self {
            if let idx = seen[element] {
                frequencies[idx].1 += 1
            }
            else {
                seen[element] = frequencies.count
                frequencies.append((element, 1))
            }
        }
        return frequencies
    }
}
