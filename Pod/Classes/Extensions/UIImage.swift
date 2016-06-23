//
//  UIImage.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

extension UIImage {
    
    class func bundledImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            return UIImage(
                named: named,
                inBundle: NSBundle(forClass: PDFViewController.classForCoder()),
                compatibleWithTraitCollection: nil)
        }
        return image
    }
}
