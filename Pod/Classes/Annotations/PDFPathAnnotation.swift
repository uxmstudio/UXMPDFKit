//
//  PDFPathAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/24/16.
//
//

import UIKit

class PDFPathAnnotation {
    
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
    var rect:CGRect = CGRectMake(0, 0, 1000, 1000) {
        didSet {
            self.view.frame = self.rect
        }
    }
    lazy var view:PDFPathView = PDFPathView(parent: self, frame: self.rect)
    var incrementalImage:UIImage?
    
    private var points:[CGPoint] = [CGPointZero,CGPointZero,CGPointZero,CGPointZero,CGPointZero]
    private var ctr:Int = 0
    
    func drawRect(frame: CGRect) {
        
        self.incrementalImage?.drawInRect(rect)
        self.color.setStroke()
        self.path.stroke()
    }
}

class PDFPathView:UIView {
    
    var parent:PDFPathAnnotation?
    
    convenience init(parent: PDFPathAnnotation, frame: CGRect) {
        self.init()
        
        self.frame = frame
        self.parent = parent
        
        self.backgroundColor = UIColor.clearColor()
        self.opaque = false
    }
    
    override func drawRect(rect: CGRect) {
        
        self.parent?.drawRect(rect)
    }
}

extension PDFPathAnnotation:PDFAnnotation {
    
    func mutableView() -> UIView {
        self.view = PDFPathView(parent: self, frame: self.rect)
        return self.view
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
            
            self.view.setNeedsDisplay()
            
            self.points[0] = self.points[3]
            self.points[1] = self.points[4]
            
            self.ctr = 1
        }
    }
    
    func touchEnded(touch: UITouch, point: CGPoint) {
        
        self.drawBitmap()
        self.view.setNeedsDisplay()
        self.path.removeAllPoints()
        self.ctr = 0
    }
    
    func drawBitmap() {
        
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
        
        if self.incrementalImage == nil {
            let path = UIBezierPath(rect: self.view.bounds)
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
        self.drawRect(self.rect)
    }
}


class PDFHighlighterAnnotation:PDFPathAnnotation {
    
    override init() {
        
        super.init()
        
        self.color = UIColor.yellowColor().colorWithAlphaComponent(0.3)
        self.lineWidth = 10.0
    }
}