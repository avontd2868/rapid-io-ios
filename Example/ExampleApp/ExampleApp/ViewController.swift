//
//  ViewController.swift
//  ExampleApp
//
//  Created by Jan on 14/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit
import Rapid

class ViewController: UIViewController {
    
    var subscription: RapidSubscription?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func subscribe(_ sender: Any) {
        subscription = Rapid.collection(named: "messages").subscribe { (error, documents) in
            if let error = error as? RapidError {
                switch error {
                case .permissionDenied(let message):
                    print("Permission denied: \(message)")
                    
                default:
                    print("Other error")
                }
            }
            else {
                let firstDoc = documents[0]
                let id = firstDoc.id
                let value = firstDoc.value
            }
        }
        
        Rapid.collection(named: "messages").document(withID: "1").subscribe { (error, document) in
            let message1 = document.value
            print(message1)
        }
        
        Rapid.collection(named: "messages").document(withID: "23").merge(value: ["reaction": "smile"]) { (error, value) in
            if let error = error as? RapidError {
                switch error {
                case .permissionDenied(let message):
                    print("Permission denied: \(message)")
                    
                case .timeout:
                    print("Timeout")
                    
                default:
                    print("Other error")
                }
            }
            else {
                print("Reaction successfuly added.")
            }
        }
        
        Rapid.collection(named: "messages")
            .filter(by:
                RapidFilterCompound(compoundOperator: .and, operands: [
                    RapidFilterCompound(compoundOperator: .or, operands: [
                        RapidFilterSimple(key: "sender", relation: .equal, value: "john123"),
                        RapidFilterSimple(key: "urgency", relation: .greaterThanOrEqual, value: 1)
                        ])!,
                    RapidFilterSimple(key: "receiver", relation: .equal, value: "carl01")
                    ])!)
            .order(by: [
                RapidOrdering(key: "sentDate", ordering: .descending),
                RapidOrdering(key: "urgency", ordering: .ascending)
                ])
            .limit(to: 50, skip: 10)
            .subscribe { (error, documents) in
                if let error = error {
                    print(error)
                }
                else {
                    print(documents)
                }
        }
    }

    @IBAction func unsubscribe(_ sender: Any) {
        subscription?.unsubscribe()
    }
    
    @IBAction func mutate(_ sender: Any) {
        Rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { (error, object) in
            if let error = error as? RapidError {
                switch error {
                case .permissionDenied(let message):
                    print("Permission denied: \(message)")
                    
                case .timeout:
                    print("Timeout")
                    
                default:
                    print("Other error")
                }
            }
            else {
                print("Message successfuly written.")
            }
        }
    }
}

