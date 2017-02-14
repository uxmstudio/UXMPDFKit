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
    
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(self.cgImage!, in: newRect)
            let newImage = UIImage(cgImage: context.makeImage()!)
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
}
