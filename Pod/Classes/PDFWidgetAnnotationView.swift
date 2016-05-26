//
//  PDFWidgetAnnotationView.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

protocol PDFWidgetAnnotationViewDelegate {
    
    func widgetAnnotationValueChanged(widget: PDFWidgetAnnotationView)
    func widgetAnnotationEntered(widget: PDFWidgetAnnotationView)
    func widgetAnnotationOptionsChanged(widget: PDFWidgetAnnotationView)
}

public class PDFWidgetAnnotationView: UIView {
    
    var zoomScale:CGFloat = 1.0 {
        didSet {
            self.frame = CGRectMake(self.baseFrame.origin.x * zoomScale,
                                    self.baseFrame.origin.y * zoomScale,
                                    self.baseFrame.size.width * zoomScale,
                                    self.baseFrame.size.height * zoomScale)
        }
    }
    var value:String = ""
    var options:[AnyObject] = []
    var baseFrame:CGRect
    
    var delegate:PDFWidgetAnnotationViewDelegate?
    
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
}