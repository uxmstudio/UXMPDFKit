//
//  PDFPathAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/24/16.
//
//

import UIKit

class PDFPathAnnotation {
    var page: Int?
    
    var path: UIBezierPath = UIBezierPath()
    var color: UIColor = UIColor.black {
        didSet {
            color.setStroke()
            path.stroke()
        }
    }
    var fill: Bool = false
    var lineWidth: CGFloat = 3.0 {
        didSet {
            path.lineWidth = lineWidth
        }
    }
    var rect: CGRect = CGRect(x: 0, y: 0, width: 1000, height: 1000) {
        didSet {
            view.frame = rect
        }
    }
    lazy var view: PDFPathView = PDFPathView(parent: self, frame: self.rect)
    var incrementalImage: UIImage?
    
    fileprivate var points: [CGPoint] = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    fileprivate var ctr: Int = 0
    
    func drawRect(_ frame: CGRect) {
        self.incrementalImage?.draw(in: rect)
        self.color.setStroke()
        self.path.stroke()
    }
}

class PDFPathView: UIView {
    var parent: PDFPathAnnotation?
    
    convenience init(parent: PDFPathAnnotation, frame: CGRect) {
        self.init()
        
        self.frame = frame
        self.parent = parent
        
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        parent?.drawRect(rect)
    }
}

extension PDFPathAnnotation: PDFAnnotation {
    func mutableView() -> UIView {
        view = PDFPathView(parent: self, frame: rect)
        return view
    }
    
    func touchStarted(_ touch: UITouch, point: CGPoint) {
        ctr = 0
        points[0] = point
    }
    
    func touchMoved(_ touch: UITouch, point: CGPoint) {
        ctr += 1
        points[ctr] = point
        if ctr == 4 {
            points[3] = CGPoint(
                x: (points[2].x + points[4].x) / 2.0,
                y: (points[2].y + points[4].y) / 2.0
            )
            
            path.move(to: points[0])
            path.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
            
            view.setNeedsDisplay()
            
            points[0] = points[3]
            points[1] = points[4]
            
            ctr = 1
        }
    }
    
    func touchEnded(_ touch: UITouch, point: CGPoint) {
        drawBitmap()
        view.setNeedsDisplay()
        path.removeAllPoints()
        ctr = 0
    }
    
    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        if incrementalImage == nil {
            let path = UIBezierPath(rect: view.bounds)
            UIColor.clear.setFill()
            path.fill()
        }
        
        incrementalImage?.draw(at: CGPoint.zero)
        color.setStroke()
        path.stroke()
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func drawInContext(_ context: CGContext) {
        drawBitmap()
        drawRect(rect)
    }
}

class PDFHighlighterAnnotation: PDFPathAnnotation {
    override init() {
        super.init()
        
        color = UIColor.yellow.withAlphaComponent(0.3)
        lineWidth = 10.0
    }
}
