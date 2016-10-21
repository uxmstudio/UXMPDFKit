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
    
    var dict: CGPDFDictionaryRef
    
    lazy var attributes: [String:AnyObject] = {
        
        var context = PDFObjectParserContext(
            keys: []
        )
        CGPDFDictionaryApplyFunction(self.dict, self.getDictionaryObjects, &context)
        
        self.keys = context.keys
        for key in self.keys {
            if let stringKey = String(validatingUTF8: key) {
                self.stringKeys.append(stringKey)
            }
        }

        var attributes: [String:AnyObject] = [:]
        for key in self.keys {
            if let stringKey = String(validatingUTF8: key) {
                if let obj = self.pdfObjectForKey(key) {
                    attributes[stringKey] = obj
                }
            }
        }
        return attributes
    }()
    
    var keys: [UnsafePointer<Int8>] = []
    var stringKeys: [String] = []
    
    var isParent: Bool = false
    
    init(dictionaryRef: CGPDFDictionaryRef) {
        
        self.dict = dictionaryRef

        super.init()
        
    }
    
    subscript(key: String) -> AnyObject? {
        return attributes[key]
    }
    
    func type() -> CGPDFObjectType {
        return CGPDFObjectType.dictionary
    }
    
    func arrayForKey(_ key: String) -> PDFArray? {
        return attributes[key] as? PDFArray
    }
    
    func stringForKey(_ key: String) -> String? {
        return attributes[key] as? String
    }
    
    func allKeys() -> [String] {
        return stringKeys
    }
    
    override func isEqual(_ object: Any?) -> Bool {
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
    
    
    fileprivate func booleanFromKey(_ key: UnsafePointer<Int8>) -> Bool? {
        var boolObj: CGPDFBoolean = 0
        if CGPDFDictionaryGetBoolean(self.dict, key, &boolObj) {
            return Int(boolObj) != 0
        }
        return nil
    }
    
    fileprivate func integerFromKey(_ key: UnsafePointer<Int8>) -> Int? {
        var intObj: CGPDFInteger = 0
        if CGPDFDictionaryGetInteger(self.dict, key, &intObj) {
            return Int(intObj)
        }
        return nil
    }
    
    fileprivate func realFromKey(_ key: UnsafePointer<Int8>) -> CGFloat? {
        var floatObj: CGPDFReal = 0
        if CGPDFDictionaryGetNumber(self.dict, key, &floatObj) {
            return CGFloat(floatObj)
        }
        return nil
    }
    
    fileprivate func nameFromKey(_ key: UnsafePointer<Int8>) -> String? {
        var nameObj: UnsafePointer<Int8>? = nil
        if CGPDFDictionaryGetName(self.dict, key, &nameObj) {
            if let dictionaryName = String(validatingUTF8: nameObj!) {
                return dictionaryName
            }
        }
        return nil
    }
    
    fileprivate func stringFromKey(_ key: UnsafePointer<Int8>) -> String? {
        var stringObj: CGPDFStringRef? = nil
        if CGPDFDictionaryGetString(self.dict, key, &stringObj) {
            if let ref: CFString = CGPDFStringCopyTextString(stringObj!) {
                return ref as String
            }
        }
        return nil
    }
    
    fileprivate func arrayFromKey(_ key: UnsafePointer<Int8>) -> PDFArray? {
        var arrayObj: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(self.dict, key, &arrayObj) {
            return PDFArray(arrayRef: arrayObj!)
        }
        return nil
    }
    
    fileprivate func dictionaryFromKey(_ key: UnsafePointer<Int8>) -> PDFDictionary? {
        
        guard let stringKey = String(validatingUTF8: key) else {
            return nil
        }
        
        if stringKey == "Parent" || stringKey == "P" {
            return nil
        }
        
        var dictObj: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetDictionary(self.dict, key, &dictObj) {
            return PDFDictionary(dictionaryRef: dictObj!)
        }
        return nil
    }
    
    fileprivate func streamFromKey(_ key: UnsafePointer<Int8>) -> PDFDictionary? {
        
        guard let stringKey = String(validatingUTF8: key) else {
            return nil
        }
        
        if stringKey == "Parent" || stringKey == "P" {
            return nil
        }
        
        var streamObj: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetStream(self.dict, key, &streamObj) {
            let dictObj = CGPDFStreamGetDictionary(streamObj!)
            return PDFDictionary(dictionaryRef: dictObj!)
        }
        return nil
    }
    
    func pdfObjectForKey(_ key: UnsafePointer<Int8>) -> AnyObject? {
        
        var object: CGPDFObjectRef? = nil
        if CGPDFDictionaryGetObject(self.dict, key, &object) {
            
            let type = CGPDFObjectGetType(object!)
            switch type {
            case CGPDFObjectType.boolean: return self.booleanFromKey(key) as AnyObject?
            case CGPDFObjectType.integer: return self.integerFromKey(key) as AnyObject?
            case CGPDFObjectType.real: return self.realFromKey(key) as AnyObject?
            case CGPDFObjectType.name: return self.nameFromKey(key) as AnyObject?
            case CGPDFObjectType.string: return self.stringFromKey(key) as AnyObject?
            case CGPDFObjectType.array: return self.arrayFromKey(key)
            case CGPDFObjectType.dictionary: return self.dictionaryFromKey(key)
            case CGPDFObjectType.stream: return self.streamFromKey(key)
            default:
                break
            }
        }
        
        return nil
    }
    
    var getDictionaryObjects:CGPDFDictionaryApplierFunction = { (key, object, info) in
        
        let context = info!.assumingMemoryBound(to: PDFObjectParserContext.self).pointee
        context.keys.append(key)
    }
    
    func description(_ level: Int = 0) -> String {
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
