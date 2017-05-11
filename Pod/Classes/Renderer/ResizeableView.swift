//
//  ResizeableView.swift
//  Pods
//
//  Created by Chris Anderson on 5/9/17.
//
//

import UIKit

struct ResizableViewAnchorPoint {
    var adjustsX: CGFloat
    var adjustsY: CGFloat
    var adjustsH: CGFloat
    var adjustsW: CGFloat
    
    init(_ adjustsX: CGFloat, _ adjustsY: CGFloat, _ adjustsH: CGFloat, _ adjustsW: CGFloat) {
        self.adjustsX = adjustsX
        self.adjustsY = adjustsY
        self.adjustsH = adjustsH
        self.adjustsW = adjustsW
    }
}

struct CGPointResizableViewAnchorPointPair {
    var point: CGPoint
    var anchorPoint: ResizableViewAnchorPoint
}

protocol ResizableViewDelegate {
    func resizableViewDidBeginEditing(view: ResizableView)
    func resizableViewDidEndEditing(view: ResizableView)
    func resizableViewDidSelectAction(view: ResizableView, action: String)
}

class ResizableView: UIView {
    
    lazy var borderView: ResizableBorderView = {
        return ResizableBorderView(frame: self.bounds.insetBy(dx: ResizableView.globalInset, dy: ResizableView.globalInset))
    }()
    var touchStart: CGPoint?
    var minWidth: CGFloat = 48.0
    var minHeight: CGFloat = 48.0
    var anchorPoint: ResizableViewAnchorPoint?
    var delegate: ResizableViewDelegate?
    var preventsPositionOutsideSuperview: Bool = true
    var showMenuController: Bool = false
    
    override var frame: CGRect {
        didSet {
            self.borderView.frame = self.bounds
            self.borderView.setNeedsDisplay()
        }
    }
    
    var isResizing: Bool {
        get {
            guard let anchorPoint = self.anchorPoint else { return false }
            return anchorPoint.adjustsH != 0.0
                || anchorPoint.adjustsW != 0.0
                || anchorPoint.adjustsX != 0.0
                || anchorPoint.adjustsY != 0.0
        }
    }
    
    static let globalInset: CGFloat = 0.0
    
