//
//  PDFFormFieldSignature.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

open class PDFFormSignatureField: PDFFormField {

    open var name: String?
    
    fileprivate var signatureView: PDFFormFieldSignatureCaptureView?
    fileprivate let signatureExtraPadding: CGFloat = 22.0
    
    lazy fileprivate var signButton:UIButton = {
        
        var button = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        button.setTitle("Tap To Sign", for: UIControlState())
        button.tintColor = UIColor.black
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        button.setTitleColor(UIColor.black, for: UIControlState())
        button.addTarget(self, action: #selector(PDFFormSignatureField.addSignature), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.isExclusiveTouch = true
        return button
    }()
    
    lazy fileprivate var signImage:UIImageView = {
        var image = UIImageView(frame: CGRect(
            x: 0,
            y: -self.signatureExtraPadding,
            width: self.frame.width,
            height: self.frame.height + self.signatureExtraPadding * 2
            )
        )
        image.contentMode = .scaleAspectFit
        image.backgroundColor = UIColor.clear
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.7)
        
        self.addSubview(self.signImage)
        self.addSubview(self.signButton)
        
        self.bringSubview(toFront: self.signButton)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didSetValue(_ value: AnyObject?) {
        if let value = value as? UIImage {
            self.signImage.image = value
        }
    }
    
    func addSignature() {
        let bounds = UIScreen.main.bounds
        let width = bounds.width
        let height = width / self.frame.width * self.frame.height + 44.0 + signatureExtraPadding * 2
        
        if let window = UIApplication.shared.keyWindow {
            let signatureView = PDFFormFieldSignatureCaptureView(frame: CGRect(
                x: (bounds.width - width) / 2, y: bounds.height - height, width: width, height: height))
            signatureView.delegate = self
            signatureView.layer.shadowColor = UIColor.black.cgColor
            signatureView.layer.shadowOpacity = 0.4
            signatureView.layer.shadowRadius = 3.0
            signatureView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
            window.addSubview(signatureView)
            self.signatureView = signatureView
        }
    }
    
    override func renderInContext(_ context: CGContext) {
        
        var frame = self.frame
        frame.origin.y -= signatureExtraPadding
        frame.size.height += signatureExtraPadding * 2

        self.signImage.image?.draw(in: frame)
    }
}

extension PDFFormSignatureField: PDFFormSignatureViewDelegate {
    
    func completedSignatureDrawing(_ field:PDFFormFieldSignatureCaptureView) {
        self.signImage.image = field.getSignature()
        self.signatureView?.removeFromSuperview()
        self.signatureView = nil
        self.signButton.alpha = 0.0

        self.value = field.getSignature()
        self.delegate?.formFieldValueChanged(self)
    }
}

protocol PDFFormSignatureViewDelegate {
    func completedSignatureDrawing(_ field: PDFFormFieldSignatureCaptureView)
}

class PDFFormFieldSignatureCaptureView: UIView {
    
    var delegate: PDFFormSignatureViewDelegate?
    
    // MARK: - Public properties
    var strokeWidth: CGFloat = 2.0 {
        didSet {
            self.path.lineWidth = strokeWidth
        }
    }
    
    var strokeColor: UIColor = UIColor.black {
        didSet {
            self.strokeColor.setStroke()
        }
    }
    
    var signatureBackgroundColor: UIColor = UIColor.white {
        didSet {
            self.backgroundColor = signatureBackgroundColor
        }
    }
    
    var containsSignature: Bool {
        get {
            if self.path.isEmpty {
                return false
            }
            else {
                return true
            }
        }
    }
    
    // MARK: - Private properties
    fileprivate var path = UIBezierPath()
    fileprivate var pts = [CGPoint](repeating: CGPoint(), count: 5)
    fileprivate var ctr = 0

    
    lazy fileprivate var doneButton:UIBarButtonItem = UIBarButtonItem(
        title: "Done",
        style: .plain,
        target: self,
        action: #selector(PDFFormFieldSignatureCaptureView.finishSignature)
    )

    lazy fileprivate var clearButton:UIBarButtonItem = UIBarButtonItem(
        title: "Clear",
        style: .plain,
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
        self.path.lineJoinStyle = CGLineJoin.round
        
        let spacerStart = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        spacerStart.width = 10.0
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let spacerEnd = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        spacerEnd.width = 10.0
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: self.frame.height - 44.0, width: self.frame.width, height: 44.0))
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        toolbar.setItems([spacerStart, clearButton, spacer, doneButton, spacerEnd], animated: false)
        self.addSubview(toolbar)
    }
    
    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        self.strokeColor.setStroke()
        self.path.stroke()
    }
    
    // MARK: - Touch handling functions
    override func touchesBegan(_ touches: Set <UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.location(in: self)
            self.ctr = 0
            self.pts[0] = touchPoint
        }
    }
    
    override func touchesMoved(_ touches: Set <UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.location(in: self)
            self.ctr += 1
            self.pts[self.ctr] = touchPoint
            if (self.ctr == 4) {
                self.pts[3] = CGPoint(x: (self.pts[2].x + self.pts[4].x)/2.0, y: (self.pts[2].y + self.pts[4].y)/2.0)
                self.path.move(to: self.pts[0])
                self.path.addCurve(to: self.pts[3], controlPoint1:self.pts[1], controlPoint2:self.pts[2])
                
                self.setNeedsDisplay()
                self.pts[0] = self.pts[3]
                self.pts[1] = self.pts[4]
                self.ctr = 1
            }
            
            self.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set <UITouch>, with event: UIEvent?) {
        if self.ctr == 0 {
            let touchPoint = self.pts[0]
            self.path.move(to: CGPoint(x: touchPoint.x-1.0,y: touchPoint.y))
            self.path.addLine(to: CGPoint(x: touchPoint.x+1.0,y: touchPoint.y))
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
    func getSignature(scale:CGFloat = 1) -> UIImage? {
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

    func getSignatureCropped(scale:CGFloat = 1) -> UIImage? {
        guard let fullRender = getSignature(scale:scale) else {
            return nil
        }
        let bounds = scaleRect(path.bounds.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2), byFactor: scale)
        guard let imageRef = fullRender.cgImage?.cropping(to: bounds) else {
            return nil
        }
        return UIImage(cgImage: imageRef)
    }
    
    func scaleRect(_ rect: CGRect, byFactor factor: CGFloat) -> CGRect {
        var scaledRect = rect
        scaledRect.origin.x *= factor
        scaledRect.origin.y *= factor
        scaledRect.size.width *= factor
        scaledRect.size.height *= factor
        return scaledRect
    }
}
