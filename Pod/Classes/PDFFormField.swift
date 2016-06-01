//
//  PDFFormField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

protocol PDFFormViewDelegate {
    
    func formFieldValueChanged(widget: PDFFormField)
    func formFieldEntered(widget: PDFFormField)
    func formFieldOptionsChanged(widget: PDFFormField)
}

public class PDFFormField: UIView {
    
    var zoomScale:CGFloat = 1.0
    var value:String = ""
    var options:[AnyObject] = []
    var baseFrame:CGRect
    
    var delegate:PDFFormViewDelegate?
    
    override init(frame: CGRect) {
        self.baseFrame = frame
        super.init(frame: frame)
    }
    
    convenience init(rect: CGRect, value: String) {
        
        self.init(frame: rect)
        self.value = value
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refresh() {
        self.setNeedsDisplay()
    }
    
    func updateForZoomScale(scale: CGFloat) {
        self.zoomScale = scale
        let screenAndZoomScale = scale * UIScreen.mainScreen().scale
        self.applyScale(screenAndZoomScale, toView: self)
        self.applyScale(screenAndZoomScale, toLayer: self.layer)
    }
    
    func applyScale(scale: CGFloat, toView view:UIView) {
        view.contentScaleFactor = scale
        for subview in view.subviews {
            self.applyScale(scale, toView: subview)
        }
    }
    
    func applyScale(scale: CGFloat, toLayer layer:CALayer) {
        layer.contentsScale = scale
        
        guard let sublayers = layer.sublayers else {
            return
        }
        for sublayer in sublayers {
            self.applyScale(scale, toLayer: sublayer)
        }
    }
}