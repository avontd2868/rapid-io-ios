//
//  RapidSocketParser.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class RapidSocketParser {
    
    class func parse(json: [AnyHashable: Any]?) -> [RapidResponse]? {
        guard let json = json else {
            return nil
        }
        
        if let batch = json["batch"] as? [[AnyHashable: Any]] {
            return batch.flatMap({ parseEvent(json: $0) })
        }
        else if let event = parseEvent(json: json) {
            return [event]
        }
        else {
            return nil
        }
    }
}

fileprivate extension RapidSocketParser {
    
    fileprivate class func parseEvent(json: [AnyHashable: Any]) -> RapidResponse? {
        if let ack = json[Acknowledgement.name] as? [AnyHashable: Any] {
            return RapidSocketAcknowledgement(json: ack)
        }
        else if let err = json[Error.name] as? [AnyHashable: Any] {
            return RapidSocketError(json: err)
        }
        else {
            return nil
        }
    }
}

//swiftlint:disable nesting
extension RapidSocketParser {
    
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
}
