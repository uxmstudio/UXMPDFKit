//
//  PDFAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

protocol PDFAnnotation {
    
    func mutableView() -> UIView
    func touchStarted(touch: UITouch, point:CGPoint)
    func touchMoved(touch:UITouch, point:CGPoint)
    func touchEnded(touch:UITouch, point:CGPoint)
    func drawInContext(context: CGContextRef)
}

class PDFTextAnnotation:UIView {
    
    var text:String = "" {
        didSet {
            self.textField.text = text
        }
    }
    var rect:CGRect = CGRectZero {
        didSet {
            self.frame = self.rect
            self.textField.frame = CGRectMake(2.0, 2.0, self.rect.width + 4.0, self.rect.height + 4.0)
        }
    }
    var font:UIFont = UIFont.systemFontOfSize(14.0) {
        didSet {
            self.textField.font = self.font
        }
    }
    
    lazy var textField:UITextField = {
        let textField = UITextField(frame: self.rect)
        textField.addTarget(self, action: #selector(PDFTextAnnotation.textFieldDidChange), forControlEvents: .EditingChanged)
        return textField
    }()
    
    private var startTouch:CGPoint = CGPointZero
    private var startInternalPosition:CGPoint = CGPointZero
    private var isDragging:Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    func setupUI() {
        
        self.addSubview(self.textField)
        
        self.layer.borderColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9).CGColor
        self.layer.borderWidth = 2.0
        self.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.2)
    }
    
    func textFieldDidChange() {
        self.textField.sizeToFit()
        
        var width:CGFloat = 300.0
        if self.textField.frame.width > width {
            width = self.textField.frame.width
        }
        
        self.rect = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                width,
                                self.textField.frame.height)
    }
}

extension PDFTextAnnotation:PDFAnnotation {
    
    func mutableView() -> UIView {
        return self
    }
    
    func touchStarted(touch: UITouch, point: CGPoint) {
        
        self.startTouch = point
        self.startInternalPosition = touch.locationInView(self)

        if (CGRectContainsPoint(self.frame, point)) {
            self.isDragging = true
        }
        else {
            self.textField.resignFirstResponder()
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
            self.textField.becomeFirstResponder()
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



class PDFPathAnnotation:UIView {
    
    var path:UIBezierPath = UIBezierPath()
    var color:UIColor = UIColor.blackColor() {
        didSet {
            self.color.setStroke()
            self.path.stroke()
        }
    }
    var fill:Bool = false
    var lineWidth:CGFloat = 3.0 {
        didSet {
            self.path.lineWidth = self.lineWidth
        }
    }
    
    private var incrementalImage:UIImage?
    private var points:[CGPoint] = [CGPointZero,CGPointZero,CGPointZero,CGPointZero,CGPointZero]
    private var ctr:Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: CGRectMake(0, 0, 1000, 1000))
        
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        self.incrementalImage?.drawInRect(rect)
        self.color.setStroke()
        self.path.stroke()
    }
}

extension PDFPathAnnotation:PDFAnnotation {
    
    func mutableView() -> UIView {
        return self
    }
    
    func touchStarted(touch: UITouch, point: CGPoint) {
        self.ctr = 0
        self.points[0] = point
    }
    
    func touchMoved(touch: UITouch, point: CGPoint) {
        
        self.ctr += 1
        self.points[self.ctr] = point
        if self.ctr == 4 {
            
            self.points[3] = CGPointMake(
                (self.points[2].x + self.points[4].x) / 2.0,
                (self.points[2].y + self.points[4].y) / 2.0
            )
            
            self.path.moveToPoint(self.points[0])
            self.path.addCurveToPoint(self.points[3], controlPoint1: self.points[1], controlPoint2: self.points[2])
            
            self.setNeedsDisplay()
            
            self.points[0] = self.points[3]
            self.points[1] = self.points[4]
            
            self.ctr = 1
        }
    }
    
    func touchEnded(touch: UITouch, point: CGPoint) {
        
        self.drawBitmap()
        self.setNeedsDisplay()
        self.path.removeAllPoints()
        self.ctr = 0
    }
    
    func drawBitmap() {
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        
        if self.incrementalImage == nil {
            let path = UIBezierPath(rect: self.bounds)
            UIColor.clearColor().setFill()
            path.fill()
        }

        self.incrementalImage?.drawAtPoint(CGPointZero)
        self.color.setStroke()
        self.path.stroke()
        self.incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    func drawInContext(context: CGContextRef) {
        
        self.drawBitmap()
    }
}


class PDFHighlighterAnnotation:PDFPathAnnotation {
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.color = UIColor.yellowColor().colorWithAlphaComponent(0.3)
        self.lineWidth = 8.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}