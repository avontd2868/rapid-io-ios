//
//  RapidCodable.swift
//  Rapid
//
//  Created by Jan on 04/10/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation

/// Subclass of `JSONDecoder`
public class RapidJSONDecoder: JSONDecoder {

    /// Structure that specifies names of keys
    ///
    /// When using direct decoding from JSONs to objects in subscriptions and fetches
    /// JSON received from a database is, for sake of decoding, enriched with attributes
    /// that contain document ID, collection name, timestamp of creation, timestamp of modification and etag.
    /// These attributes are added into a JSON under keys specified by an instance of this structure
    public struct RapidDocumentDecodingKeys {
        /// Key for document ID
        public var documentIdKey = "$documentId"
        /// Key for collection name
        public var collectionNameKey = "$collectionName"
        /// Key for timestamp of document creation
        public var createdAtKey = "$createdAt"
        /// Key for timestamp of document modification
        public var modifiedAtKey = "$modifiedAt"
        /// Key for document etag
        public var etagKey = "$etag"
    }

    /// Instance of `RapidDocumentDecodingKeys` that specifies names of keys
    /// under which document metadata should be added into a decoding JSON.
    ///
    /// See documentation of `RapidDocumentDecodingKeys`
    public var rapidDocumentDecodingKeys = RapidDocumentDecodingKeys()
}

/// Subclass of `JSONEncoder`
public class RapidJSONEncoder: JSONEncoder {
    
    /// Names of object properties that should not be taken into account during encoding
    /// when using mutations and merges with encodable objects
    public var rapidDocumentStripoffKeys: [String] = []
}
