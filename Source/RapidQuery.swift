//
//  RapidQuery.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

public protocol RapidFilter {
}

public struct RapidFilterSimple: RapidFilter {
    
    enum Relation {
        case equal
        case greaterThanOrEqual
        case lessThanOrEqual
    }
    
    let key: String
    let relation: Relation
    let value: Any
}

public struct RapidFilterCompound: RapidFilter {
    
    enum Operator {
        case and
        case or
        case not
    }
    
    let compoundOperator: Operator
    let operands: [RapidFilter]
    
    init?(compoundOperator: Operator, operands: [RapidFilter]) {
        guard operands.count > 0 else {
            return nil
        }
        
        if compoundOperator == .not && operands.count > 1 {
            return nil
        }
        
        self.compoundOperator = compoundOperator
        self.operands = operands
    }
}

public struct RapidOrdering {
    
    enum Ordering {
        case ascending
        case descending
    }
}

public struct RapidPaging {
    
    let skip: Int?
    let take: Int
}
