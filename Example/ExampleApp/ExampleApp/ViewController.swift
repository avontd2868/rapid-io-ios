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
    }

    @IBAction func mutate(_ sender: Any) {
        Rapid.collection(named: "users").newDocument().mutate(value: ["name": "Jan"]) { (error, object) in
            print(error, object)
        }
    }
}

