//
//  AppDelegate.swift
//  ExampleMacOSApp
//
//  Created by Jan on 15/05/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Cocoa
import Rapid

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var newTaskWindows: [NSWindow] = []
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func newDocument(_ sender: Any) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let window = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "AddTaskWindow")) as! NSWindowController
        window.showWindow(self)
        if let window = window.window {
            newTaskWindows.append(window)
        }
    }
    
    func updateTask(_ task: Task) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let window = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "AddTaskWindow")) as! NSWindowController
        (window.contentViewController as? TaskViewController)?.task = task
        window.showWindow(self)
        if let window = window.window {
            newTaskWindows.append(window)
        }
    }
    
    class func closeWindow(_ window: NSWindow) {
        window.close()
        windowClosed(window)
    }
    
    class func windowClosed(_ window: NSWindow) {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        if let index = delegate?.newTaskWindows.index(of: window) {
            delegate?.newTaskWindows.remove(at: index)
        }
    }
    
}

