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
        let podBundle = NSBundle(forClass: PDFViewController.classForCoder())
        
        if image == nil {
            if let bundleURL = podBundle.URLForResource("UXMPDFKit", withExtension: "bundle"),
                let bundle = NSBundle(URL: bundleURL) {
                return UIImage(
                    named: named,
                    inBundle: bundle,
                    compatibleWithTraitCollection: nil)
            }
        }
        return image
    }
}
