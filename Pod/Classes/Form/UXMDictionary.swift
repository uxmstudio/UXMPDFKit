//
//  UXMDictionary.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import UIKit

internal protocol UXMObject {
    var type: CGPDFObjectType { get }
}

fileprivate class UXMObjectParserContext {
    var keys: [UnsafePointer<Int8>] = []
    
    init(keys: [UnsafePointer<Int8>]) {
        self.keys = keys
    }
}

func == (lhs: UXMDictionary, rhs: UXMDictionary) -> Bool {
    let rect1 = lhs.arrayForKey("Rect")?.rect
    let rect2 = rhs.arrayForKey("Rect")?.rect
    
    let keys1 = lhs.allKeys()
    let keys2 = rhs.allKeys()
    
    let t1 = lhs["T"] as? String
    let t2 = rhs["T"] as? String
    
    return rect1 == rect2 && keys1 == keys2 && t1 == t2
}

internal class UXMDictionary: UXMObject, Equatable {
    var dict: CGPDFDictionaryRef
    
    lazy var attributes: [String:AnyObject] = {
        
        var context = UXMObjectParserContext(keys: [])
        CGPDFDictionaryApplyFunction(self.dict, self.getDictionaryObjects, &context)
        
        self.keys = context.keys
        for key in self.keys {
            guard let stringKey = String(validatingUTF8: key) else { continue }
            self.stringKeys.append(stringKey)
        }

        var attributes: [String:AnyObject] = [:]
        for key in self.keys {
            guard let stringKey = String(validatingUTF8: key) else { continue }
            guard let obj = self.pdfObjectForKey(key) else { continue }
            attributes[stringKey] = obj
        }
        return attributes
    }()
    
    var keys: [UnsafePointer<Int8>] = []
    var stringKeys: [String] = []
    
    var isParent: Bool = false
    
    var type: CGPDFObjectType {
        return CGPDFObjectType.dictionary
    }
    
    init(dictionaryRef: CGPDFDictionaryRef) {
        dict = dictionaryRef
    }
    
    subscript(key: String) -> AnyObject? {
        return attributes[key]
    }
    
    func arrayForKey(_ key: String) -> UXMArray? {
        return attributes[key] as? UXMArray
    }
    
    func stringForKey(_ key: String) -> String? {
        return attributes[key] as? String
    }
    
    func allKeys() -> [String] {
        return stringKeys
    }
    
    fileprivate func booleanFromKey(_ key: UnsafePointer<Int8>) -> Bool? {
        var boolObj: CGPDFBoolean = 0
        if CGPDFDictionaryGetBoolean(dict, key, &boolObj) {
            return Int(boolObj) != 0
        }
        return nil
    }
    
    fileprivate func integerFromKey(_ key: UnsafePointer<Int8>) -> Int? {
        var intObj: CGPDFInteger = 0
        if CGPDFDictionaryGetInteger(dict, key, &intObj) {
            return Int(intObj)
        }
        return nil
    }
    
    fileprivate func realFromKey(_ key: UnsafePointer<Int8>) -> CGFloat? {
        var floatObj: CGPDFReal = 0
        if CGPDFDictionaryGetNumber(dict, key, &floatObj) {
            return CGFloat(floatObj)
        }
        return nil
    }
    
    fileprivate func nameFromKey(_ key: UnsafePointer<Int8>) -> String? {
        var nameObj: UnsafePointer<Int8>? = nil
        if CGPDFDictionaryGetName(dict, key, &nameObj) {
            if let dictionaryName = String(validatingUTF8: nameObj!) {
                return dictionaryName
            }
        }
        return nil
    }
    
    fileprivate func stringFromKey(_ key: UnsafePointer<Int8>) -> String? {
        var stringObj: CGPDFStringRef? = nil
        if CGPDFDictionaryGetString(dict, key, &stringObj) {
            if let ref: CFString = CGPDFStringCopyTextString(stringObj!) {
                return ref as String
            }
        }
        return nil
    }
    
    fileprivate func arrayFromKey(_ key: UnsafePointer<Int8>) -> UXMArray? {
        var arrayObj: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(dict, key, &arrayObj) {
            return UXMArray(arrayRef: arrayObj!)
        }
        return nil
    }
    
    fileprivate func dictionaryFromKey(_ key: UnsafePointer<Int8>) -> UXMDictionary? {
        guard let stringKey = String(validatingUTF8: key) else {
            return nil
        }
        
        if stringKey == "Parent" || stringKey == "P" {
            return nil
        }
        
        var dictObj: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetDictionary(dict, key, &dictObj) {
            return UXMDictionary(dictionaryRef: dictObj!)
        }
        return nil
    }
    
    fileprivate func streamFromKey(_ key: UnsafePointer<Int8>) -> UXMDictionary? {
        guard let stringKey = String(validatingUTF8: key) else {
            return nil
        }
        
        if stringKey == "Parent" || stringKey == "P" {
            return nil
        }
        
        var streamObj: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetStream(self.dict, key, &streamObj) {
            let dictObj = CGPDFStreamGetDictionary(streamObj!)
            return UXMDictionary(dictionaryRef: dictObj!)
        }
        return nil
    }
    
    func pdfObjectForKey(_ key: UnsafePointer<Int8>) -> AnyObject? {
        var object: CGPDFObjectRef? = nil
        if CGPDFDictionaryGetObject(dict, key, &object), object != nil {
            let type = CGPDFObjectGetType(object!)
            switch type {
            case CGPDFObjectType.boolean: return booleanFromKey(key) as AnyObject?
            case CGPDFObjectType.integer: return integerFromKey(key) as AnyObject?
            case CGPDFObjectType.real: return realFromKey(key) as AnyObject?
            case CGPDFObjectType.name: return nameFromKey(key) as AnyObject?
            case CGPDFObjectType.string: return stringFromKey(key) as AnyObject?
            case CGPDFObjectType.array: return arrayFromKey(key)
            case CGPDFObjectType.dictionary: return dictionaryFromKey(key)
            case CGPDFObjectType.stream: return streamFromKey(key)
            default:
                break
            }
        }
        
        return nil
    }
    
    var getDictionaryObjects: CGPDFDictionaryApplierFunction = { (key, object, info) in
        let context = info!.assumingMemoryBound(to: UXMObjectParserContext.self).pointee
        context.keys.append(key)
    }
    
    func description(_ level: Int = 0) -> String {
        var spacer = ""
        for _ in 0..<(level*2) { spacer += " " }
        
        var string = "\n\(spacer){\n"
        for (key, value) in attributes {
            if let value = value as? UXMDictionary {
                string += "\(spacer)\(key) : \(value.description(level+1))"
            } else {
                string += "\(spacer)\(key) : \(value)\n"
            }
        }
        string += "\(spacer)}\n"
        return string
    }
    
    var description: String {
        return description(0)
    }
}
