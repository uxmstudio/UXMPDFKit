//
//  PDFFormView.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

struct PDFFormViewOptions {
    var type: String
    var rect: CGRect
    var flags: [PDFFormFlag]?
    var name: String = ""
    var exportValue: String = ""
    var options: [String]?
}

struct PDFFormFlag: Equatable {
    let rawValue: UInt
    
    static let ReadOnly             = PDFFormFlag(rawValue:1 << 0)
    static let Required             = PDFFormFlag(rawValue:1 << 1)
    static let NoExport             = PDFFormFlag(rawValue:1 << 2)
    static let TextFieldMultiline   = PDFFormFlag(rawValue:1 << 12)
    static let TextFieldPassword    = PDFFormFlag(rawValue:1 << 13)
    static let ButtonNoToggleToOff  = PDFFormFlag(rawValue:1 << 14)
    static let ButtonRadio          = PDFFormFlag(rawValue:1 << 15)
    static let ButtonPushButton     = PDFFormFlag(rawValue:1 << 16)
    static let ChoiceFieldIsCombo   = PDFFormFlag(rawValue:1 << 17)
    static let ChoiceFieldEditable  = PDFFormFlag(rawValue:1 << 18)
    static let ChoiceFieldSorted    = PDFFormFlag(rawValue:1 << 19)
}

func ==(lhs: PDFFormFlag, rhs: PDFFormFlag) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

open class PDFFormPage: NSObject {
    var fields: [PDFFormFieldObject] = []
    var page: Int
    var zoomScale: CGFloat = 1.0
    
    init(page: Int) {
        self.page = page
    }
    
    func showForm(_ contentView: PDFPageContentView) {
        let formView = PDFFormPageView(
            frame: contentView.contentView.cropBoxRect,
            boundingBox: contentView.containerView.frame,
            cropBox: contentView.contentView.cropBoxRect,
            fields: self.fields)
        
        formView.zoomScale = contentView.zoomScale
        if contentView.contentView.subviews.filter({ $0 is PDFFormPageView }).count <= 0 {
            contentView.contentView.addSubview(formView)
        }
        contentView.viewDidZoom = { scale in
            formView.updateWithZoom(scale)
        }
    }
    
    func createFormField(_ dict: PDFDictionary) {
        fields.append(PDFFormFieldObject(dict: dict))
    }
    
    func renderInContext(_ context: CGContext, size: CGRect) {
        let formView = PDFFormPageView(
            frame: size,
            boundingBox: size,
            cropBox: size,
            fields: self.fields)
        formView.renderInContext(context)
    }
}

open class PDFFormPageView: UIView {
    var fields: [PDFFormFieldObject]
    var fieldViews: [PDFFormField] = []
    var zoomScale: CGFloat = 1.0
    
    var cropBox = CGRect.zero
    var boundingBox = CGRect.zero
    var baseFrame: CGRect
    
    init(frame: CGRect, boundingBox: CGRect, cropBox: CGRect, fields: [PDFFormFieldObject]) {
        self.baseFrame = frame
        self.cropBox = cropBox
        self.boundingBox = boundingBox
        self.fields = fields
        super.init(frame: frame)
        
        for field in fields {
            if let fieldView = field.createFormField() {
                addSubview(fieldView)
                adjustFrame(fieldView)
                fieldViews.append(fieldView)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWithZoom(_ zoomScale: CGFloat) {
        for field in fieldViews {
            field.updateForZoomScale(zoomScale)
            field.refresh()
        }
    }
    
    func adjustFrame(_ field: PDFFormField) {
        let factor: CGFloat = 1.0
        let correctedFrame = CGRect(
            x: (field.baseFrame.origin.x - cropBox.origin.x) * factor,
            y: (cropBox.height - field.baseFrame.origin.y - field.baseFrame.height - cropBox.origin.y) * factor,
            width: field.baseFrame.width * factor,
            height: field.baseFrame.height * factor)
        
        field.frame = correctedFrame
    }
    
    func renderInContext(_ context: CGContext) {
        for field in fieldViews {
            field.renderInContext(context)
        }
    }
}
