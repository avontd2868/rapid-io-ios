//
//  AppDelegate.swift
//  ExampleMacOSApp
//
//  Created by Jan on 15/05/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Cocoa
import Rapid

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var newTaskWindows: [NSWindowController] = []
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func newDocument(_ sender: Any) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let window = storyboard.instantiateController(withIdentifier: "AddTaskWindow") as! NSWindowController
        window.showWindow(self)
        newTaskWindows.append(window)
    }
    
    func updateTask(_ task: Task) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let window = storyboard.instantiateController(withIdentifier: "AddTaskWindow") as! NSWindowController
        window.showWindow(self)
        newTaskWindows.append(window)
    }
    
}

