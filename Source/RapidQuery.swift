//
//  RapidQuery.swift
//  Rapid
//
//  Created by Jan Schwarz on 17/03/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Foundation
import CoreGraphics

/// Protocol that describes a subscription query
public protocol RapidQuery {}
extension RapidQuery {
    
    /// Special key which stands for a document ID property
    public static var docIdKey: String {
        return "$id"
    }
    
    /// Special key which stands for a document creation timestamp property
    public static var docCreatedAtKey: String {
        return "$created"
    }
    
    /// Special key which stands for a document modification timestamp property
    public static var docModifiedAtKey: String {
        return "$modified"
    }
}

/// Protocol discribing a filter instance
public protocol RapidFilterDescriptor {
    var filterHash: String { get }
}

/// Protocol describing data types that can be used in filter for comparison purposes
///
/// Data types that conform to `RapidComparable` defaultly are guaranteed to be
/// compatible with Rapid database
///
/// When developer explicitly adds a conformance of another data type to `RapidComparable`
/// we cannot guarantee any behavior
public protocol RapidComparable {}
extension String: RapidComparable {}
extension Int: RapidComparable {}
extension Double: RapidComparable {}
extension Float: RapidComparable {}
extension CGFloat: RapidComparable {}
extension Bool: RapidComparable {}

/// Subscription filter
public struct RapidFilter: RapidQuery {
    
    // MARK: Compound filters
    
    /// Negate filter
    ///
    /// - Parameter filter: Filter to be negated
    /// - Returns: Negated filter
    public static func not(_ filter: RapidFilterDescriptor) -> RapidFilterDescriptor {
        return RapidFilterCompound(compoundOperator: .not, operands: [filter])
    }
    
    /// Combine filters with logical AND
    ///
    /// - Parameter operands: Filters to be combined
    /// - Returns: Compound filter
    public static func and(_ operands: [RapidFilterDescriptor]) -> RapidFilterDescriptor {
        return RapidFilterCompound(compoundOperator: .and, operands: operands)
    }
    
    /// Combine filters with logical OR
    ///
    /// - Parameter operands: Filters to be combined
    /// - Returns: Compound filter
    public static func or(_ operands: [RapidFilterDescriptor]) -> RapidFilterDescriptor {
        return RapidFilterCompound(compoundOperator: .or, operands: operands)
    }
    
    // MARK: Simple filters
    
    /// Create equality filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - value: Property value
    /// - Returns: Filter for key path equal to value
    public static func equal(keyPath: String, value: RapidComparable) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .equal, value: value)
    }
    
    /// Create equal to null filter
    ///
    /// - Parameter keyPath: Document property key path
    /// - Returns: Filter for key path equal to null
    public static func isNull(keyPath: String) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .equal)
    }
    
    /// Create greater than filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - value: Property value
    /// - Returns: Filter for key path greater than value
    public static func greaterThan(keyPath: String, value: RapidComparable) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .greaterThan, value: value)
    }
    
    /// Create greater than or equal filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - value: Property value
    /// - Returns: Filter for key path greater than or equal to value
    public static func greaterThanOrEqual(keyPath: String, value: RapidComparable) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .greaterThanOrEqual, value: value)
    }
    
    /// Create less than filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - value: Property value
    /// - Returns: Filter for key path less than value
    public static func lessThan(keyPath: String, value: RapidComparable) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .lessThan, value: value)
    }
    
    /// Create less than or equal filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - value: Property value
    /// - Returns: Filter for key path less than or equal to value
    public static func lessThanOrEqual(keyPath: String, value: RapidComparable) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .lessThanOrEqual, value: value)
    }
    
    /// Create string contains filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - subString: Property value substring
    /// - Returns: Filter for string at key path contains a substring
    public static func contains(keyPath: String, subString: String) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .contains, value: subString)
    }
    
    /// Create string starts with filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - prefix: Property value prefix
    /// - Returns: Filter for string at key path starts with a prefix
    public static func startsWith(keyPath: String, prefix: String) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .startsWith, value: prefix)
    }
    
    /// Create string ends with filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - suffix: Property value suffix
    /// - Returns: Filter for string at key path ends with a suffix
    public static func endsWith(keyPath: String, suffix: String) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .endsWith, value: suffix)
    }
    
    /// Create array contains filter
    ///
    /// - Parameters:
    ///   - keyPath: Document property key path
    ///   - value: Value that should be present in a property array
    /// - Returns: Filter for array at key path that contains a value
    public static func arrayContains(keyPath: String, value: RapidComparable) -> RapidFilterDescriptor {
        return RapidFilterSimple(keyPath: keyPath, relation: .arrayContains, value: value)
    }
}

