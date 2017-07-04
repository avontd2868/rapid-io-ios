//
//  UIColorExtension.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
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
    
    static let appText = UIColor("#1C1D2F")
    
    static let appSeparator = UIColor("#EEEBF3")
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
