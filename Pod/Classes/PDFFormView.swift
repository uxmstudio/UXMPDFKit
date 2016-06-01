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

public class PDFFormView:UIView {
    
    var fields:[PDFFormField] = []
    var page:Int
    var zoomScale:CGFloat = 1.0
    
    var cropBox:CGRect = CGRectZero
    var boundingBox:CGRect = CGRectZero
    var baseFrame:CGRect
    
    init(frame: CGRect, page:Int) {
        self.page = page
        self.baseFrame = frame
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSize(rect: CGRect, boundingBox:CGRect, cropBox:CGRect) {
        
        self.frame = rect
        self.baseFrame = rect
        self.cropBox = cropBox
        self.boundingBox = boundingBox
        
        for field in fields {
            self.adjustFrame(field)
        }
    }
    
    func updateWithZoom(zoomScale: CGFloat) {
        for field in fields {
            field.updateForZoomScale(zoomScale)
            field.refresh()
        }
//        var zoomLevel = 1 / self.zoomScale * zoomScale
//        if zoomLevel > 1 {
//            
//        }
//        var newWidth = self.baseFrame.width * zoomLevel
//        var left = (newWidth - self.baseFrame.width) / 2
//        self.frame = CGRectMake(self.baseFrame.origin.x - left, 0, newWidth, self.baseFrame.height * zoomLevel)
//        for field in fields {
//            field.zoomScale = zoomScale
//        }
    }
    
    func adjustFrame(field: PDFFormField) {
        
        let factor:CGFloat = 1.0
        let zoomLevel = 1 / self.zoomScale
        let correctedFrame = CGRectMake(
            (field.frame.origin.x - cropBox.origin.x) * factor,
            (cropBox.height - field.frame.origin.y - field.frame.height - self.cropBox.origin.y) * factor,
            field.frame.width * factor,
            field.frame.height * factor)
        
        field.frame = correctedFrame
        
        field.baseFrame = CGRectMake(
            correctedFrame.origin.x * zoomLevel,
            correctedFrame.origin.y * zoomLevel,
            correctedFrame.width * zoomLevel,
            correctedFrame.height * zoomLevel
        )
    }
    
    func createFormField(dictionary: PDFDictionary) {
        
        print(dictionary["T"])
        print(dictionary["TU"])
        
        guard let type = dictionary["FT"] as? String else {
            return
        }
        guard let rect = dictionary.arrayForKey("Rect")?.rect() else {
            return
        }
        
        print(rect)
        
        var flags:[PDFFormFlag] = []
        if let flagsObj = dictionary["Ff"] as? UInt {
            flags = determineFlags(flagsObj)
        }
        
        let export:String = determineExportValue(dictionary)
        let name:String = dictionary.stringForKey("T") ?? ""
        let uname:String = dictionary.stringForKey("TU") ?? ""
        
        let options = PDFFormViewOptions(
            type: type,
            rect: rect,
            flags: flags,
            name: name,
            exportValue: export,
            options: []
        )
        
        if type == "Btn" {
            self.addFormField(self.createButtonField(options))
        }
        else if type == "Tx" {
            self.addFormField(self.createTextField(options))
        }
        else if type == "Ch" {
            //fields.append(self.createChoiceField(options))
        }
        else if type == "Sig" {
            //fields.append(self.createSignatureField(options))
        }
    }
    
    func addFormField(field: PDFFormField) {
        self.fields.append(field)
        self.addSubview(field)
    }
    
    func removeFormField(field: PDFFormField) {
        field.removeFromSuperview()
    }
    
    func determineFlags(flags: UInt) -> [PDFFormFlag] {
        
        var flagsArr:[PDFFormFlag] = []
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
    
    func determineExportValue(dict: PDFDictionary) -> String {
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
    
    func createTextField(options: PDFFormViewOptions) -> PDFFormField {
        
        return PDFFormTextField(frame: options.rect, multiline: false, alignment: NSTextAlignment.Left)
    }
    
    func createButtonField(options: PDFFormViewOptions) -> PDFFormField {
        
        let radio:Bool = options.flags?.contains({ $0 == PDFFormFlag.ButtonRadio }) ?? false
        var field = PDFFormButtonField(frame: options.rect, radio: radio)
        field.name = options.name
        field.exportValue = options.exportValue
        
        return field
    }
    
    //    func createSignatureField(options: PDFFormViewOptions) -> PDFFormField {
    //
    //    }
    //
    //    func createChoiceField(options: PDFFormViewOptions) -> PDFFormField {
    //
    //    }
    //
    //    func createButtonField(options: PDFFormViewOptions) -> PDFFormField {
    //        
    //    }
}
