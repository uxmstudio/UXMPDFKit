//
//  PDFTextAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

class PDFTextAnnotation:NSObject {
    
    var text:String = "" {
        didSet {
            self.textView.text = text
        }
    }
    
    var rect:CGRect = CGRectZero {
        didSet {
            self.textView.frame = self.rect
        }
    }
    
    var font:UIFont = UIFont.systemFontOfSize(14.0) {
        didSet {
            self.textView.font = self.font
        }
    }
    
    lazy var textView:UITextView = self.createTextView()
    
    private var startTouch:CGPoint = CGPointZero
    private var startInternalPosition:CGPoint = CGPointZero
    private var isDragging:Bool = false
    
    func createTextView() -> UITextView {
        let textView = UITextView(frame: self.rect)
        textView.delegate = self
        textView.font = self.font
        textView.text = self.text
        
        textView.layer.borderWidth = 2.0
        textView.layer.borderColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9).CGColor
        textView.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.2)
        
        return textView
    }
}

extension PDFTextAnnotation:PDFAnnotation {
    
    func mutableView() -> UIView {
        self.textView = self.createTextView()
        return self.textView
    }
    
    func touchStarted(touch: UITouch, point: CGPoint) {
        
        self.startTouch = point
        self.startInternalPosition = touch.locationInView(self.textView)
        
        if (CGRectContainsPoint(self.textView.frame, point)) {
            self.isDragging = true
        }
        else {
            self.textView.resignFirstResponder()
        }
        
        if self.rect == CGRectZero {
            self.rect = CGRectMake(point.x, point.y, 300.0, 32.0)
        }
    }
    
    func touchMoved(touch: UITouch, point: CGPoint) {
        
        if self.isDragging {
            
            self.rect = CGRectMake(
                point.x - self.startInternalPosition.x,
                point.y - self.startInternalPosition.y,
                self.rect.width,
                self.rect.height
            )
        }
    }
    
    func touchEnded(touch: UITouch, point: CGPoint) {
        if self.startTouch == point {
            self.textView.becomeFirstResponder()
        }
        self.isDragging = false
    }
    
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
    }
}

extension PDFTextAnnotation:UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        self.textView.sizeToFit()
        
        var width:CGFloat = 300.0
        if self.textView.frame.width > width {
            width = self.textView.frame.width
        }
        
        self.rect = CGRectMake(self.textView.frame.origin.x,
                               self.textView.frame.origin.y,
                               width,
                               self.textView.frame.height)
        
        if self.text != self.textView.text {
            self.text = self.textView.text
        }
    }
}
