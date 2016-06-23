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
    
    lazy var attributes:[String:AnyObject] = {
        
        var context = PDFObjectParserContext(
            keys: []
        )
        CGPDFDictionaryApplyFunction(self.dict, self.getDictionaryObjects, &context)
        
        self.keys = context.keys
        for key in self.keys {
            if let stringKey = String.fromCString(key) {
                self.stringKeys.append(stringKey)
            }
        }

        var attributes:[String:AnyObject] = [:]
        for key in self.keys {
            if let stringKey = String.fromCString(key) {
                if let obj = self.pdfObjectForKey(key) {
                    attributes[stringKey] = obj
                }
            }
        }
        return attributes
    }()
    
    var keys:[UnsafePointer<Int8>] = []
    var stringKeys:[String] = []
    
    var isParent:Bool = false
    
    init(dictionaryRef: CGPDFDictionaryRef) {
        
        self.dict = dictionaryRef

        super.init()
        
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
    
    func stringForKey(key: String) -> String? {
        return attributes[key] as? String
    }
    
    func allKeys() -> [String] {
        return stringKeys
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? PDFDictionary {
            
            let rect1 = self.arrayForKey("Rect")?.rect()
            let rect2 = object.arrayForKey("Rect")?.rect()
            
            let keys1 = self.allKeys()
            let keys2 = object.allKeys()
            
            let t1 = self["T"] as? String
            let t2 = object["T"] as? String
            
            return rect1 == rect2 && keys1 == keys2 && t1 == t2
        }
        return false
    }
    
    
    private func booleanFromKey(key: UnsafePointer<Int8>) -> Bool? {
        var boolObj:CGPDFBoolean = 0
        if CGPDFDictionaryGetBoolean(self.dict, key, &boolObj) {
            return Bool(Int(boolObj))
        }
        return nil
    }
    
    private func integerFromKey(key: UnsafePointer<Int8>) -> Int? {
        var intObj:CGPDFInteger = 0
        if CGPDFDictionaryGetInteger(self.dict, key, &intObj) {
            return Int(intObj)
        }
        return nil
    }
    
    private func realFromKey(key: UnsafePointer<Int8>) -> CGFloat? {
        var floatObj:CGPDFReal = 0
        if CGPDFDictionaryGetNumber(self.dict, key, &floatObj) {
            return CGFloat(floatObj)
        }
        return nil
    }
    
    private func nameFromKey(key: UnsafePointer<Int8>) -> String? {
        var nameObj:UnsafePointer<Int8> = nil
        if CGPDFDictionaryGetName(self.dict, key, &nameObj) {
            if let dictionaryName = String.fromCString(nameObj) {
                return dictionaryName
            }
        }
        return nil
    }
    
    private func stringFromKey(key: UnsafePointer<Int8>) -> String? {
        var stringObj:CGPDFStringRef = nil
        if CGPDFDictionaryGetString(self.dict, key, &stringObj) {
            if let ref:CFStringRef = CGPDFStringCopyTextString(stringObj) {
                return ref as String
            }
        }
        return nil
    }
    
    private func arrayFromKey(key: UnsafePointer<Int8>) -> PDFArray? {
        var arrayObj:CGPDFArrayRef = nil
        if CGPDFDictionaryGetArray(self.dict, key, &arrayObj) {
            return PDFArray(arrayRef: arrayObj)
        }
        return nil
    }
    
    private func dictionaryFromKey(key: UnsafePointer<Int8>) -> PDFDictionary? {
        
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
    
    private func streamFromKey(key: UnsafePointer<Int8>) -> PDFDictionary? {
        
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
        
        let context = UnsafeMutablePointer<PDFObjectParserContext>(info).memory
        context.keys.append(key)
    }
    
    func description(level: Int = 0) -> String {
        var spacer = ""
        for _ in 0..<(level*2) { spacer += " " }
        
        var string = "\n\(spacer){\n"
        for (key, value) in attributes {
            if let value = value as? PDFDictionary {
                string += "\(spacer)\(key) : \(value.description(level+1))"
            }
            else {
                string += "\(spacer)\(key) : \(value)\n"
            }
        }
        string += "\(spacer)}\n"
        return string
    }
    
    override var description: String {
        return description(0)
    }
}