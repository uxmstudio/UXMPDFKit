//
//  PDFPathAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/24/16.
//
//

import UIKit

open class PDFPathAnnotation: NSObject, NSCoding {
    
    public var page: Int?
    public var uuid: String = UUID().uuidString
    public var saved: Bool = false
    public var delegate: PDFAnnotationEvent?
    
    var path: UIBezierPath = UIBezierPath()
    
    /// The color for the stroke to be
    public var color: UIColor = UIColor.black {
        didSet {
            color.setStroke()
            path.stroke()
        }
    }
    
    /// The linewidth of the stroke
    public var lineWidth: CGFloat = 3.0 {
        didSet {
            path.lineWidth = lineWidth
        }
    }
    var fill: Bool = false
    var rect: CGRect = CGRect(x: 0, y: 0, width: 1000, height: 1000) {
        didSet {
            view.frame = rect
        }
    }
    lazy var view: PDFPathView = PDFPathView(parent: self, frame: self.rect)
    var incrementalImage: UIImage?
    
    fileprivate var points: [CGPoint] = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    fileprivate var ctr: Int = 0
    
    override required public init() { super.init() }
    
    required public init(coder aDecoder: NSCoder) {
        page = aDecoder.decodeObject(forKey: "page") as? Int
        path = aDecoder.decodeObject(forKey: "path") as! UIBezierPath
        color = aDecoder.decodeObject(forKey: "color") as! UIColor
        fill = aDecoder.decodeBool(forKey: "fill")
        lineWidth = aDecoder.decodeObject(forKey: "lineWidth") as! CGFloat
        rect = aDecoder.decodeCGRect(forKey: "rect")
        points = aDecoder.decodeObject(forKey: "points") as! [CGPoint]
        incrementalImage = aDecoder.decodeObject(forKey: "image") as? UIImage
        ctr = aDecoder.decodeInteger(forKey: "ctr")
        
        super.init()
    }
    
    public func didEnd() {
        self.view.hideEditingHandles()
    }
    
    func drawRect(_ frame: CGRect, point: CGPoint = CGPoint.zero) {
        self.incrementalImage?.draw(at: point)
        self.path.lineWidth = self.lineWidth
        self.color.setStroke()
        self.path.stroke()
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(page, forKey: "page")
        aCoder.encode(path, forKey: "path")
        aCoder.encode(color, forKey: "color")
        aCoder.encode(fill, forKey: "fill")
        aCoder.encode(lineWidth, forKey: "lineWidth")
        aCoder.encode(rect, forKey: "rect")
        aCoder.encode(points, forKey: "points")
        aCoder.encode(ctr, forKey: "ctr")
        aCoder.encode(incrementalImage, forKey: "image")
    }
}

class PDFPathView: ResizableView, PDFAnnotationView {
    var parent: PDFAnnotation?
    override var canBecomeFirstResponder: Bool { return true }
    
    convenience init(parent: PDFPathAnnotation, frame: CGRect) {
        
        self.init()
        
        self.frame = frame
        self.parent = parent
        self.delegate = parent
        
        backgroundColor = UIColor.clear
        isOpaque = false
        clipsToBounds = false
    }
    
    override func draw(_ rect: CGRect) {
        (parent as? PDFPathAnnotation)?.drawRect(rect)
    }
}

extension PDFPathAnnotation: PDFAnnotation {
    
    public func mutableView() -> UIView {
        view = PDFPathView(parent: self, frame: rect)
        return view
    }
    
    public func touchStarted(_ touch: UITouch, point: CGPoint) {
        ctr = 0
        points[0] = point
        path.move(to: points[0])
    }
    
    public func touchMoved(_ touch: UITouch, point: CGPoint) {
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
    
    public func touchEnded(_ touch: UITouch, point: CGPoint) {
        
        view.setNeedsDisplay()
        ctr = 0
    }
    
    public func save() {
        
        let rect = path.bounds
        let inset: CGFloat = 5.0
        let translation = CGAffineTransform(translationX: -path.bounds.minX + inset,
                                            y: -path.bounds.minY + inset)
        path.apply(translation)
        
        self.rect = rect.insetBy(dx: -1 * inset, dy: -1 * inset)
        
        drawBitmap()
        view.setNeedsDisplay()
        ctr = 0
        
        self.saved = true
    }
    
    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        if incrementalImage == nil {
            let path = UIBezierPath(rect: rect)
            UIColor.clear.setFill()
            path.fill()
        }
        
        incrementalImage?.draw(at: CGPoint.zero)
        color.setStroke()
        path.stroke()
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    public func drawInContext(_ context: CGContext) {
        drawBitmap()
        drawRect(rect, point: rect.origin)
    }
}

extension PDFPathAnnotation: ResizableViewDelegate {
    func resizableViewDidBeginEditing(view: ResizableView) { }
    
    func resizableViewDidEndEditing(view: ResizableView) {
        self.rect = self.view.frame
    }
    
    func resizableViewDidSelectAction(view: ResizableView, action: String) {
        self.delegate?.annotation(annotation: self, selected: action)
    }
}

open class PDFPenAnnotation: PDFPathAnnotation, PDFAnnotationButtonable {
    
    public static var name: String? { return "Pen" }
    public static var buttonImage: UIImage? { return UIImage.bundledImage("pen") }
}

open class PDFHighlighterAnnotation: PDFPathAnnotation, PDFAnnotationButtonable {
    
    public static var name: String? { return "Highlighter" }
    public static var buttonImage: UIImage? { return UIImage.bundledImage("highlighter") }
    
    required public init() {
        super.init()
        
        color = UIColor.yellow.withAlphaComponent(0.3)
        lineWidth = 10.0
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
