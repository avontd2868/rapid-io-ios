//
//  RapidQuery.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Subscription filter protocol
public protocol RapidFilter {
    var filterHash: String { get }
}

/// Structure that describes simple subscription filter
///
/// Simple filter can contain only a name of a filtering parameter, its reference value and a relation to the value.
public struct RapidFilterSimple: RapidFilter {
    
    /// Special key which stands for a document ID
    public static let documentIdKey = "$id"
    
    /// Type of relation to a specified value
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
    
    /// Name of a document parameter
    public let key: String
    /// Ralation to a specified value
    public let relation: Relation
    /// Reference value
    public let value: Any?
    
    /// Simple filter initializer
    ///
    /// - Parameters:
    ///   - key: Name of a document parameter
    ///   - relation: Ralation to the `value`
    ///   - value: Reference value
    public init(key: String, relation: Relation, value: Any?) {
        self.key = key
        self.relation = relation
        self.value = value
    }
    
    public var filterHash: String {
        return "\(key)-\(relation.hash)-\(value ?? "null")"
    }
}

/// Structure that describes compound subscription filter
///
/// Compound filter consists of one or more filters that are combined together with one of logical operators.
/// Compound filter with the logical NOT operator must contain only one operand.
public struct RapidFilterCompound: RapidFilter {
    
    /// Type of logical operator
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
    
    /// Logical operator
    public let compoundOperator: Operator
    /// Array of filters
    public let operands: [RapidFilter]
    
    /// Compound filter initializer
    ///
    /// - Parameters:
    ///   - compoundOperator: Logical operator
    ///   - operands: Array of filters that are combined together with the `compoundOperator`
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

/// Structure that describes subscription ordering
public struct RapidOrdering {
    
    /// Type of ordering
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
    
    /// Name of a document parameter
    public let key: String
    /// Ordering type
    public let ordering: Ordering
    
    /// Ordering initializer
    ///
    /// - Parameters:
    ///   - key: Name of a document parameter
    ///   - ordering: Ordering type
    public init(key: String, ordering: Ordering) {
        self.key = key
        self.ordering = ordering
    }
    
    var orderingHash: String {
        return "o-\(key)-\(ordering.hash)"
    }
}

/// Structure that contains subscription paging values
public struct RapidPaging {
    
    /// Number of documents to be skipped
    public let skip: Int?
    /// Maximum number of documents to be returned
    public let take: Int
    
    var pagingHash: String {
        var hash = "t\(take)"
        
        if let skip = skip {
            hash += "s\(skip)"
        }
        
        return hash
    }
}
