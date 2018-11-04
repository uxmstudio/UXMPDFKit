//
//  PDFFormView.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

struct UXMFormViewOptions {
    var type: String
    var rect: CGRect
    var flags: [UXMFormFlag]?
    var name: String = ""
    var exportValue: String = ""
    var options: [String]?
}

struct UXMFormFlag: Equatable {
    let rawValue: UInt
    
    static let ReadOnly             = UXMFormFlag(rawValue:1 << 0)
    static let Required             = UXMFormFlag(rawValue:1 << 1)
    static let NoExport             = UXMFormFlag(rawValue:1 << 2)
    static let TextFieldMultiline   = UXMFormFlag(rawValue:1 << 12)
    static let TextFieldPassword    = UXMFormFlag(rawValue:1 << 13)
    static let ButtonNoToggleToOff  = UXMFormFlag(rawValue:1 << 14)
    static let ButtonRadio          = UXMFormFlag(rawValue:1 << 15)
    static let ButtonPushButton     = UXMFormFlag(rawValue:1 << 16)
    static let ChoiceFieldIsCombo   = UXMFormFlag(rawValue:1 << 17)
    static let ChoiceFieldEditable  = UXMFormFlag(rawValue:1 << 18)
    static let ChoiceFieldSorted    = UXMFormFlag(rawValue:1 << 19)
}

func ==(lhs: UXMFormFlag, rhs: UXMFormFlag) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

open class UXMFormPage: NSObject {
    let page: Int
    var fields: [UXMFormFieldObject] = []
    let zoomScale: CGFloat = 1.0
    
    init(page: Int) {
        self.page = page
    }
    
    func showForm(_ contentView: UXMPageContentView) {
        let formView = UXMFormPageView(
            frame: contentView.contentView.cropBoxRect,
            boundingBox: contentView.containerView.frame,
            cropBox: contentView.contentView.cropBoxRect,
            fields: self.fields)
        
        formView.zoomScale = contentView.zoomScale
        if contentView.contentView.subviews.filter({ $0 is UXMFormPageView }).count <= 0 {
            contentView.contentView.addSubview(formView)
        }
        contentView.viewDidZoom = { scale in
            formView.updateWithZoom(scale)
        }
        contentView.sendSubviewToBack(formView)
    }
    
    func createFormField(_ dict: UXMDictionary) {
        fields.append(UXMFormFieldObject(dict: dict))
    }
    
    func renderInContext(_ context: CGContext, size: CGRect) {
        let formView = UXMFormPageView(
            frame: size,
            boundingBox: size,
            cropBox: size,
            fields: self.fields)
        formView.renderInContext(context)
    }
}

open class UXMFormPageView: UIView {
    var fields: [UXMFormFieldObject]
    var fieldViews: [UXMFormField] = []
    var zoomScale: CGFloat = 1.0
    
    let cropBox: CGRect
    let boundingBox: CGRect
    let baseFrame: CGRect
    
    init(frame: CGRect, boundingBox: CGRect, cropBox: CGRect, fields: [UXMFormFieldObject]) {
        self.baseFrame = frame
        self.cropBox = cropBox
        self.boundingBox = boundingBox
        self.fields = fields
        super.init(frame: frame)
        
        for field in fields {
            guard let fieldView = field.createFormField() else { continue }
            addSubview(fieldView)
            adjustFrame(fieldView)
            fieldViews.append(fieldView)
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
    
    func adjustFrame(_ field: UXMFormField) {
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
