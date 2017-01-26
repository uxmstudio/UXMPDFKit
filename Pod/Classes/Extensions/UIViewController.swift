//
//  UIViewController.swift
//  Pods
//
//  Created by Chris Anderson on 1/26/17.
//
//

import UIKit

extension UIViewController {
    
    static func topController() -> UIViewController? {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        return nil
    }
}
