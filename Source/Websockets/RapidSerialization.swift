//
//  RapidSocketParser.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidSerialization {
    
    /// Parse JSON received through websocket
    ///
    /// - Parameter json: Received JSON
    /// - Returns: Array of deserialized objects
    class func parse(json: [AnyHashable: Any]?) -> [RapidResponse]? {
        guard let json = json else {
            return nil
        }
        
        // If websocket received a batch of events
        if let batch = json[Batch.name] as? [[AnyHashable: Any]] {
            var events = [RapidResponse]()
            var updates = [String: RapidSubscriptionEvent]()
            
            for json in batch {
                let event = parseEvent(json: json)
                
                // If the event is a subscription update treat it specially, otherwise just append it to the response array
                if let update = event as? RapidSubscriptionEvent {
                    
                    // If there was any update for the subscription combine it to one update
                    if var existingUpdate = updates[update.subscriptionID] {
                        existingUpdate.merge(withUpdate: update)
                        updates[existingUpdate.subscriptionID] = existingUpdate
                    }
                    else {
                        updates[update.subscriptionID] = update
                        events.append(update)
                    }
                    
                }
                else if let event = event {
                    events.append(event)
                }
            }
            
            return events
        }
        else if let event = parseEvent(json: json) {
            return [event]
        }
        else {
            return nil
        }
    }
    
    /// Serialize a document mutation into JSON string
    ///
    /// - Parameters:
    ///   - mutation: Mutation object
    ///   - identifiers: Identifiers that are associated with the mutation event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(mutation: RapidDocumentMutation, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        var doc = [AnyHashable: Any]()
        doc[Mutation.Document.DocumentID.name] = mutation.documentID
        doc[Mutation.Document.Body.name] = mutation.value
        
        json[Mutation.CollectionID.name] = mutation.collectionID
        json[Mutation.Document.name] = doc
        
        let resultDict: [AnyHashable: Any] = [Mutation.name: json]
        return try resultDict.jsonString()
    }
    
    /// Serialize a document merge into JSON string
    ///
    /// - Parameters:
    ///   - merge: Merge object
    ///   - identifiers: Identifiers that are associated with the merge event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(merge: RapidDocumentMerge, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        var doc = [AnyHashable: Any]()
        doc[Merge.Document.DocumentID.name] = merge.documentID
        doc[Merge.Document.Body.name] = merge.value
        
        json[Merge.CollectionID.name] = merge.collectionID
        json[Merge.Document.name] = doc
        
        let resultDict: [AnyHashable: Any] = [Merge.name: json]
        return try resultDict.jsonString()
    }
    
    /// Serialize a collection subscription into JSON string
    ///
    /// - Parameters:
    ///   - subscription: Subscription object
    ///   - identifiers: Identifiers that are associated with the subscription event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(subscription: RapidCollectionSub, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        json[Subscription.CollectionID.name] = subscription.collectionID
        json[Subscription.Filter.name] = serialize(filter: subscription.filter)
        json[Subscription.Ordering.name] = serialize(ordering: subscription.ordering)
        json[Subscription.Limit.name] = subscription.paging?.take
        json[Subscription.Skip.name] = subscription.paging?.skip
        
        let resultDict: [AnyHashable: Any] = [Subscription.name: json]
        return try resultDict.jsonString()
    }
    
    /// Serialize a subscription filter into JSON
    ///
    /// - Parameter filter: Filter object
    /// - Returns: JSON dictionary
    class func serialize(filter: RapidFilter?) -> [AnyHashable: Any]? {
        if let filter = filter as? RapidFilterSimple {
            return serialize(simpleFilter: filter)
        }
        else if let filter = filter as? RapidFilterCompound {
            return serialize(compoundFilter: filter)
        }
        else {
            return nil
        }
    }
    
    /// Serialize a simple subscription filter into JSON
    ///
    /// - Parameter simpleFilter: Simple filter object
    /// - Returns: JSON dictionary
    class func serialize(simpleFilter: RapidFilterSimple) -> [AnyHashable: Any] {
        switch simpleFilter.relation {
        case .equal:
            return [simpleFilter.key: simpleFilter.value ?? NSNull()]
            
        case .greaterThanOrEqual:
            return [simpleFilter.key: ["gte": simpleFilter.value]]
            
        case .lessThanOrEqual:
            return [simpleFilter.key: ["lte": simpleFilter.value]]
        }
    }
    
    /// Serialize a compound subscription filter into JSON
    ///
    /// - Parameter compoundFilter: Compound filter object
    /// - Returns: JSON dictionary
    class func serialize(compoundFilter: RapidFilterCompound) -> [AnyHashable: Any] {
        switch compoundFilter.compoundOperator {
        case .and:
            return ["and": compoundFilter.operands.map({serialize(filter: $0)})]
            
        case .or:
            return ["or": compoundFilter.operands.map({serialize(filter: $0)})]
            
        case .not:
            if let filter = compoundFilter.operands.first, let serializedFilter = serialize(filter: filter) {
                return ["not": serializedFilter]
            }
            else {
                return [:]
            }
        }
    }
    
    /// Serialize an array of subscription orderings into JSON
    ///
    /// - Parameter ordering: Array of ordering objects
    /// - Returns: JSON dictionary
    class func serialize(ordering: [RapidOrdering]?) -> [[AnyHashable: Any]]? {
        if let ordering = ordering {
            let orderingArray = ordering.map({ order -> [AnyHashable: Any] in
                switch order.ordering {
                case .ascending:
                    return [order.key: "asc"]
                    
                case .descending:
                    return [order.key: "desc"]

                }
            })
            
            return orderingArray
        }
        else {
            return nil
        }
    }
    
    /// Serialize an unsubscription request into JSON string
    ///
    /// - Parameters:
    ///   - unsubscription: Unsubscription object
    ///   - identifiers: Identifiers that are associated with the unsubscription event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(unsubscription: RapidUnsubscriptionHandler, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        json[Unsubscribe.SubscriptionID.name] = unsubscription.subscription.subscriptionID
        
        let resultDict: [AnyHashable: Any] = [Unsubscribe.name: json]
        return try resultDict.jsonString()
    }
    
    /// Serialize an event acknowledgement into JSON string
    ///
    /// - Parameters:
    ///   - acknowledgement: Acknowledgement object
    ///   - identifiers: Identifiers that are associated with the acknowledgement event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(acknowledgement: RapidSocketAcknowledgement, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        let resultDict = [Acknowledgement.name: identifiers]
        return try resultDict.jsonString()
    }
    
    /// Serialize an connection request into JSON string
    ///
    /// - Parameters:
    ///   - connection: Connection request object
    ///   - identifiers: Identifiers that are associated with the connection request event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(connection: RapidConnectionRequest, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        var json = identifiers
        
        json[Connect.ConnectionID.name] = connection.connectionID
        
        let resultDict = [Connect.name: json]
        return try resultDict.jsonString()
    }
    
    /// Serialize an disconnection request into JSON string
    ///
    /// - Parameters:
    ///   - disconnection: Disconnection request object
    ///   - identifiers: Identifiers that are associated with the disconnection request event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(disconnection: RapidDisconnectionRequest, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        let resultDict = [Disconnect.name: identifiers]
        return try resultDict.jsonString()
    }
    
    /// Serialize an hearbeat into JSON string
    ///
    /// - Parameters:
    ///   - heartbeat: Heartbeat object
    ///   - identifiers: Identifiers that are associated with the heartbeat event
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` errors
    class func serialize(heartbeat: RapidHeartbeat, withIdentifiers identifiers: [AnyHashable: Any]) throws -> String {
        let resultDict = [Heartbeat.name: identifiers]
        return try resultDict.jsonString()
    }
}

// MARK: Fileprivate methods
fileprivate extension RapidSerialization {
    
    /// Parse single event received from websocket
    ///
    /// - Parameter json: Event JSON
    /// - Returns: Deserialized object
    class func parseEvent(json: [AnyHashable: Any]) -> RapidResponse? {
        if let ack = json[Acknowledgement.name] as? [AnyHashable: Any] {
            return RapidSocketAcknowledgement(json: ack)
        }
        else if let err = json[Error.name] as? [AnyHashable: Any] {
            return RapidErrorInstance(json: err)
        }
        else if let val = json[SubscriptionValue.name] as? [AnyHashable: Any] {
            return RapidSubscriptionInitialValue(json: val)
        }
        else if let upd = json[SubscriptionUpdate.name] as? [AnyHashable: Any] {
            return RapidSubscriptionUpdate(json: upd)
        }
        else {
            return nil
        }
    }
    
}

// MARK: Name constants

//swiftlint:disable nesting
extension RapidSerialization {
    
    struct Batch {
        static let name = "batch"
    }
    
    struct EventID {
        static let name = "evt-id"
    }
    
    struct Acknowledgement {
        static let name = "ack"
    }
    
    struct Error {
        static let name = "err"
        
        struct ErrorType {
            static let name = "err-type"
            
            struct Internal {
                static let name = "internal-error"
            }
            
            struct PermissionDenied {
                static let name = "permission-denied"
            }
            
            struct ConnectionTerminated {
                static let name = "connection-terminated"
            }
        }
        
        struct ErrorMessage {
            static let name = "err-message"
        }
    }
    
    struct Mutation {
        static let name = "mut"
        
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
    
    struct Merge {
        static let name = "mer"
        
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
        
        struct Limit {
            static let name = "limit"
        }
        
        struct Skip {
            static let name = "skip"
        }
    }
    
    struct SubscriptionValue {
        static let name = "val"
        
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
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
        
        struct CollectionID {
            static let name = "col-id"
        }
        
        struct Document {
            static let name = "doc"
        }
    }
    
    struct Document {
        
        struct DocumentID {
            static let name = "id"
        }
        
        struct TimeStamp {
            static let name = "ts"
        }
        
        struct Body {
            static let name = "body"
        }
        
        //TODO: Sibling
        struct Predecessor {
            static let name = "pred-id"
        }
    }
    
    struct Unsubscribe {
        static let name = "uns"
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
    }
    
    struct Connect {
        static let name = "con"
        
        struct ConnectionID {
            static let name = "con-id"
        }
    }
    
    struct Disconnect {
        static let name = "dis"
    }
    
    struct Heartbeat {
        static let name = "hb"
    }
}
