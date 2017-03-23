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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func subscribe(_ sender: Any) {
        print(Rapid.connectionState)
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
        Rapid.collection(named: "users").document(withID: "1").mutate(value: ["name": "Jan"])
    }
}

