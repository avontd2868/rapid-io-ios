//
//  ExampleAppTests.swift
//  ExampleAppTests
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import ExampleApp
@testable import Rapid

class ExampleAppTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        Rapid.deinitialize()
        
        super.tearDown()
    }
    
    func testExample() {
        Rapid.configure(withAPIKey: "ws://13.64.77.202:8080")
        
        XCTAssertEqual(Rapid.connectionState, .connecting)
    }
    
}
