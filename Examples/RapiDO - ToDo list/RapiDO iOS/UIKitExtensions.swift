//
//  UIColorExtension.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import UIKit

extension UIColor {

    public convenience init(_ hexString: String, alpha: CGFloat = 1.0) {
        // Replace # if found
        let hex = hexString.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var color: UInt32 = 0
        
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = CGFloat(Float(Int(color >> 16) & mask) / 255.0)
        let g = CGFloat(Float(Int(color >> 8) & mask) / 255.0)
        let b = CGFloat(Float(Int(color) & mask) / 255.0)
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    public convenience init(realRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
    
    static let appRed = UIColor("#CF4647")
    
    static let appBlue = UIColor("#3F91EB")
    
    static let appGreen = UIColor("#85D95B")
    
    static let appText = UIColor("#1C1D2F")
    
    static let appSeparator = UIColor("#EEEBF3")
    
    static let appPlaceholderText = UIColor("#ADA9BF")
}

extension UIImage {
    
    class func imageWithColor(_ color: UIColor, size: CGSize = CGSize(width:1, height: 1)) -> UIImage {
        
        let rect = CGRect(x: 0.0, y:  0.0, width:  size.width, height:  size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
        
    }

}

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
