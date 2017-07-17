//
//  RapidProtocolConstants.swift
//  Rapid
//
//  Created by Jan on 08/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

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
            
            struct InvalidAuthToken {
                static let name = "invalid-auth-token"
            }
            
            struct ClientSide {
                static let name = "client-error"
            }
            
            struct WriteConflict {
                static let name = "etag-conflict"
            }
        }
        
        struct ErrorMessage {
            static let name = "err-msg"
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
            
            struct Etag {
                static let name = "etag"
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
            
            struct Etag {
                static let name = "etag"
            }
            
            struct Body {
                static let name = "body"
            }
        }
    }
    
    struct Delete {
        static let name = "del"
        
        struct CollectionID {
            static let name = "col-id"
        }
        
        struct Document {
            static let name = "doc"
            
            struct DocumentID {
                static let name = "id"
            }
            
            struct Etag {
                static let name = "etag"
            }
        }
    }
    
    struct Publish {
        static let name = "pub"
        
        struct ChannelID {
            static let name = "chan-id"
        }
        
        struct Body {
            static let name = "body"
        }
    }
    
    struct Fetch {
        static let name = "ftc"
        
        struct FetchID {
            static let name = "ftc-id"
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
    
    struct CollectionSubscription {
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
    
    struct ChannelSubscription {
        static let name = "sub-ch"
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
        
        struct ChannelID {
            static let name = "chan-id"
            
            struct Prefix {
                static let name = "pref"
            }
        }
    }
    
    struct FetchValue {
        static let name = "res"
        
        struct FetchID {
            static let name = "ftc-id"
        }
        
        struct CollectionID {
            static let name = "col-id"
        }
        
        struct Documents {
            static let name = "docs"
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
    
    struct SubscriptionDocRemoved {
        static let name = "rm"
    }
    
    struct Document {
        
        struct DocumentID {
            static let name = "id"
        }
        
        struct Modified {
            static let name = "ts"
        }
        
        struct SortValue {
            static let name = "crt"
        }
        
        struct CreatedAt {
            static let name = "crt-ts"
        }
        
        struct ModifiedAt {
            static let name = "mod-ts"
        }
        
        struct Body {
            static let name = "body"
        }
        
        struct Etag {
            static let name = "etag"
        }
        
        struct SortKeys {
            static let name = "skey"
        }
    }
    
    struct ChannelMessage {
        static let name = "mes"
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
        
        struct ChannelID {
            static let name = "chan-id"
        }
        
        struct Body {
            static let name = "body"
        }
    }
    
    struct UnsubscribeCollection {
        static let name = "uns"
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
    }
    
    struct UnsubscribeChannel {
        static let name = "uns-ch"
        
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
    
    struct Reconnect {
        static let name = "rec"
        
        struct ConnectionID {
            static let name = "con-id"
        }
    }
    
    struct Disconnect {
        static let name = "dis"
    }
    
    struct NoOperation {
        static let name = "nop"
    }
    
    struct Authorization {
        static let name = "auth"
        
        struct Token {
            static let name = "token"
        }
    }
    
    struct Deauthorization {
        static let name = "deauth"
    }
    
    struct CollectionSubscriptionCancelled {
        static let name = "ca"
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
    }
    
    struct ChannelSubscriptionCancelled {
        static let name = "ca-ch"
        
        struct SubscriptionID {
            static let name = "sub-id"
        }
    }
    
    struct RequestTimestamp {
        static let name = "req-ts"
    }
    
    struct Timestamp {
        static let name = "ts"
        
        struct Timestamp {
            static let name = "timestamp"
        }
    }
}
