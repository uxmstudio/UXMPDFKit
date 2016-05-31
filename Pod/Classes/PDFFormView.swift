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
    var flags:String
    var uname:String?
    var rect:CGRect
    var options:[String]?
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
        var newWidth = self.baseFrame.width * zoomScale
        var left = (newWidth - self.baseFrame.width) / 2
        self.frame = CGRectMake(self.baseFrame.origin.x - left, 0, newWidth, self.baseFrame.height * zoomScale)
        for field in fields {
            field.zoomScale = zoomScale
        }
    }
    
    func adjustFrame(field: PDFFormField) {
        
        var offsetX = (self.frame.width - boundingBox.width) / 2
        var factor = boundingBox.width / cropBox.width
        var zoomLevel = 1 / self.zoomScale
        var correctedFrame = CGRectMake(
            (field.frame.origin.x - cropBox.origin.x) * factor + offsetX,
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
        
        guard let type = dictionary["FT"] as? String else {
            return
        }
        guard let rect = dictionary.arrayForKey("Rect")?.rect() else {
            return
        }
        
        print(rect)
        
        var flags = dictionary["Ff"]
        var uname = dictionary["TU"] as? String
        
        var options = PDFFormViewOptions(type: type, flags: "", uname: uname, rect: rect, options: [])
        
        if type == "Btn" {
            //fields.append(self.createButtonField(options))
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
    
    func createTextField(options: PDFFormViewOptions) -> PDFFormField {
        
        return PDFFormTextField(frame: options.rect, multiline: false, alignment: NSTextAlignment.Left)
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
