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
    var color:UIColor = UIColor.black {
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
    var rect:CGRect = CGRect(x: 0, y: 0, width: 1000, height: 1000) {
        didSet {
            self.view.frame = self.rect
        }
    }
    lazy var view:PDFPathView = PDFPathView(parent: self, frame: self.rect)
    var incrementalImage:UIImage?
    
    fileprivate var points:[CGPoint] = [CGPoint.zero,CGPoint.zero,CGPoint.zero,CGPoint.zero,CGPoint.zero]
    fileprivate var ctr:Int = 0
    
    func drawRect(_ frame: CGRect) {
        
        self.incrementalImage?.draw(in: rect)
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
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        
        self.parent?.drawRect(rect)
    }
}

extension PDFPathAnnotation:PDFAnnotation {
    
    func mutableView() -> UIView {
        self.view = PDFPathView(parent: self, frame: self.rect)
        return self.view
    }
    
    func touchStarted(_ touch: UITouch, point: CGPoint) {
        self.ctr = 0
        self.points[0] = point
    }
    
    func touchMoved(_ touch: UITouch, point: CGPoint) {
        
        self.ctr += 1
        self.points[self.ctr] = point
        if self.ctr == 4 {
            
            self.points[3] = CGPoint(
                x: (self.points[2].x + self.points[4].x) / 2.0,
                y: (self.points[2].y + self.points[4].y) / 2.0
            )
            
            self.path.move(to: self.points[0])
            self.path.addCurve(to: self.points[3], controlPoint1: self.points[1], controlPoint2: self.points[2])
            
            self.view.setNeedsDisplay()
            
            self.points[0] = self.points[3]
            self.points[1] = self.points[4]
            
            self.ctr = 1
        }
    }
    
    func touchEnded(_ touch: UITouch, point: CGPoint) {
        
        self.drawBitmap()
        self.view.setNeedsDisplay()
        self.path.removeAllPoints()
        self.ctr = 0
    }
    
    func drawBitmap() {
        
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
        
        if self.incrementalImage == nil {
            let path = UIBezierPath(rect: self.view.bounds)
            UIColor.clear.setFill()
            path.fill()
        }
        
        self.incrementalImage?.draw(at: CGPoint.zero)
        self.color.setStroke()
        self.path.stroke()
        self.incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    func drawInContext(_ context: CGContext) {
        
        self.drawBitmap()
        self.drawRect(self.rect)
    }
}


class PDFHighlighterAnnotation:PDFPathAnnotation {
    
    override init() {
        
        super.init()
        
        self.color = UIColor.yellow.withAlphaComponent(0.3)
        self.lineWidth = 10.0
    }
}
