//
//  UIViewController+Keyboard.swift
//  RapiChat
//
//  Created by Jan on 27/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

fileprivate var registeredForObject: UIView?

@objc protocol AdjustsToKeyboard: class {
    func animateWithKeyboard(height: CGFloat)
    @objc optional func completeKeyboardAnimation(height: CGFloat)
}

extension UIViewController {
    
    func registerForKeyboardFrameChangeNotifications(object: UIView? = nil) {
        if registeredForObject != nil {
            registeredForObject = object
            return
        }
        
        registeredForObject = object
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func unregisterKeyboardFrameChangeNotifications(object: UIView? = nil) {
        if registeredForObject == nil || registeredForObject == object {
            NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
            
            registeredForObject = nil
        }
    }
    
    @objc fileprivate func keyboardWillChangeFrame(_ notification: NSNotification) {
        
        if let delegate = self as? AdjustsToKeyboard,
            let userInfo = notification.userInfo,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
            let endFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let options = UIViewAnimationOptions(rawValue: UInt(curve << 16))
            let height = UIScreen.main.bounds.height - endFrame.origin.y
            
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: { () -> Void in
                delegate.animateWithKeyboard(height: height)
                self.view.layoutIfNeeded()
            }, completion: { (_) -> Void in
                delegate.completeKeyboardAnimation?(height: height)
            })
        }
    }
    
}