    static let noResizeAnchorPoint    = ResizableViewAnchorPoint( 0.0, 0.0, 0.0, 0.0 )
    static let upperLeftAnchorPoint   = ResizableViewAnchorPoint( 1.0, 1.0, -1.0, 1.0 )
    static let middleLeftAnchorPoint  = ResizableViewAnchorPoint( 1.0, 0.0, 0.0, 1.0 )
    static let lowerLeftAnchorPoint   = ResizableViewAnchorPoint( 1.0, 0.0, 1.0, 1.0 )
    static let upperMiddleAnchorPoint = ResizableViewAnchorPoint( 0.0, 1.0, -1.0, 0.0 )
    static let upperRightAnchorPoint  = ResizableViewAnchorPoint( 0.0, 1.0, -1.0, -1.0 )
    static let middleRightAnchorPoint = ResizableViewAnchorPoint( 0.0, 0.0, 0.0, -1.0 )
    static let lowerRightAnchorPoint  = ResizableViewAnchorPoint( 0.0, 0.0, 1.0, -1.0 )
    static let lowerMiddleAnchorPoint = ResizableViewAnchorPoint( 0.0, 0.0, 1.0, 0.0 )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.borderView.isHidden = true
        self.addSubview(self.borderView)
        self.clipsToBounds = false
    }
    
    func hideEditingHandles() {
        self.borderView.isHidden = false
        self.showMenuController = false
    }
    
    func showEditingHandles() {
        self.borderView.isHidden = true
    }
    
    
    func anchorPoint(touch: CGPoint) -> ResizableViewAnchorPoint {
        let upperLeft   = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: 0.0, y: 0.0),
            anchorPoint: ResizableView.upperLeftAnchorPoint
        )
        let upperMiddle = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: self.bounds.size.width/2, y: 0.0),
            anchorPoint: ResizableView.upperMiddleAnchorPoint
        )
        let upperRight  = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: self.bounds.size.width, y: 0.0),
            anchorPoint: ResizableView.upperRightAnchorPoint
        )
        let middleRight = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height/2),
            anchorPoint: ResizableView.middleRightAnchorPoint
        )
        let lowerRight  = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height),
            anchorPoint: ResizableView.lowerRightAnchorPoint
        )
        let lowerMiddle = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height),
            anchorPoint: ResizableView.lowerMiddleAnchorPoint
        )
        let lowerLeft   = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: 0, y: self.bounds.size.height),
            anchorPoint: ResizableView.lowerLeftAnchorPoint
        )
        let middleLeft  = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: 0, y: self.bounds.size.height/2),
            anchorPoint: ResizableView.middleLeftAnchorPoint
        )
        let centerPoint = CGPointResizableViewAnchorPointPair(
            point: CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2),
            anchorPoint: ResizableView.noResizeAnchorPoint
        )
        
        let allPoints = [ upperLeft, upperRight, lowerRight, lowerLeft,
                          upperMiddle, lowerMiddle, middleLeft, middleRight, centerPoint ]
        var smallestDistance: CGFloat = CGFloat(MAXFLOAT)
        var closestPoint = centerPoint
        for pointPair in allPoints {
            let distance = touch.distance(point: pointPair.point)
            if distance < smallestDistance {
                closestPoint = pointPair
                smallestDistance = distance
            }
        }
        return closestPoint.anchorPoint
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        self.delegate?.resizableViewDidBeginEditing(view: self)
        
        self.borderView.isHidden = false
        self.anchorPoint = self.anchorPoint(touch: touch.location(in: self))
        
        self.touchStart = touch.location(in: self.superview)
        if !self.isResizing {
            self.touchStart = touch.location(in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /// Call delegate method
        self.delegate?.resizableViewDidEndEditing(view: self)
        
        self.toggleMenuController()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /// Call delegate method
        self.delegate?.resizableViewDidEndEditing(view: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first,
            let superview = self.superview else { return }
        if self.isResizing {
            var touch = touch.location(in: superview)
            self.resize(using: &touch)
        }
        else {
            var touch = touch.location(in: self)
            self.translate(using: &touch)
        }
    }
    
    func resize(using touch: inout CGPoint) {
        
        guard let superview = self.superview,
            let touchStart = self.touchStart,
            let anchorPoint = self.anchorPoint else { return }
        
        // (1) Update the touch point if we're outside the superview.
        if self.preventsPositionOutsideSuperview {
            let border = ResizableView.globalInset + ResizableBorderView.borderSize / 2.0
            if touch.x < border {
                touch.x = border
            }
            if touch.x > superview.bounds.size.width - border {
                touch.x = superview.bounds.size.width - border
            }
            if touch.y < border {
                touch.y = border
            }
            if touch.y > superview.bounds.size.height - border {
                touch.y = superview.bounds.size.height - border
            }
        }
        
        // (2) Calculate the deltas using the current anchor point.
        var deltaW = anchorPoint.adjustsW * (touchStart.x - touch.x)
        let deltaX = anchorPoint.adjustsX * (-1.0 * deltaW)
        var deltaH = anchorPoint.adjustsH * (touch.y - touchStart.y)
        let deltaY = anchorPoint.adjustsY * (-1.0 * deltaH)
        
        // (3) Calculate the new frame.
        var newX = self.frame.origin.x + deltaX
        var newY = self.frame.origin.y + deltaY
        var newWidth = self.frame.size.width + deltaW
        var newHeight = self.frame.size.height + deltaH
        
        // (4) If the new frame is too small, cancel the changes.
        if newWidth < self.minWidth {
            newWidth = self.frame.size.width
            newX = self.frame.origin.x
        }
        if newHeight < self.minHeight {
            newHeight = self.frame.size.height
            newY = self.frame.origin.y
        }
        
        // (5) Ensure the resize won't cause the view to move offscreen.
        if self.preventsPositionOutsideSuperview {
            if newX < superview.bounds.origin.x {
                deltaW = self.frame.origin.x - superview.bounds.origin.x
                newWidth = self.frame.size.width + deltaW
                newX = superview.bounds.origin.x
            }
            if newX + newWidth > superview.bounds.origin.x + superview.bounds.size.width {
                newWidth = superview.bounds.size.width - newX
            }
            if newY < superview.bounds.origin.y {
                deltaH = self.frame.origin.y - superview.bounds.origin.y
                newHeight = self.frame.size.height + deltaH
                newY = superview.bounds.origin.y
            }
            if newY + newHeight > superview.bounds.origin.y + superview.bounds.size.height {
                newHeight = superview.bounds.size.height - newY
            }
        }
        
        self.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        self.touchStart = touch
    }
    
    func translate(using touch: inout CGPoint) {
        
        guard let superview = self.superview,
            let touchStart = self.touchStart else { return }
        var newCenter = CGPoint(
            x: self.center.x + touch.x - touchStart.x,
            y: self.center.y + touch.y - touchStart.y
        )
        if self.preventsPositionOutsideSuperview {
            // Ensure the translation won't cause the view to move offscreen.
            let midPointX = self.bounds.minX
            if newCenter.x > superview.bounds.size.width - midPointX {
                newCenter.x = superview.bounds.size.width - midPointX
            }
            if newCenter.x < midPointX {
                newCenter.x = midPointX
            }
            
            let midPointY = self.bounds.midY
            if newCenter.y > superview.bounds.size.height - midPointY {
                newCenter.y = superview.bounds.size.height - midPointY
            }
            if newCenter.y < midPointY {
                newCenter.y = midPointY
            }
        }
        self.center = newCenter;
    }
    
    
    
    
    //MARK: Context Menu Methods
    func toggleMenuController() {
        
        if !self.showMenuController {
            self.becomeFirstResponder()
            UIMenuController.shared.setTargetRect(self.frame, in: self.superview!)
            UIMenuController.shared.menuItems = [
                UIMenuItem(
                    title: "Delete",
                    action: #selector(ResizableView.menuActionDelete(_:))
                )
            ]
            UIMenuController.shared.setMenuVisible(true, animated: true)
            self.showMenuController = true
        }
        else {
            self.resignFirstResponder()
            self.showMenuController = false
        }
    }
    
    func menuActionDelete(_ sender: Any!) {
        self.delegate?.resizableViewDidSelectAction(view: self, action: "delete")
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if action == #selector(menuActionDelete(_:)) {
            return true
        }
        return false
    }
    
    
}

