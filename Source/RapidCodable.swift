//
//  RapidCodable.swift
//  Rapid
//
//  Created by Jan on 04/10/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public class RapidJSONDecoder: JSONDecoder {

    public struct RapidDocumentDecodingKeys {
        public var documentIdKey = "$documentId"
        public var collectionNameKey = "$collectionName"
        public var createdAtKey = "$createdAt"
        public var modifiedAtKey = "$modifiedAt"
        public var etagKey = "$etag"
    }

    public var rapidDocumentDecodingKeys = RapidDocumentDecodingKeys()
}

public class RapidJSONEncoder: JSONEncoder {
    
    public var rapidDocumentStripoffKeys: [String] = []
}
