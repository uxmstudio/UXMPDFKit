//
//  PDFTextAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

class PDFTextAnnotation: NSObject, NSCoding {
    var page: Int?
    
    var text: String = "" {
        didSet {
            textView.text = text
        }
    }
    
    var rect: CGRect = CGRect.zero {
        didSet {
            textView.frame = self.rect
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 14.0) {
        didSet {
            textView.font = self.font
        }
    }
    
    lazy var textView: UITextView = self.createTextView()
    
    fileprivate var startTouch: CGPoint = CGPoint.zero
    fileprivate var startInternalPosition: CGPoint = CGPoint.zero
    fileprivate var isDragging: Bool = false
    
    func createTextView() -> UITextView {
        let textView = UITextView(frame: rect)
        textView.delegate = self
        textView.font = font
        textView.text = text
        
        textView.layer.borderWidth = 2.0
        textView.layer.borderColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9).cgColor
        textView.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.2)
        
        return textView
    }
    
    override init() { super.init() }
    
    required init(coder aDecoder: NSCoder) {
        page = aDecoder.decodeObject(forKey: "page") as? Int
        text = aDecoder.decodeObject(forKey: "text") as! String
        rect = aDecoder.decodeCGRect(forKey: "rect")
        font = aDecoder.decodeObject(forKey: "font") as! UIFont
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(page, forKey: "page")
        aCoder.encode(text, forKey: "text")
        aCoder.encode(rect, forKey: "rect")
        aCoder.encode(font, forKey: "font")
    }
}

extension PDFTextAnnotation: PDFAnnotation {
    func mutableView() -> UIView {
        textView = createTextView()
        return textView
    }
    
    func touchStarted(_ touch: UITouch, point: CGPoint) {
        startTouch = point
        startInternalPosition = touch.location(in: textView)
        
        if textView.frame.contains(point) {
            isDragging = true
        }
        else {
            textView.resignFirstResponder()
        }
        
        if rect == CGRect.zero {
            rect = CGRect(origin: point, size: CGSize(width: 300, height: 32))
        }
    }
    
    func touchMoved(_ touch: UITouch, point: CGPoint) {
        if isDragging {
            rect = CGRect(
                x: point.x - startInternalPosition.x,
                y: point.y - startInternalPosition.y,
                width: rect.width,
                height: rect.height
            )
        }
    }
    
    func touchEnded(_ touch: UITouch, point: CGPoint) {
        if startTouch == point {
            textView.becomeFirstResponder()
        }
        isDragging = false
    }
    
    func drawInContext(_ context: CGContext) {
        UIGraphicsPushContext(context)
        context.setAlpha(1.0)
        
        let nsText = self.text as NSString
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.left
        
        let attributes: [String:AnyObject] = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.black,
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let size = nsText.size(attributes: attributes)
        let textRect = CGRect(origin: rect.origin, size: size)
        
        nsText.draw(in: textRect, withAttributes: attributes)
        
        UIGraphicsPopContext()
    }
}

extension PDFTextAnnotation: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.sizeToFit()
        
        var width: CGFloat = 300.0
        if self.textView.frame.width > width {
            width = self.textView.frame.width
        }
        
        rect = CGRect(x: textView.frame.origin.x,
                           y: textView.frame.origin.y,
                           width: width,
                           height: textView.frame.height)
        
        if text != textView.text {
            text = textView.text
        }
    }
}
