//
//  RapidCache.swift
//  Rapid
//
//  Created by Jan Schwarz on 16/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

/// Class for handling data cache
class RapidCache: NSObject {
    
    /// URL of a file with info about cached data
    fileprivate var cacheInfoURL: URL {
        return cacheDir.appendingPathComponent("0.dat")
    }
    
    /// Shared file manager
    fileprivate let fileManager: FileManager
    
    /// URL of a directory with cached data
    fileprivate let cacheDir: URL
    
    /// Dedicated queue for I/O operations
    fileprivate let diskQueue: DispatchQueue
    
    /// Maximum size of a cache directory
    ///
    /// Default value is 100 MB
    fileprivate let maxSize: Float?
    
    /// Maximum Time To Live of a single piece of data
    ///
    /// Default value is nil e.i. no expiration
    fileprivate let timeToLive: TimeInterval?
    
    /// Dictionary with info about cached data
    ///
    /// It stores modification time for every piece of data
    fileprivate var cacheInfo: [UInt64: [String: TimeInterval]]
    
    /// Initialize `RapidCache`
    ///
    /// - Parameters:
    ///   - apiKey: API key of Rapid database
    ///   - timeToLive: Maximum Time To Live of a single piece of data in seconds. Default value is nil e.i. no expiration
    ///   - maxSize: Maximum size of a cache directory in MB. Default value is 100 MB
    init?(apiKey: String, timeToLive: TimeInterval? = nil, maxSize: Float? = 100) {
        guard !apiKey.isEmpty, let cacheURL = RapidCache.cacheURL(forAPIKey: apiKey) else {
            return nil
        }
        
        guard (timeToLive ?? 1) > 0 && (maxSize ?? 1) > 0 else {
            return nil
        }
        
        self.fileManager = FileManager()
        self.cacheDir = cacheURL
        
        self.maxSize = maxSize
        self.timeToLive = timeToLive
        
        var isDir: ObjCBool = false
        
        // If the URL exists but it is a file replace the file with a directory
        // Otherwise create a directory at the URL
        if fileManager.fileExists(atPath: cacheDir.path, isDirectory: &isDir) {
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
        
        // Load info about cached data
        if let data = try? Data(contentsOf: cacheDir.appendingPathComponent("0.dat")), let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UInt64: [String: TimeInterval]] {
            cacheInfo = info
        }
        else {
            cacheInfo = [:]
        }
        
        diskQueue = DispatchQueue(label: "io.rapid.cache.disk", qos: .utility)
        
        super.init()
        
        // Prune cached data
        diskQueue.async {
            self.pruneCache()
        }
    }
    
    /// Compute hash for a key
    ///
    /// - Parameter key: Cache key
    /// - Returns: Hash for the key
    func hash(forKey key: String) -> UInt64 {
        if key.isEmpty {
            return 1
        }
        
        // Get list of characters, compute their frequencies and sort characters according to their frequencies
        let metaString = key.lowercased().characters.frequencies.sorted(by: { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 < $1.1 })
        
        var hash: UInt64 = 0
        
        for (index, tuple) in metaString.enumerated() {
            hash += (UInt64(index + 1) * 101) * UInt64(tuple.1) * UInt64(tuple.0.asciiValue ?? 0)
            
            if hash > UInt64(UInt32.max) {
                hash = hash % 2147483647
            }
        }
        
        return max(hash, 1)
    }
    
    /// Find out if there are cached data for a given key
    ///
    /// - Parameters:
    ///   - key: Cache key
    ///   - completion: Completion handler. Boolean parameter is `true` if any data are cached for the key
    func hasCache(forKey key: String, completion: @escaping (Bool) -> Void) {
        diskQueue.async {
            let hash = self.hash(forKey: key)
            completion(self.cacheInfo[hash]?[key] != nil)
        }
    }
    
    /// Get cached data for a given key
    ///
    /// - Parameters:
    ///   - key: Cache key
    ///   - completion: Completion handler. If there are any cached data for the key they are passed in the completion handler parameter.
    func cache(forKey key: String, completion: @escaping (Any?) -> Void) {
        diskQueue.async {
            completion(self.cache(forKey: key))
        }
    }
    
    /// Store data with a given key to the cache
    ///
    /// - Parameters:
    ///   - data: Data to be cached
    ///   - key: Cache key
    func save(data: NSCoding, forKey key: String) {
        diskQueue.async {
            self.saveCache(data, forKey: key)
        }
    }
    
    /// Remove all data from the cache
    func clearCache() {
        diskQueue.async {
            self.removeCache()
        }
    }
    
    /// Remove cached data for a given key
    ///
    /// - Parameter key: Cache key
    func clearCache(forKey key: String) {
        diskQueue.async {
            self.removeCache(forKey: key)
        }
    }
    
}

// MARK: Class methods
extension RapidCache {
    
    /// Get an URL to a cache directory for a given API key
    ///
    /// - Parameter apiKey: API key of a Rapid database
    /// - Returns: URL to a cache directory
    class func cacheURL(forAPIKey apiKey: String) -> URL? {
        let urlSafeAPIKey = apiKey.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
        
