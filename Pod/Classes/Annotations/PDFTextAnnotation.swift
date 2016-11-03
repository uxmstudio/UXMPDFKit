//
//  PDFTextAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

class PDFTextAnnotation: NSObject {
    
    var text: String = "" {
        didSet {
            self.textView.text = text
        }
    }
    
    var rect: CGRect = CGRect.zero {
        didSet {
            self.textView.frame = self.rect
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 14.0) {
        didSet {
            self.textView.font = self.font
        }
    }
    
    lazy var textView: UITextView = self.createTextView()
    
    fileprivate var startTouch: CGPoint = CGPoint.zero
    fileprivate var startInternalPosition: CGPoint = CGPoint.zero
    fileprivate var isDragging: Bool = false
    
    func createTextView() -> UITextView {
        
        let textView = UITextView(frame: self.rect)
        textView.delegate = self
        textView.font = self.font
        textView.text = self.text
        
        textView.layer.borderWidth = 2.0
        textView.layer.borderColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9).cgColor
        textView.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.2)
        
        return textView
    }
}

extension PDFTextAnnotation: PDFAnnotation {
    
    func mutableView() -> UIView {
        self.textView = self.createTextView()
        return self.textView
    }
    
    func touchStarted(_ touch: UITouch, point: CGPoint) {
        
        self.startTouch = point
        self.startInternalPosition = touch.location(in: self.textView)
        
        if (self.textView.frame.contains(point)) {
            self.isDragging = true
        }
        else {
            self.textView.resignFirstResponder()
        }
        
        if self.rect == CGRect.zero {
            self.rect = CGRect(origin: point, size: CGSize(width: 300, height: 32))
        }
    }
    
    func touchMoved(_ touch: UITouch, point: CGPoint) {
        
        if self.isDragging {
            
            self.rect = CGRect(
                x: point.x - self.startInternalPosition.x,
                y: point.y - self.startInternalPosition.y,
                width: self.rect.width,
                height: self.rect.height
            )
        }
    }
    
    func touchEnded(_ touch: UITouch, point: CGPoint) {
        if self.startTouch == point {
            self.textView.becomeFirstResponder()
        }
        self.isDragging = false
    }
    
    func drawInContext(_ context: CGContext) {
        
        UIGraphicsPushContext(context)
        context.setAlpha(1.0)
        
        let nsText = self.text as NSString
        let paragraphStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.left
        
        let attributes: [String:AnyObject] = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.black,
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let size: CGSize = nsText.size(attributes: attributes)
        let textRect = CGRect(origin: rect.origin, size: size)
        
        nsText.draw(in: textRect, withAttributes: attributes)
        
        UIGraphicsPopContext()
    }
}

extension PDFTextAnnotation: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.textView.sizeToFit()
        
        var width: CGFloat = 300.0
        if self.textView.frame.width > width {
            width = self.textView.frame.width
        }
        
        self.rect = CGRect(x: self.textView.frame.origin.x,
                           y: self.textView.frame.origin.y,
                           width: width,
                           height: self.textView.frame.height)
        
        if self.text != self.textView.text {
            self.text = self.textView.text
        }
    }
}
