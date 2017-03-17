//
//  RapidSocketParser.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidSerialization {
    
    class func parse(json: [AnyHashable: Any]?) -> [RapidResponse]? {
        guard let json = json else {
            return nil
        }
        
        if let batch = json[Batch.name] as? [[AnyHashable: Any]] {
            return batch.flatMap({ parseEvent(json: $0) })
        }
        else if let event = parseEvent(json: json) {
            return [event]
        }
        else {
            return nil
        }
    }
    
    class func serialize(mutation: RapidDocumentMutation, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        var doc = [AnyHashable: Any]()
        doc[Mutation.Document.DocumentID.name] = mutation.documentID
        doc[Mutation.Document.Body.name] = mutation.value
        
        json[Mutation.CollectionID.name] = mutation.collectionID
        json[Mutation.Document.name] = doc
        
        let resultDict: [AnyHashable: Any] = [Mutation.name: json]
        let data = try JSONSerialization.data(withJSONObject: resultDict, options: [])
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    class func serialize(subscription: RapidCollectionSub, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        json[Subscription.CollectionID.name] = subscription.collectionID
        json[Subscription.Filter.name] = serialize(filter: subscription.filter)
        json[Subscription.Ordering.name] = serialize(ordering: subscription.ordering)
        //TODO: Serialize paging
        
        let resultDict: [AnyHashable: Any] = [Subscription.name: json]
        let data = try JSONSerialization.data(withJSONObject: resultDict, options: [])
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    class func serialize(filter: RapidFilter?) -> [[AnyHashable: Any]]? {
        //TODO: Serialize filter
        return nil
    }
    
    class func serialize(ordering: [RapidOrdering]?) -> [[AnyHashable: Any]]? {
        //TODO: Serialize ordering
        return nil
    }
}

fileprivate extension RapidSerialization {
    
    fileprivate class func parseEvent(json: [AnyHashable: Any]) -> RapidResponse? {
        if let ack = json[Acknowledgement.name] as? [AnyHashable: Any] {
            return RapidSocketAcknowledgement(json: ack)
        }
        else if let err = json[Error.name] as? [AnyHashable: Any] {
            return RapidSocketError(json: err)
        }
        else if let val = json[SubscriptionValue.name] as? [AnyHashable: Any] {
            return RapidSubscriptionInitialValue(json: val)
        }
        else {
            return nil
        }
    }
}

//swiftlint:disable nesting
extension RapidSerialization {
    
    struct Batch {
        static let name = "batch"
    }
    
    struct Acknowledgement {
        static let name = "ack"
        
        struct EventID {
            static let name = "evt-id"
        }
    }
    
    struct Error {
        static let name = "err"
        
        struct EventID {
            static let name = "evt-id"
        }
        
        struct ErrorType {
            static let name = "err-type"
        }
        
        struct ErrorMessage {
            static let name = "err-message"
        }
    }
    
    struct Mutation {
        static let name = "mut"
        
        struct EventID {
            static let name = "evt-id"
        }
        
        struct CollectionID {
            static let name = "col-id"
        }
        
        struct Document {
            static let name = "doc"
            
            struct DocumentID {
                static let name = "id"
            }
            
            struct Body {
                static let name = "body"
            }
        }
    }
    
    struct Subscription {
        static let name = "sub"
        
        struct EventID {
            static let name = "evt-id"
        }
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
        
        struct CollectionID {
            static let name = "col-id"
        }
        
        struct Filter {
            static let name = "filter"
        }
        
        struct Ordering {
            static let name = "order"
        }
    }
    
    struct SubscriptionValue {
        static let name = "val"
        
        struct EventID {
            static let name = "evt-id"
        }
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
        
        struct CollectionID {
            static let name = "col-id"
        }
        
        struct Documents {
            static let name = "docs"
        }
    }
    
    struct SubscriptionUpdate {
        static let name = "upd"
    }
}
