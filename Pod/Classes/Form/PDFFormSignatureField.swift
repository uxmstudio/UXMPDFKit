//
//  PDFFormFieldSignature.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

public class PDFFormSignatureField: PDFFormField {

    public var name:String?
    
    private var signatureView:PDFFormFieldSignatureCaptureView?
    private let signatureExtraPadding:CGFloat = 22.0
    
    lazy private var signButton:UIButton = {
        
        var button = UIButton(frame: CGRectMake(0, 0, self.frame.width, self.frame.height))
        button.setTitle("Tap To Sign", forState: .Normal)
        button.tintColor = UIColor.blackColor()
        button.titleLabel?.font = UIFont.systemFontOfSize(14.0)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.addTarget(self, action: #selector(PDFFormSignatureField.addSignature), forControlEvents: .TouchUpInside)
        button.userInteractionEnabled = true
        button.exclusiveTouch = true
        return button
    }()
    
    lazy private var signImage:UIImageView = {
        var image = UIImageView(frame: CGRectMake(
            0,
            -self.signatureExtraPadding,
            self.frame.width,
            self.frame.height + self.signatureExtraPadding * 2
            )
        )
        image.contentMode = .ScaleAspectFit
        image.backgroundColor = UIColor.clearColor()
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.7)
        
        self.addSubview(self.signImage)
        self.addSubview(self.signButton)
        
        self.bringSubviewToFront(self.signButton)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didSetValue(value: AnyObject?) {
        if let value = value as? UIImage {
            self.signImage.image = value
        }
    }
    
    func addSignature() {
        let bounds = UIScreen.mainScreen().bounds
        let width = bounds.width
        let height = width / self.frame.width * self.frame.height + 44.0 + signatureExtraPadding * 2
        
        if let window = UIApplication.sharedApplication().keyWindow {
            let signatureView = PDFFormFieldSignatureCaptureView(frame: CGRectMake(
                (bounds.width - width) / 2, bounds.height - height, width, height))
            signatureView.delegate = self
            signatureView.layer.shadowColor = UIColor.blackColor().CGColor
            signatureView.layer.shadowOpacity = 0.4
            signatureView.layer.shadowRadius = 3.0
            signatureView.layer.shadowOffset = CGSizeMake(2.0, 2.0)
            window.addSubview(signatureView)
            self.signatureView = signatureView
        }
    }
    
    override func renderInContext(context: CGContext) {
        
        var frame = self.frame
        frame.origin.y -= signatureExtraPadding
        frame.size.height += signatureExtraPadding * 2

        self.signImage.image?.drawInRect(frame)
    }
}

extension PDFFormSignatureField: PDFFormSignatureViewDelegate {
    
    func completedSignatureDrawing(field:PDFFormFieldSignatureCaptureView) {
        self.signImage.image = field.getSignature()
        self.signatureView?.removeFromSuperview()
        self.signatureView = nil
        self.signButton.alpha = 0.0

        self.value = field.getSignature()
        self.delegate?.formFieldValueChanged(self)
    }
}

protocol PDFFormSignatureViewDelegate {
    func completedSignatureDrawing(field: PDFFormFieldSignatureCaptureView)
}

class PDFFormFieldSignatureCaptureView: UIView {
    
    var delegate: PDFFormSignatureViewDelegate?
    
    // MARK: - Public properties
    var strokeWidth: CGFloat = 2.0 {
        didSet {
            self.path.lineWidth = strokeWidth
        }
    }
    
    var strokeColor: UIColor = UIColor.blackColor() {
        didSet {
            self.strokeColor.setStroke()
        }
    }
    
