//
//  RapidQuery.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public protocol RapidFilter {
    var filterHash: String { get }
}

public struct RapidFilterSimple: RapidFilter {
    
    public enum Relation {
        case equal
        case greaterThanOrEqual
        case lessThanOrEqual
        
        var hash: String {
            switch self {
            case .equal:
                return "e"
                
            case .greaterThanOrEqual:
                return "gte"
                
            case .lessThanOrEqual:
                
                return "lte"
            }
        }
    }
    
    public let key: String
    public let relation: Relation
    public let value: Any
    
    public var filterHash: String {
        return "\(key)-\(relation.hash)-\(value)"
    }
}

public struct RapidFilterCompound: RapidFilter {
    
    public enum Operator {
        case and
        case or
        case not
        
        var hash: String {
            switch self {
            case .and:
                return "and"
                
            case .or:
                return "or"
                
            case .not:
                return "not"
            }
        }
    }
    
    public let compoundOperator: Operator
    public let operands: [RapidFilter]
    
    public init?(compoundOperator: Operator, operands: [RapidFilter]) {
        guard operands.count > 0 else {
            return nil
        }
        
        if compoundOperator == .not && operands.count > 1 {
            return nil
        }
        
        self.compoundOperator = compoundOperator
        self.operands = operands
    }
    
    public var filterHash: String {
        let hash = operands.map({ $0.filterHash }).joined(separator: "|")
        return "\(compoundOperator.hash)(\(hash))"
    }
}

public struct RapidOrdering {
    
    public enum Ordering {
        case ascending
        case descending
        
        var hash: String {
            switch self {
            case .ascending:
                return "a"
                
            case .descending:
                return "d"
            }
        }
    }
    
    public let key: String
    public let ordering: Ordering
    
    var orderingHash: String {
        return "o-\(key)-\(ordering.hash)"
    }
}

public struct RapidPaging {
    
    public let skip: Int?
    public let take: Int
    
    var pagingHash: String {
        var hash = "t\(take)"
        
        if let skip = skip {
            hash += "s\(skip)"
        }
        
        return hash
    }
}
