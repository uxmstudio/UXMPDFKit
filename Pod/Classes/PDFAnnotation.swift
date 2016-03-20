//
//  PDFAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

protocol PDFAnnotation {
    
    func drawInContext(context: CGContextRef)
}

struct PDFTextAnnotation:PDFAnnotation {
    
    var text:String = ""
    var rect:CGRect = CGRectMake(0, 0, 0, 0)
    var font:UIFont = UIFont.systemFontOfSize(14.0)
    
    func drawInContext(context: CGContextRef) {
        
        UIGraphicsPushContext(context)
        CGContextSetAlpha(context, 1.0)
        
        let nsText = self.text as NSString
        let paragraphStyle:NSMutableParagraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.Left
        
        let attributes:[String:AnyObject] = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.blackColor(),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let size:CGSize = nsText.sizeWithAttributes(attributes)
        let textRect = CGRectMake(self.rect.origin.x, self.rect.origin.y, size.width, size.height)
        
        nsText.drawInRect(textRect, withAttributes: attributes)
        
        UIGraphicsPopContext()
    }MARPAR10
}

struct PDFPathAnnotation:PDFAnnotation {
    
    var path:CGPathRef
    var color:CGColorRef
    var alpha:CGFloat
    var fill:Bool
    var lineWidth: CGFloat
    
    func drawInContext(context: CGContextRef) {
        
        CGContextAddPath(context, self.path)
        CGContextSetLineWidth(context, self.lineWidth)
        CGContextSetAlpha(context, self.alpha)
        
        if self.fill {
            CGContextSetFillColorWithColor(context, self.color)
            CGContextFillPath(context);
        }
        else {
            CGContextSetStrokeColorWithColor(context, self.color)
            CGContextStrokePath(context)
        }
    }
}