        guard let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        return URL(string: cachePath, relativeTo: URL(string: "file://"))?.appendingPathComponent("io.rapid.cache", isDirectory: true).appendingPathComponent(urlSafeAPIKey, isDirectory: true)
    }
    
    /// Remove all data from a cache with a given API key
    ///
    /// - Parameter apiKey: API key of a Rapid database
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

// MARK: Private methods
fileprivate extension RapidCache {
    
    /// Get cached data for a given key
    ///
    /// - Parameter key: Cache key
    /// - Returns: Cached data if there are any
    func cache(forKey key: String) -> Any? {
        let hash = self.hash(forKey: key)

        if self.cacheInfo[hash]?[key] == nil {
            return nil
        }

        let fileDict = self.fileDictionary(forHash: hash)
        return fileDict[key]
    }
    
    /// Get cached data for all keys with a same hash value
    ///
    /// - Parameter hash: Hash value of a cache key
    /// - Returns: Dictionary of cached pieces of data
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
    
    /// Store data with a given key to the cache
    ///
    /// - Parameters:
    ///   - cache: Data to be stored
    ///   - key: Cache key
    func saveCache(_ cache: NSCoding, forKey key: String) {
        let hash = self.hash(forKey: key)
        
        // Add data to the cache
        var fileDict = fileDictionary(forHash: hash)
        fileDict[key] = cache
        
        // Put down a timestamp of data modification
        if var dict = cacheInfo[hash] {
            dict[key] = Date().timeIntervalSince1970
            cacheInfo[hash] = dict
        }
        else {
            cacheInfo[hash] = [key: Date().timeIntervalSince1970]
        }
        
        saveCacheInfo()
        saveCache(fileDict, forHash: hash)
    }
    
    /// Write cache file to a disk
    ///
    /// - Parameters:
    ///   - cache: Dictionary of cached pieces of data
    ///   - hash: Hash value of keys associated with data in this cache file
    func saveCache(_ cache: [String: NSCoding], forHash hash: UInt64) {
        do {
            let data = NSKeyedArchiver.archivedData(withRootObject: cache)
            
            try data.write(to: self.url(forHash: hash))
        }
        catch {}
    }
    
    /// Write info about cached data to a disk
    func saveCacheInfo() {
        do {
            let data = NSKeyedArchiver.archivedData(withRootObject: cacheInfo)
            
            try data.write(to: cacheInfoURL)
        }
        catch {}
    }
    
    /// Remove cache directore from a disk
    func removeCache() {
        do {
            self.cacheInfo.removeAll()
            
            try self.fileManager.removeItem(at: self.cacheDir)
        }
        catch {
            print("Cache wasn't cleared")
        }
    }
    
    /// Remove cached data for a given key
    ///
    /// - Parameter key: Cache key
    func removeCache(forKey key: String) {
        let hash = self.hash(forKey: key)
        
        self.cacheInfo[hash]?[key] = nil
        
        // If there are still any data stored under the same hash value save the updated file
        // Otherwise remove the cache file
        if (self.cacheInfo[hash]?.keys.count ?? 0) > 0 {
            var fileDict = self.fileDictionary(forHash: hash)
            
            fileDict[key] = nil
            
            self.saveCache(fileDict, forHash: hash)
        }
        else {
            self.removeCacheFile(forHash: hash)
        }
        
        self.saveCacheInfo()
    }
    
    /// Remove cache file from a disk
    ///
    /// - Parameter hash: Hash value associated with data stored in a file
    func removeCacheFile(forHash hash: UInt64) {
        do {
            try fileManager.removeItem(at: url(forHash: hash))
        }
        catch {}
    }
    
    /// Get URL to a file containing data that are stored under a given hash value
    ///
    /// - Parameter hash: Hash value
    /// - Returns: URL to a file
    func url(forHash hash: UInt64) -> URL {
        return cacheDir.appendingPathComponent("\(hash).dat")
    }
    
    /// Prune outdated or oversized cached data
    func pruneCache() {
        pruneOutdatedFiles()
        pruneIfNecessary()
    }
    
    /// Prune outdated cached data
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
    
    /// Prune the oldest cached data if the cache directory is too large
    func pruneIfNecessary() {
        guard let maxSize = maxSize, Int(maxSize * 1024 * 1024) < (cacheDir.memorySize ?? 0) else {
            return
        }
        
        // Sort cached data according to their time of modification
        var sortedValues = cacheInfo
            .values
            .reduce([(String, TimeInterval)](), { temp, dict in
                let tuples = dict.map({ (key, value) in (key, value) })
                return temp + tuples
            })
            .sorted(by: { $0.1 < $1.1 })
        
        while (cacheDir.memorySize ?? 0) > Int((maxSize/2) * 1024 * 1024) && sortedValues.count > 0 {
            for (key, _) in sortedValues.prefix(5) {
                removeCache(forKey: key)
            }
            
            sortedValues = Array(sortedValues.dropFirst(5))
        }
    }
}