    var signatureBackgroundColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.backgroundColor = signatureBackgroundColor
        }
    }
    
    var containsSignature: Bool {
        get {
            if self.path.empty {
                return false
            }
            else {
                return true
            }
        }
    }
    
    // MARK: - Private properties
    private var path = UIBezierPath()
    private var pts = [CGPoint](count: 5, repeatedValue: CGPoint())
    private var ctr = 0

    
    lazy private var doneButton:UIBarButtonItem = UIBarButtonItem(
        title: "Done",
        style: .Plain,
        target: self,
        action: #selector(PDFFormFieldSignatureCaptureView.finishSignature)
    )

    lazy private var clearButton:UIBarButtonItem = UIBarButtonItem(
        title: "Clear",
        style: .Plain,
        target: self,
        action: #selector(PDFFormFieldSignatureCaptureView.clearSignature)
    )
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    func setupUI() {
        
        self.backgroundColor = self.signatureBackgroundColor
        self.path.lineWidth = self.strokeWidth
        self.path.lineJoinStyle = CGLineJoin.Round
        
        let spacerStart = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        spacerStart.width = 10.0
        let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        let spacerEnd = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        spacerEnd.width = 10.0
        
        let toolbar = UIToolbar(frame: CGRectMake(0, self.frame.height - 44.0, self.frame.width, 44.0))
        toolbar.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        toolbar.setItems([spacerStart, clearButton, spacer, doneButton, spacerEnd], animated: false)
        self.addSubview(toolbar)
    }
    
    // MARK: - Draw
    override func drawRect(rect: CGRect) {
        self.strokeColor.setStroke()
        self.path.stroke()
    }
    
    // MARK: - Touch handling functions
    override func touchesBegan(touches: Set <UITouch>, withEvent event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.locationInView(self)
            self.ctr = 0
            self.pts[0] = touchPoint
        }
    }
    
    override func touchesMoved(touches: Set <UITouch>, withEvent event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.locationInView(self)
            self.ctr += 1
            self.pts[self.ctr] = touchPoint
            if (self.ctr == 4) {
                self.pts[3] = CGPointMake((self.pts[2].x + self.pts[4].x)/2.0, (self.pts[2].y + self.pts[4].y)/2.0)
                self.path.moveToPoint(self.pts[0])
                self.path.addCurveToPoint(self.pts[3], controlPoint1:self.pts[1], controlPoint2:self.pts[2])
                
                self.setNeedsDisplay()
                self.pts[0] = self.pts[3]
                self.pts[1] = self.pts[4]
                self.ctr = 1
            }
            
            self.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(touches: Set <UITouch>, withEvent event: UIEvent?) {
        if self.ctr == 0 {
            let touchPoint = self.pts[0]
            self.path.moveToPoint(CGPointMake(touchPoint.x-1.0,touchPoint.y))
            self.path.addLineToPoint(CGPointMake(touchPoint.x+1.0,touchPoint.y))
            self.setNeedsDisplay()
        }
        else {
            self.ctr = 0
        }
    }
    
    // MARK: - Methods for interacting with Signature View
    
    // Clear the Signature View
    func clearSignature() {
        self.path.removeAllPoints()
        self.setNeedsDisplay()
    }
    
    func finishSignature() {
        self.delegate?.completedSignatureDrawing(self)
    }
    
    // Save the Signature as an UIImage
    func getSignature(scale scale:CGFloat = 1) -> UIImage? {
        if !containsSignature {
            return nil
        }
        var bounds = self.bounds.size
        bounds.height = bounds.height - 44.0
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, scale)
        self.path.stroke()
        let signature = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return signature
    }

    func getSignatureCropped(scale scale:CGFloat = 1) -> UIImage? {
        guard let fullRender = getSignature(scale:scale) else {
            return nil
        }
        let bounds = scaleRect(path.bounds.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2), byFactor: scale)
        guard let imageRef = CGImageCreateWithImageInRect(fullRender.CGImage, bounds) else {
            return nil
        }
        return UIImage(CGImage: imageRef)
    }
    
    func scaleRect(rect: CGRect, byFactor factor: CGFloat) -> CGRect {
        var scaledRect = rect
        scaledRect.origin.x *= factor
        scaledRect.origin.y *= factor
        scaledRect.size.width *= factor
        scaledRect.size.height *= factor
        return scaledRect
    }
}