/// Structure that describes simple subscription filter
///
/// Simple filter can contain only a name of a filtering document property, its reference value and a relation to the value.
public struct RapidFilterSimple: RapidFilterDescriptor {
    
    /// Type of relation to a specified value
    ///
    /// - equal: Property value is equal to a reference value
    /// - greaterThanOrEqual: Property value is greater than or equal to a reference value
    /// - lessThanOrEqual: Property value is less than or equal to a reference value
    /// - greaterThan: Parameter value is greater than a reference value
    /// - lessThan: Property value is less than a reference value
    /// - contains: Property value contains a reference value as a substring
    /// - startsWith: Property value starts with a reference value
    /// - endsWith: Property value ends with a reference value
    /// - arrayContains: Property array contains a reference value
    public enum Relation {
        case equal
        case greaterThanOrEqual
        case lessThanOrEqual
        case greaterThan
        case lessThan
        case contains
        case startsWith
        case endsWith
        case arrayContains
        
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
                
            case .contains:
                return "cnt"
                
            case .startsWith:
                return "pref"
                
            case .endsWith:
                return "suf"
                
            case .arrayContains:
                return "arr-cnt"
            }
        }
    }
    
    /// Name of a document property
    public let keyPath: String
    
    /// Ralation to a reference value
    public let relation: Relation
    
    /// Reference value
    public let value: Any?
    
    /// Simple filter initializer
    ///
    /// - Parameters:
    ///   - keyPath: Name of a document parameter
    ///   - relation: Ralation to the `value`
    ///   - value: Reference value
    init(keyPath: String, relation: Relation, value: RapidComparable) {
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
    
    public var filterHash: String {
        return "\(keyPath)-\(relation.hash)-\(value ?? "null")"
    }
}

/// Structure that describes compound subscription filter
///
/// Compound filter consists of one or more filters that are combined together with one of logical operators.
/// Compound filter with the logical NOT operator must contain only one operand.
public struct RapidFilterCompound: RapidFilterDescriptor {
    
    /// Type of logical operator
    ///
    /// - and: Logical AND
    /// - or: Logical OR
    /// - not: Logical NOT
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
    public let operands: [RapidFilterDescriptor]
    /// Subscription Hash
    internal let storedHash: String
    
    /// Compound filter initializer
    ///
    /// - Parameters:
    ///   - compoundOperator: Logical operator
    ///   - operands: Array of filters that are combined together with the `compoundOperator`
    init(compoundOperator: Operator, operands: [RapidFilterDescriptor]) {
        self.compoundOperator = compoundOperator
        self.operands = operands
        
        let hash = operands.sorted(by: { $0.filterHash > $1.filterHash }).flatMap({ $0.filterHash }).joined(separator: "|")
        self.storedHash = "\(compoundOperator.hash)(\(hash))"
    }

    public var filterHash: String {
        return storedHash
    }
}

/// Structure that describes subscription ordering
public struct RapidOrdering: RapidQuery {
    
    /// Type of ordering
    ///
    /// - ascending: Ascending ordering
    /// - descending: Descending ordering
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
    
    /// Name of a document property
    public let keyPath: String
    
    /// Ordering type
    public let ordering: Ordering
    
    /// Initialize an ordering
    ///
    /// - Parameters:
    ///   - keyPath: Name of a document property
    ///   - ordering: Ordering type
    public init(keyPath: String, ordering: Ordering) {
        self.keyPath = keyPath
        self.ordering = ordering
    }
    
    var orderingHash: String {
        return "o-\(keyPath)-\(ordering.hash)"
    }

}

/// Structure that contains subscription paging values
public struct RapidPaging {
    
    /// Maximum value of `take`
    public static let takeLimit = 500
    
    // Number of documents to be skipped
    //public let skip: Int?
    
    /// Maximum number of documents to be returned
    ///
    /// Max. value is 500
    public let take: Int
    
    var pagingHash: String {
        let hash = "t\(take)"
        
        //TODO: Implement skip
        /*if let skip = skip {
            hash += "s\(skip)"
        }*/
        
        return hash
    }
}
