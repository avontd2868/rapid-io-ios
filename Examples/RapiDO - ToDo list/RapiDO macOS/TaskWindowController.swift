//
//  TaskWindowController.swift
//  RapiDO
//
//  Created by Jan on 16/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Cocoa

class TaskWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.delegate = self
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let window = window {
            AppDelegate.windowClosed(window)
        }
        return true
    }
}