class ResizableBorderView: UIView {
    
    static let borderSize: CGFloat = 10.0
    static let handleSize: CGFloat = 10.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        self.layer.masksToBounds = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.addRect(self.bounds.insetBy(dx: ResizableBorderView.borderSize/2, dy: ResizableBorderView.borderSize/2))
        context.strokePath()
        
        let upperLeft = CGRect(
            x: -ResizableBorderView.handleSize/2 + ResizableBorderView.borderSize/2,
            y: -ResizableBorderView.handleSize/2 + ResizableBorderView.borderSize/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let upperRight = CGRect(
            x: self.bounds.size.width - ResizableBorderView.handleSize/2 - ResizableBorderView.borderSize/2,
            y: -ResizableBorderView.handleSize/2 + ResizableBorderView.borderSize/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let lowerRight = CGRect(
            x: self.bounds.size.width - ResizableBorderView.handleSize/2 - ResizableBorderView.borderSize/2,
            y: self.bounds.size.height - ResizableBorderView.handleSize/2 - ResizableBorderView.borderSize/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let lowerLeft = CGRect(
            x: -ResizableBorderView.handleSize/2 + ResizableBorderView.borderSize/2,
            y: self.bounds.size.height - ResizableBorderView.handleSize/2 - ResizableBorderView.borderSize/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let upperMiddle = CGRect(
            x: (self.bounds.size.width - ResizableBorderView.borderSize)/2,
            y: -ResizableBorderView.handleSize/2 + ResizableBorderView.borderSize/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let lowerMiddle = CGRect(
            x: (self.bounds.size.width - ResizableBorderView.handleSize)/2,
            y: self.bounds.size.height - ResizableBorderView.handleSize/2 - ResizableBorderView.borderSize/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let middleLeft = CGRect(
            x: -ResizableBorderView.handleSize/2 + ResizableBorderView.borderSize/2,
            y: (self.bounds.size.height - ResizableBorderView.handleSize)/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let middleRight = CGRect(
            x: self.bounds.size.width - ResizableBorderView.handleSize/2 - ResizableBorderView.borderSize/2,
            y: (self.bounds.size.height - ResizableBorderView.handleSize)/2,
            width: ResizableBorderView.handleSize,
            height: ResizableBorderView.handleSize
        )
        
        let colors: [CGFloat] = [0.4, 0.8, 1.0, 1.0,
                                 0.0, 0.0, 1.0, 1.0]
        
        let baseSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(
            colorSpace: baseSpace,
            colorComponents: colors,
            locations: nil,
            count: 2) else { return }
        
        context.setLineWidth(1.0)
        context.setShadow(offset: CGSize(width: 0.5, height: 0.5), blur: 1)
        context.setStrokeColor(UIColor.white.cgColor)
        
        let allPoints = [ upperLeft, upperRight, lowerRight, lowerLeft,
                          upperMiddle, lowerMiddle, middleLeft, middleRight ]
        for point in allPoints {
            context.saveGState()
            context.addEllipse(in: point)
            context.clip()
            let startPoint = CGPoint(x: point.midX, y: point.minY)
            let endPoint = CGPoint(x: point.midX, y: point.maxY)
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            context.restoreGState()
            context.strokeEllipse(in: point.insetBy(dx: 1, dy: 1))
        }
        context.restoreGState()
    }
}
