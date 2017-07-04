//
//  AppNavigationController.swift
//  RapiChat
//
//  Created by Jan on 28/06/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import UIKit

class AppNavigationController: UINavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        setupUI()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if visibleViewController != nil {
            visibleViewController?.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        }
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        if viewControllers.count > 1 {
            return super.popViewController(animated: animated)
        }
        else {
            dismiss(animated: animated, completion: nil)
            return nil
        }
    }
    
    class func setupNavigationBar(_ bar: UINavigationBar) {
        bar.barTintColor = .white
        bar.isTranslucent = false
        bar.titleTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.appText, NSAttributedStringKey.font.rawValue: UIFont.systemFont(ofSize: 20)]
        bar.tintColor = UIColor.appRed
        bar.shadowImage = UIImage.imageWithColor(.appSeparator)
        bar.setBackgroundImage(UIImage(), for: .default)
        bar.barStyle = .black
    }
}

private extension AppNavigationController {
    
    func setupUI() {
        AppNavigationController.setupNavigationBar(navigationBar)
    }
}
