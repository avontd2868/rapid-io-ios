//
//  RapidMutationTests.swift
//  Rapid
//
//  Created by Jan on 05/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import XCTest
@testable import Rapid

extension RapidTests {
    
    func testCreateAndDelete() {
        let promise = expectation(description: "Delete document")
        
        let document = self.rapid.collection(named: testCollectionName).newDocument()
        
        document.mutate(value: ["name": "delete"], completion: { _, value in
            if let dict = value as? [AnyHashable: Any], dict["name"] as? String == "delete" {
                self.rapid.collection(named: self.testCollectionName).document(withID: document.documentID).delete(completion: { (error) in
                    if error == nil {
                        promise.fulfill()
                    }
                    else {
                        XCTFail("Document not deleted")
                    }
                })
            }
            else {
                XCTFail("Document not created")
            }
        })
        
        
        waitForExpectations(timeout: 8, handler: nil)
    }
}
