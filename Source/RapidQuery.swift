//
//  RapidQuery.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Subscription filter
public class RapidFilter: RapidSubscriptionHashable {
    
    /// Special key which stands for a document ID
    public static let documentIdKey = "$id"
    
    internal var subscriptionHash: String { return "" }
}

public extension RapidFilter {
    
    // MARK: Compound filters
    
    class func not(_ filter: RapidFilter) -> RapidFilter {
        return RapidFilterCompound(compoundOperator: .not, operands: [filter])
    }
    
    class func and(_ operands: [RapidFilter]) -> RapidFilter {
        return RapidFilterCompound(compoundOperator: .and, operands: operands)
    }
    
    class func or(_ operands: [RapidFilter]) -> RapidFilter {
        return RapidFilterCompound(compoundOperator: .or, operands: operands)
    }
    
    // MARK: Simple filters
    
    class func equal<Numeric: Comparable>(key: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(key: key, relation: .equal, value: value)
    }
    
    class func isNull(key: String) -> RapidFilter {
        return RapidFilterSimple(key: key, relation: .equal)
    }
    
    class func greaterThan<Numeric: Comparable>(key: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(key: key, relation: .greaterThan, value: value)
    }
    
    class func greaterThanOrEqual<Numeric: Comparable>(key: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(key: key, relation: .greaterThanOrEqual, value: value)
    }
    
    class func lessThan<Numeric: Comparable>(key: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(key: key, relation: .lessThan, value: value)
    }
    
    class func lessThanOrEqual<Numeric: Comparable>(key: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(key: key, relation: .lessThanOrEqual, value: value)
    }
    
}

/// Class that describes simple subscription filter
///
/// Simple filter can contain only a name of a filtering parameter, its reference value and a relation to the value.
public class RapidFilterSimple: RapidFilter {
    
    /// Type of relation to a specified value
    public enum Relation {
        case equal
        case greaterThanOrEqual
        case lessThanOrEqual
        case greaterThan
        case lessThan
        
        var hash: String {
            switch self {
            case .equal:
                return "e"
                
            case .greaterThanOrEqual:
                return "gte"
                
            case .lessThanOrEqual:
                return "lte"
                
            case .greaterThan:
                return "gt"
                
            case .lessThan:
                return "lt"
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
    init<Numeric: Comparable>(key: String, relation: Relation, value: Numeric) {
        self.key = key
        self.relation = relation
        self.value = value
    }
    
    /// Simple filter initializer
    ///
    /// - Parameters:
    ///   - key: Name of a document parameter
    ///   - relation: Ralation to the `value`
    init(key: String, relation: Relation) {
        self.key = key
        self.relation = relation
        self.value = nil
    }
    
    override var subscriptionHash: String {
        return "\(key)-\(relation.hash)-\(value ?? "null")"
    }
}

/// Class that describes compound subscription filter
///
/// Compound filter consists of one or more filters that are combined together with one of logical operators.
/// Compound filter with the logical NOT operator must contain only one operand.
public class RapidFilterCompound: RapidFilter {
    
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
    /// Subscription Hash
    fileprivate let storedHash: String
    
    /// Compound filter initializer
    ///
    /// - Parameters:
    ///   - compoundOperator: Logical operator
    ///   - operands: Array of filters that are combined together with the `compoundOperator`
    init(compoundOperator: Operator, operands: [RapidFilter]) {
        self.compoundOperator = compoundOperator
        self.operands = operands
        
        let hash = operands.sorted(by: { $0.subscriptionHash > $1.subscriptionHash }).flatMap({ $0.subscriptionHash }).joined(separator: "|")
        self.storedHash = "\(compoundOperator.hash)(\(hash))"
    }

    override var subscriptionHash: String {
        return storedHash
    }
}

/// Structure that describes subscription ordering
public struct RapidOrdering: RapidSubscriptionHashable {
    
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
    
    var subscriptionHash: String {
        return "o-\(key)-\(ordering.hash)"
    }

}

/// Structure that contains subscription paging values
public struct RapidPaging: RapidSubscriptionHashable {
    
    /// Number of documents to be skipped
    public let skip: Int?
    /// Maximum number of documents to be returned
    public let take: Int
    
    var subscriptionHash: String {
        var hash = "t\(take)"
        
        if let skip = skip {
            hash += "s\(skip)"
        }
        
        return hash
    }
}
