//
//  PDFDictionary.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import UIKit

protocol PDFObject {
    
    func type() -> CGPDFObjectType
}

class PDFDictionary:NSObject, PDFObject {

    var dict:CGPDFDictionaryRef
    var attributes:[String:AnyObject] = [:]
    
    init(dictionaryRef: CGPDFDictionaryRef) {
        
        self.dict = dictionaryRef
        super.init()
        
        var context = PDFObjectParserContext(
            dictionaryRef: self.dict,
            info: UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()),
            attributes: self.attributes
        )
        
        CGPDFDictionaryApplyFunction(dictionaryRef, getDictionaryObjects, &context)
        
        self.attributes = context.attributes
    }
    
    subscript(key: String) -> AnyObject? {
        return attributes[key]
    }
    
    func type() -> CGPDFObjectType {
        return CGPDFObjectType.Dictionary
    }
    
    func arrayForKey(key: String) -> PDFArray? {
        return attributes[key] as? PDFArray
    }
    
    func allKeys() -> [String] {
        return Array(attributes.keys)
    }
    
    func booleanFromKey(key: UnsafePointer<Int8>) -> Bool? {
        var boolObj:CGPDFBoolean = 0
        if CGPDFDictionaryGetBoolean(self.dict, key, &boolObj) {
            return Bool(Int(boolObj))
        }
        return nil
    }
    
    func integerFromKey(key: UnsafePointer<Int8>) -> Int? {
        var intObj:CGPDFInteger = 0
        if CGPDFDictionaryGetInteger(self.dict, key, &intObj) {
            return Int(intObj)
        }
        return nil
    }
    
    func realFromKey(key: UnsafePointer<Int8>) -> CGFloat? {
        var floatObj:CGPDFReal = 0
        if CGPDFDictionaryGetNumber(self.dict, key, &floatObj) {
            return CGFloat(floatObj)
        }
        return nil
    }
    
    func nameFromKey(key: UnsafePointer<Int8>) -> String? {
        var nameObj:UnsafePointer<Int8> = nil
        if CGPDFDictionaryGetName(self.dict, key, &nameObj) {
            if let dictionaryName = String.fromCString(nameObj) {
                print(dictionaryName)
                return dictionaryName
            }
        }
        return nil
    }
    
    func stringFromKey(key: UnsafePointer<Int8>) -> String? {
        var stringObj:CGPDFStringRef = nil
        if CGPDFDictionaryGetString(self.dict, key, &stringObj) {
            if let ref:CFStringRef = CGPDFStringCopyTextString(stringObj) {
                return ref as String
            }
        }
        return nil
    }
    
    func arrayFromKey(key: UnsafePointer<Int8>) -> PDFArray? {
        var arrayObj:CGPDFArrayRef = nil
        if CGPDFDictionaryGetArray(self.dict, key, &arrayObj) {
            return PDFArray(arrayRef: arrayObj)
        }
        return nil
    }
    
    func dictionaryFromKey(key: UnsafePointer<Int8>) -> PDFDictionary? {
        
        guard let stringKey = String.fromCString(key) else {
            return nil
        }
        if stringKey == "Parent" || stringKey == "P" {
            return nil
        }
        
        var dictObj:CGPDFArrayRef = nil
        if CGPDFDictionaryGetDictionary(self.dict, key, &dictObj) {
            return PDFDictionary(dictionaryRef: dictObj)
        }
        return nil
    }
    
    func streamFromKey(key: UnsafePointer<Int8>) -> PDFDictionary? {
        
        guard let stringKey = String.fromCString(key) else {
            return nil
        }
        if stringKey == "Parent" || stringKey == "P" {
            return nil
        }
        
        var streamObj:CGPDFArrayRef = nil
        if CGPDFDictionaryGetStream(self.dict, key, &streamObj) {
            let dictObj = CGPDFStreamGetDictionary(streamObj)
            return PDFDictionary(dictionaryRef: dictObj)
        }
        return nil
    }
    
    func pdfObjectForKey(key: UnsafePointer<Int8>) -> AnyObject? {
        
        var object:CGPDFObjectRef = nil
        if CGPDFDictionaryGetObject(self.dict, key, &object) {
            
            let type = CGPDFObjectGetType(object)
            switch type {
            case CGPDFObjectType.Boolean: return self.booleanFromKey(key)
            case CGPDFObjectType.Integer: return self.integerFromKey(key)
            case CGPDFObjectType.Real: return self.realFromKey(key)
            case CGPDFObjectType.Name: return self.nameFromKey(key)
            case CGPDFObjectType.String: return self.stringFromKey(key)
            case CGPDFObjectType.Array: return self.arrayFromKey(key)
            case CGPDFObjectType.Dictionary: return self.dictionaryFromKey(key)
            case CGPDFObjectType.Stream: return self.streamFromKey(key)
            default:
                break
            }
        }
        
        return nil
    }
    
    var getDictionaryObjects:CGPDFDictionaryApplierFunction = { (key, object, info) in
        
        guard let stringKey = String.fromCString(key) else {
            return
        }
        
        let context = UnsafeMutablePointer<PDFObjectParserContext>(info).memory
        let contentDict:CGPDFDictionaryRef = context.dictionaryRef
        let objSelf = Unmanaged<PDFDictionary>.fromOpaque(COpaquePointer(context.info)).takeUnretainedValue()
        let type:CGPDFObjectType = CGPDFObjectGetType(object)
        
        if let obj = objSelf.pdfObjectForKey(key) {
            context.attributes[stringKey] = obj
        }
    }
}