//
//  CocoaExtensions.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid. All rights reserved.
//

import Cocoa

extension NSColor {
    
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
    
    static let appRed = NSColor("#CF4647")
    
    static let appBlue = NSColor("#3F91EB")
    
    static let appText = NSColor("#1C1D2F")
    
    static let appSeparator = NSColor("#EEEBF3")

}

extension String {
    
    func sizeWithFont(_ font: NSFont, constraintWidth: CGFloat = CGFloat(MAXFLOAT), constraintHeight: CGFloat = CGFloat(MAXFLOAT)) -> CGSize {
        let attributes = [NSAttributedStringKey.font: font]
        var rect = (self as NSString).boundingRect(with: CGSize(width: constraintWidth, height: constraintHeight), options:.usesLineFragmentOrigin, attributes:attributes, context:nil)
        
        rect.size.height = CGFloat(ceilf(Float(rect.height)))
        rect.size.width = CGFloat(ceilf(Float(rect.width)))
        
        return rect.size
    }
    
}
