//
//  PDFFormField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

protocol PDFFormViewDelegate {
    
    func widgetAnnotationValueChanged(widget: PDFFormField)
    func widgetAnnotationEntered(widget: PDFFormField)
    func widgetAnnotationOptionsChanged(widget: PDFFormField)
}

public class PDFFormField: UIView {
    
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
    
    var delegate:PDFFormViewDelegate?
    
    override init(frame: CGRect) {
        self.baseFrame = frame
        super.init(frame: frame)
    }
    
    convenience init(rect: CGRect, value: String) {
        
        self.init(frame: rect)
        
        self.value = value
    }
    
//    convenience init(dictionary:PDFDictionary) {
//        
//        var value = dictionary["V"]
//        var type = dictionary["FT"]
//    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refresh() {
        self.setNeedsDisplay()
    }
}