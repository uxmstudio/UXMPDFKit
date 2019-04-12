//
//  UIScreen.swift
//  UXMPDFKit
//
//  Created by Diego Stamigni on 26/01/2018.
//

import UIKit

extension UIScreen {
    var widthOfSafeArea: CGFloat {
        get {
            guard let rootView = UIApplication.shared.keyWindow else { return 0 }
            return rootView.bounds.height - self.leftSafeAreaInset - self.rightSafeAreaInset
        }
    }
    
    var heightOfSafeArea: CGFloat {
        get {
            guard let rootView = UIApplication.shared.keyWindow else { return 0 }
            return rootView.bounds.height - self.topSafeAreaInset - self.bottomSafeAreaInset
        }
    }
    
    var topSafeAreaInset: CGFloat {
        get {
            guard let rootView = UIApplication.shared.keyWindow else { return 0 }
            
            if #available(iOS 11.0, *) {
                return rootView.safeAreaInsets.top
            } else {
                return 0
            }
        }
    }
    
    var bottomSafeAreaInset: CGFloat {
        get {
            guard let rootView = UIApplication.shared.keyWindow else { return 0 }
            
            if #available(iOS 11.0, *) {
                return rootView.safeAreaInsets.bottom
            } else {
                return 0
            }
        }
    }
    
    var leftSafeAreaInset: CGFloat {
        get {
            guard let rootView = UIApplication.shared.keyWindow else { return 0 }
            
            if #available(iOS 11.0, *) {
                return rootView.safeAreaInsets.left
            } else {
                return 0
            }
        }
    }
    
    var rightSafeAreaInset: CGFloat {
        get {
            guard let rootView = UIApplication.shared.keyWindow else { return 0 }
            
            if #available(iOS 11.0, *) {
                return rootView.safeAreaInsets.right
            } else {
                return 0
            }
        }
    }
}
