//
//  PDFFormView.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

struct PDFFormViewOptions {
    var type:String
    var rect:CGRect
    var flags:[PDFFormFlag]?
    var name:String = ""
    var exportValue:String = ""
    var options:[String]?
}

struct PDFFormFlag: Equatable {
    
    let rawValue: UInt
    
    static let  ReadOnly             = PDFFormFlag(rawValue:1 << 0)
    static let  Required             = PDFFormFlag(rawValue:1 << 1)
    static let  NoExport             = PDFFormFlag(rawValue:1 << 2)
    static let  TextFieldMultiline   = PDFFormFlag(rawValue:1 << 12)
    static let  TextFieldPassword    = PDFFormFlag(rawValue:1 << 13)
    static let  ButtonNoToggleToOff  = PDFFormFlag(rawValue:1 << 14)
    static let  ButtonRadio          = PDFFormFlag(rawValue:1 << 15)
    static let  ButtonPushButton     = PDFFormFlag(rawValue:1 << 16)
    static let  ChoiceFieldIsCombo   = PDFFormFlag(rawValue:1 << 17)
    static let  ChoiceFieldEditable  = PDFFormFlag(rawValue:1 << 18)
    static let  ChoiceFieldSorted    = PDFFormFlag(rawValue:1 << 19)
}

func ==(lhs: PDFFormFlag, rhs: PDFFormFlag) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public class PDFFormPage:NSObject {
    
    var fields:[PDFFormFieldObject] = []
    var page:Int
    var zoomScale:CGFloat = 1.0
    
    init(page:Int) {
        self.page = page
    }
    
    func showForm(contentView: PDFPageContentView) {
        
        let formView = PDFFormPageView(
            frame: contentView.contentView.cropBoxRect,
            boundingBox: contentView.containerView.frame,
            cropBox: contentView.contentView.cropBoxRect,
            fields: self.fields)
        
        formView.zoomScale = contentView.zoomScale
        contentView.contentView.addSubview(formView)
        contentView.viewDidZoom = { scale in
            
            formView.updateWithZoom(scale)
        }
    }

    func createFormField(dict: PDFDictionary) {
        self.fields.append(PDFFormFieldObject(dict: dict))
    }
    
    func renderInContext(context: CGContext, size: CGRect) {
        
        let formView = PDFFormPageView(
            frame: size,
            boundingBox: size,
            cropBox: size,
            fields: self.fields)
        formView.renderInContext(context)
    }
}

public class PDFFormPageView:UIView {
    
    var fields:[PDFFormFieldObject]
    var fieldViews:[PDFFormField] = []
    var zoomScale:CGFloat = 1.0
    
    var cropBox:CGRect = CGRectZero
    var boundingBox:CGRect = CGRectZero
    var baseFrame:CGRect
    
    init(frame: CGRect, boundingBox:CGRect, cropBox:CGRect, fields:[PDFFormFieldObject]) {
        self.baseFrame = frame
        self.cropBox = cropBox
        self.boundingBox = boundingBox
        self.fields = fields
        super.init(frame: frame)
        
        for field in fields {
            if let fieldView = field.createFormField() {
                self.addSubview(fieldView)
                self.adjustFrame(fieldView)
                self.fieldViews.append(fieldView)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWithZoom(zoomScale: CGFloat) {
        for field in fieldViews {
            field.updateForZoomScale(zoomScale)
            field.refresh()
        }
    }
    
    func adjustFrame(field: PDFFormField) {
        
        let factor:CGFloat = 1.0
        let correctedFrame = CGRectMake(
            (field.baseFrame.origin.x - cropBox.origin.x) * factor,
            (cropBox.height - field.baseFrame.origin.y - field.baseFrame.height - self.cropBox.origin.y) * factor,
            field.baseFrame.width * factor,
            field.baseFrame.height * factor)
        
        field.frame = correctedFrame
    }
    
    func renderInContext(context: CGContext) {
        
        for field in fieldViews {
            field.renderInContext(context)
        }
    }
}
