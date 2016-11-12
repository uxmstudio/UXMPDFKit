//
//  PDFFormField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

protocol PDFFormViewDelegate {
    func formFieldValueChanged(_ widget: PDFFormField)
    func formFieldEntered(_ widget: PDFFormField)
    func formFieldOptionsChanged(_ widget: PDFFormField)
}

open class PDFFormFieldObject {
    var value: AnyObject?
    var options: PDFFormViewOptions?
    
    let dict: PDFDictionary
    
    init(dict: PDFDictionary) {
        self.dict = dict
        
        guard let type = dict["FT"] as? String else {
            return
        }
        guard let rect = dict.arrayForKey("Rect")?.rect else {
            return
        }
        
        let flags: [PDFFormFlag]
        if let flagsObj = dict["Ff"] as? UInt {
            flags = self.determineFlags(flagsObj)
        } else {
            flags = []
        }
        
        let export = self.determineExportValue(dict)
        let name = dict.stringForKey("T") ?? ""
        
        options = PDFFormViewOptions(
            type: type,
            rect: rect,
            flags: flags,
            name: name,
            exportValue: export,
            options: []
        )
    }

    func createFormField() -> PDFFormField? {
        if let options = self.options {
            if options.type == "Btn" {
                return self.createButtonField(options)
            } else if options.type == "Tx" {
                return self.createTextField(options)
            } else if options.type == "Sig" {
                return self.createSignatureField(options)
            }
        }
        return nil
    }
    
    func determineFlags(_ flags: UInt) -> [PDFFormFlag] {
        var flagsArr: [PDFFormFlag] = []
        if ((flags & PDFFormFlag.ReadOnly.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.ReadOnly)
        }
        if ((flags & PDFFormFlag.Required.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.Required)
        }
        if ((flags & PDFFormFlag.NoExport.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.NoExport)
        }
        if ((flags & PDFFormFlag.ButtonNoToggleToOff.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.ButtonNoToggleToOff)
        }
        if ((flags & PDFFormFlag.ButtonRadio.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.ButtonRadio)
        }
        if ((flags & PDFFormFlag.ButtonPushButton.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.ButtonPushButton)
        }
        if ((flags & PDFFormFlag.TextFieldMultiline.rawValue) > 0) {
            flagsArr.append(PDFFormFlag.TextFieldMultiline)
        }
        return flagsArr
    }
    
    func determineExportValue(_ dict: PDFDictionary) -> String {
        if let apObj = dict["AP"] as? PDFDictionary {
            if let nObj = apObj["N"] as? PDFDictionary {
                for key in nObj.allKeys() {
                    if key == "Off" || key == "OFF" {
                        return key
                    }
                }
            }
        }
        
        if let asObj = dict["AS"] as? String {
            return asObj
        }
        return ""
    }
    
    func createTextField(_ options: PDFFormViewOptions) -> PDFFormField {
        let multiline = options.flags?.contains(PDFFormFlag.TextFieldMultiline) ?? false
        let field = PDFFormTextField(frame: options.rect, multiline: multiline, alignment: NSTextAlignment.left)
        field.delegate = self
        if let value = self.value {
            field.value = value
        }
        return field
    }
    
    func createButtonField(_ options: PDFFormViewOptions) -> PDFFormField {
        let radio = options.flags?.contains(where: { $0 == PDFFormFlag.ButtonRadio }) ?? false
        let field = PDFFormButtonField(frame: options.rect, radio: radio)
        field.name = options.name
        field.exportValue = options.exportValue
        field.delegate = self
        if let value = self.value {
            field.value = value
        }
        
        return field
    }
    
    func createSignatureField(_ options: PDFFormViewOptions) -> PDFFormField {
        let field = PDFFormSignatureField(frame: options.rect)
        field.delegate = self
        if let value = self.value {
            field.value = value
        }
        return field
    }
}

extension PDFFormFieldObject: PDFFormViewDelegate {
    func formFieldValueChanged(_ widget: PDFFormField) {
        self.value = widget.value
    }
    
    func formFieldEntered(_ widget: PDFFormField) { }
    
    func formFieldOptionsChanged(_ widget: PDFFormField) { }
}

open class PDFFormField: UIView {
    var zoomScale: CGFloat = 1.0
    var options: [AnyObject] = []
    var baseFrame: CGRect
    var value: AnyObject? {
        didSet {
            self.didSetValue(value)
        }
    }
    
    var delegate: PDFFormViewDelegate?
    
    override init(frame: CGRect) {
        self.baseFrame = frame
        super.init(frame: frame)
    }
    
    convenience init(rect: CGRect, value: String) {
        self.init(frame: rect)
        self.value = value as AnyObject?
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func refresh() {
        self.setNeedsDisplay()
    }
    
    func didSetValue(_ value: AnyObject?) { }
    
    func updateForZoomScale(_ scale: CGFloat) {
        zoomScale = scale
        let screenAndZoomScale = scale * UIScreen.main.scale
        applyScale(screenAndZoomScale, toView: self)
        applyScale(screenAndZoomScale, toLayer: self.layer)
    }
    
    func applyScale(_ scale: CGFloat, toView view:UIView) {
        view.contentScaleFactor = scale
        for subview in view.subviews {
            applyScale(scale, toView: subview)
        }
    }
    
    func applyScale(_ scale: CGFloat, toLayer layer:CALayer) {
        layer.contentsScale = scale
        
        guard let sublayers = layer.sublayers else {
            return
        }
        for sublayer in sublayers {
            applyScale(scale, toLayer: sublayer)
        }
    }
    
    func renderInContext(_ context: CGContext) {
        
    }
}
