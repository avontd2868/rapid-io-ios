//
//  ViewController.swift
//  ExamplePodApp
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

    func subscribe() {
        if Rapid.connectionState == .connected {
            Rapid.collection(named: "messages").subscribe(completion: { (error, documents) in
                if let error = error as? RapidError {
                    print(error)
                }
                else {
                    print(documents)
                }
            })
        }
    }
    
    func mutate() {
        Rapid.collection(named: "messages").document(withID: "1").mutate(value: ["text": "texty text"])
    }
}

