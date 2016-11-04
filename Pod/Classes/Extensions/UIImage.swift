//
//  UIImage.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

extension UIImage {
    class func bundledImage(_ named: String) -> UIImage? {
        let image = UIImage(named: named)
        
        if image == nil {
            let podBundle = Bundle(for: PDFViewController.classForCoder())
            if let bundleURL = podBundle.url(forResource: "UXMPDFKit", withExtension: "bundle"),
                let bundle = Bundle(url: bundleURL) {
                return UIImage(
                    named: named,
                    in: bundle,
                    compatibleWith: nil)
            }
        }
        return image
    }
}
