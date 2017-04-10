//
//  RapidQuery.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public protocol RapidQuery {}
extension RapidQuery {
    
    /// Special key which stands for a document ID
    static var documentIdKey: String {
        return "$id"
    }
}

/// Subscription filter
public class RapidFilter: RapidSubscriptionHashable, RapidQuery {
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
    
    class func equal<Numeric: Comparable>(keyPath: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(keyPath: keyPath, relation: .equal, value: value)
    }
    
    class func isNull(keyPath: String) -> RapidFilter {
        return RapidFilterSimple(keyPath: keyPath, relation: .equal)
    }
    
    class func greaterThan<Numeric: Comparable>(keyPath: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(keyPath: keyPath, relation: .greaterThan, value: value)
    }
    
    class func greaterThanOrEqual<Numeric: Comparable>(keyPath: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(keyPath: keyPath, relation: .greaterThanOrEqual, value: value)
    }
    
    class func lessThan<Numeric: Comparable>(keyPath: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(keyPath: keyPath, relation: .lessThan, value: value)
    }
    
    class func lessThanOrEqual<Numeric: Comparable>(keyPath: String, value: Numeric) -> RapidFilter {
        return RapidFilterSimple(keyPath: keyPath, relation: .lessThanOrEqual, value: value)
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
    public let keyPath: String
    /// Ralation to a specified value
    public let relation: Relation
    /// Reference value
    public let value: Any?
    
    /// Simple filter initializer
    ///
    /// - Parameters:
    ///   - keyPath: Name of a document parameter
    ///   - relation: Ralation to the `value`
    ///   - value: Reference value
    init<Numeric: Comparable>(keyPath: String, relation: Relation, value: Numeric) {
        self.keyPath = keyPath
        self.relation = relation
        self.value = value
    }
    
    /// Simple filter initializer
    ///
    /// - Parameters:
    ///   - keyPath: Name of a document parameter
    ///   - relation: Ralation to the `value`
    init(keyPath: String, relation: Relation) {
        self.keyPath = keyPath
        self.relation = relation
        self.value = nil
    }
    
    override var subscriptionHash: String {
        return "\(keyPath)-\(relation.hash)-\(value ?? "null")"
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
public struct RapidOrdering: RapidSubscriptionHashable, RapidQuery {
    
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
    public let keyPath: String
    /// Ordering type
    public let ordering: Ordering
    
    /// Ordering initializer
    ///
    /// - Parameters:
    ///   - keyPath: Name of a document parameter
    ///   - ordering: Ordering type
    public init(keyPath: String, ordering: Ordering) {
        self.keyPath = keyPath
        self.ordering = ordering
    }
    
    var subscriptionHash: String {
        return "o-\(keyPath)-\(ordering.hash)"
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
