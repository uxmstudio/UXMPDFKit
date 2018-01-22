//
//  UXMFormField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

protocol UXMFormViewDelegate : class {
    func formFieldValueChanged(_ widget: UXMFormField)
    func formFieldEntered(_ widget: UXMFormField)
    func formFieldOptionsChanged(_ widget: UXMFormField)
}

open class UXMFormFieldObject {
    var value: AnyObject?
    var options: UXMFormViewOptions?
    
    let dict: UXMDictionary
    
    init(dict: UXMDictionary) {
        self.dict = dict
        
        guard let type = dict["FT"] as? String else {
            return
        }
        guard let rect = dict.arrayForKey("Rect")?.rect else {
            return
        }
        
        let flags: [UXMFormFlag]
        if let flagsObj = dict["Ff"] as? NSNumber {
            flags = self.determineFlags(UInt(truncating: flagsObj))
        }
        else {
            flags = []
        }
        
        let export = self.determineExportValue(dict)
        let name = dict.stringForKey("T") ?? ""

        options = UXMFormViewOptions(
            type: type,
            rect: rect,
            flags: flags,
            name: name,
            exportValue: export,
            options: []
        )
    }

    func createFormField() -> UXMFormField? {
        if let options = self.options {
            if options.type == "Btn" {
                return self.createButtonField(options)
            }
            else if options.type == "Tx" {
                return self.createTextField(options)
            }
            else if options.type == "Sig" {
                return self.createSignatureField(options)
            }
        }
        return nil
    }
    
    func determineFlags(_ flags: UInt) -> [UXMFormFlag] {
        var flagsArr: [UXMFormFlag] = []
        if ((flags & UXMFormFlag.ReadOnly.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.ReadOnly)
        }
        if ((flags & UXMFormFlag.Required.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.Required)
        }
        if ((flags & UXMFormFlag.NoExport.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.NoExport)
        }
        if ((flags & UXMFormFlag.ButtonNoToggleToOff.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.ButtonNoToggleToOff)
        }
        if ((flags & UXMFormFlag.ButtonRadio.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.ButtonRadio)
        }
        if ((flags & UXMFormFlag.ButtonPushButton.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.ButtonPushButton)
        }
        if ((flags & UXMFormFlag.TextFieldMultiline.rawValue) > 0) {
            flagsArr.append(UXMFormFlag.TextFieldMultiline)
        }
        return flagsArr
    }
    
    func determineExportValue(_ dict: UXMDictionary) -> String {
        if let apObj = dict["AP"] as? UXMDictionary {
            if let nObj = apObj["N"] as? UXMDictionary {
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
    
    func createTextField(_ options: UXMFormViewOptions) -> UXMFormField {
        let multiline = options.flags?.contains(UXMFormFlag.TextFieldMultiline) ?? false
        let field = UXMFormTextField(frame: options.rect, multiline: multiline, alignment: NSTextAlignment.left)
        field.delegate = self
        if let value = self.value {
            field.value = value
        }
        return field
    }
    
    func createButtonField(_ options: UXMFormViewOptions) -> UXMFormField {
        let radio = options.flags?.contains(where: { $0 == UXMFormFlag.ButtonRadio }) ?? false
        let field = UXMFormButtonField(frame: options.rect, radio: radio)
        field.name = options.name
        field.exportValue = options.exportValue
        field.delegate = self
        if let value = self.value {
            field.value = value
        }
        
        return field
    }
    
    func createSignatureField(_ options: UXMFormViewOptions) -> UXMFormField {
        let field = UXMFormSignatureField(frame: options.rect)
        field.delegate = self
        if let value = self.value {
            field.value = value
        }
        return field
    }
}

extension UXMFormFieldObject: UXMFormViewDelegate {
    func formFieldValueChanged(_ widget: UXMFormField) {
        self.value = widget.value
    }
    
    func formFieldEntered(_ widget: UXMFormField) { }
    
    func formFieldOptionsChanged(_ widget: UXMFormField) { }
}

open class UXMFormField: UIView {
    var zoomScale: CGFloat = 1.0
    var options: [AnyObject] = []
    var baseFrame: CGRect
    var value: AnyObject? {
        didSet {
            self.didSetValue(value)
        }
    }
    
    weak var delegate: UXMFormViewDelegate?
    
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
