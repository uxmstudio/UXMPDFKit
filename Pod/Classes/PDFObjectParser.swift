//
//  PDFObjectParser.swift
//  Pods
//
//  Created by Chris Anderson on 5/25/16.
//
//

import UIKit

class PDFObjectParserContext {
    
    var dictionaryRef:CGPDFDictionaryRef
    var info:UnsafeMutablePointer<Void>
    var attributes:[String:AnyObject] = [:]
    
    init(dictionaryRef: CGPDFDictionaryRef, info: UnsafeMutablePointer<Void>, attributes: [String:AnyObject]) {
        
        self.dictionaryRef = dictionaryRef
        self.info = info
        self.attributes = attributes
    }
}

public class PDFObjectParser: NSObject {
    
    var document:PDFDocument
    var attributes:[String:AnyObject] = [:]
    
    public init(document: PDFDocument) {
        
        self.document = document
        super.init()
        
        print(self.getFormFields())
    }
    
    func getFormFields() -> AnyObject? {
        var acroForm:CGPDFDictionaryRef = nil
        
        guard let ref = self.document.documentRef() else {
            return nil
        }
        let catalogue = CGPDFDocumentGetCatalog(ref)
        
        if CGPDFDictionaryGetDictionary(catalogue, "AcroForm", &acroForm) {
            
            var context = PDFObjectParserContext(
                dictionaryRef: acroForm,
                info: UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()),
                attributes: self.attributes
            )
            
            CGPDFDictionaryApplyFunction(acroForm, getDictionaryObjects, &context)
            
            self.attributes = context.attributes
        }

        return self.attributes
    }
    
    func getCatalogue() -> CGPDFDictionaryRef? {
        
        guard let ref = self.document.documentRef() else {
            return nil
        }
        return CGPDFDocumentGetCatalog(ref)
    }
    
    
    func booleanValue(object: CGPDFObjectRef) -> Bool? {
        var objectBoolean:CGPDFBoolean = 0
        if CGPDFObjectGetValue(object, CGPDFObjectType.Boolean, &objectBoolean) {
            return Bool(Int(objectBoolean))
        }
        return nil
    }
    
    func integerValue(object: CGPDFObjectRef) -> Int? {
        var objectInt:CGPDFInteger = 0
        if CGPDFObjectGetValue(object, CGPDFObjectType.Integer, &objectInt) {
            return Int(objectInt)
        }
        return nil
    }
    
    func realValue(object: CGPDFObjectRef) -> Int? {
        var objectReal:CGPDFReal = 0
        if CGPDFObjectGetValue(object, CGPDFObjectType.Real, &objectReal) {
            return Int(objectReal)
        }
        return nil
    }
    
    
    
    var getDictionaryObjects:CGPDFDictionaryApplierFunction = { (key, object, info) in
        
        guard let stringKey = String.fromCString(key) else {
            return
        }
        
        let context = UnsafeMutablePointer<PDFObjectParserContext>(info).memory
        let contentDict:CGPDFDictionaryRef = context.dictionaryRef
        let objSelf = Unmanaged<PDFObjectParser>.fromOpaque(COpaquePointer(context.info)).takeUnretainedValue()
        let type:CGPDFObjectType = CGPDFObjectGetType(object)
        var attrs:[String:AnyObject] = [:]
        
        switch type {
        case CGPDFObjectType.Boolean:
            attrs[stringKey] = objSelf.booleanValue(object)
            break
        case CGPDFObjectType.Integer:
            attrs[stringKey] = objSelf.integerValue(object)
            break
        case CGPDFObjectType.Real:
            attrs[stringKey] = objSelf.realValue(object)
            break
        case CGPDFObjectType.Name:

            var name:UnsafePointer<Int8> = nil
            if CGPDFDictionaryGetName(contentDict, key, &name) {
                
                if let dictionaryName = String.fromCString(name) {
                    context.attributes[dictionaryName] = [:]
                }
            }
            break
        case CGPDFObjectType.String:

            var objectString:CGPDFStringRef = nil
            if CGPDFObjectGetValue(object, CGPDFObjectType.String, &objectString) {
                
                if let ref:CFStringRef = CGPDFStringCopyTextString(objectString) {
                    context.attributes[stringKey] = ref as String
                }
            }
            break
        case CGPDFObjectType.Array:

            var objectArray:CGPDFArrayRef = nil
            if CGPDFObjectGetValue(object, CGPDFObjectType.Array, &objectArray) {
                if let array = objectArray.copyAsArray(contentDict, refKey: key, info: info) {
                    context.attributes[stringKey] = array
                }
            }
            
            break
        case CGPDFObjectType.Dictionary:

            var objectDictionary:CGPDFArrayRef = nil
            if CGPDFObjectGetValue(object, CGPDFObjectType.Dictionary, &objectDictionary) {
                if stringKey != "Parent" && stringKey != "P" {
                    
                    var attributes:[String:AnyObject] = [:]
                    var ctx = PDFObjectParserContext(
                        dictionaryRef: objectDictionary,
                        info: context.info,
                        attributes: attributes)
                    
                    CGPDFDictionaryApplyFunction(objectDictionary, objSelf.getDictionaryObjects, &ctx)
                    
                    context.attributes[stringKey] = ctx.attributes
                }
            }
            break
        case CGPDFObjectType.Stream:
            
            var objectStream:CGPDFStreamRef = nil
            if CGPDFObjectGetValue(object, CGPDFObjectType.Stream, &objectStream) {
                
                let objectDictionary = CGPDFStreamGetDictionary(objectStream)
                if stringKey != "Parent" && stringKey != "P" {
                    
                    var attributes:[String:AnyObject] = [:]
                    var ctx = PDFObjectParserContext(
                        dictionaryRef: objectDictionary,
                        info: context.info,
                        attributes: attributes)
                    
                    CGPDFDictionaryApplyFunction(objectDictionary, objSelf.getDictionaryObjects, &ctx)
                    
                    context.attributes[stringKey] = context.attributes
                }
            }
            
            break
        default:
            break
        }
    }

}



extension CGPDFArrayRef {
    
    func copyAsArray(refDictionary:CGPDFDictionaryRef, refKey:UnsafePointer<Int8>, info: UnsafeMutablePointer<Void>) -> [AnyObject]? {
        
        guard let stringKey = String.fromCString(refKey) else {
            return nil
        }
        
        let context = UnsafeMutablePointer<PDFObjectParserContext>(info).memory
        let contentDict:CGPDFDictionaryRef = context.dictionaryRef
        let objSelf = Unmanaged<PDFObjectParser>.fromOpaque(COpaquePointer(context.info)).takeUnretainedValue()
        
        var temp:[AnyObject] = []
        for i in 0...CGPDFArrayGetCount(self) {
            
            var object:CGPDFObjectRef = nil
            CGPDFArrayGetObject(self, i, &object)
            var type = CGPDFObjectGetType(object)
            
            switch type {
            case CGPDFObjectType.Boolean:
                var objectBoolean:CGPDFBoolean = 0
                if CGPDFObjectGetValue(object, CGPDFObjectType.Boolean, &objectBoolean) {
                    
                    temp.append(Bool(Int(objectBoolean)))
                }
                break
            case CGPDFObjectType.Integer:
                var objectInt:CGPDFInteger = 0
                if CGPDFObjectGetValue(object, CGPDFObjectType.Integer, &objectInt) {
                    
                    temp.append(Int(objectInt))
                }
                break
            case CGPDFObjectType.Real:
                var objectReal:CGPDFReal = 0
                if CGPDFObjectGetValue(object, CGPDFObjectType.Real, &objectReal) {
                    
                    temp.append(Int(objectReal))
                }
                break
            case CGPDFObjectType.Name:
                var name:UnsafePointer<Int8> = nil
                if CGPDFDictionaryGetName(refDictionary, refKey, &name) {
                    
                    if let dictionaryName = String.fromCString(name) {
                        objSelf.attributes[dictionaryName] = stringKey
                    }
                }
                break
            case CGPDFObjectType.String:
                var objectString:CGPDFStringRef = nil
                if CGPDFObjectGetValue(object, CGPDFObjectType.String, &objectString) {
                    
                    if let ref:CFStringRef = CGPDFStringCopyTextString(objectString) {
                        temp.append(ref as String)
                    }
                }
                break
            case CGPDFObjectType.Array:
                var objectArray:CGPDFArrayRef = nil
                if CGPDFObjectGetValue(object, CGPDFObjectType.Array, &objectArray) {
                    if let array = objectArray.copyAsArray(refDictionary, refKey: refKey, info: info) {
                        temp.append(array)
                    }
                }
                
                break
            case CGPDFObjectType.Dictionary:
                var objectDictionary:CGPDFArrayRef = nil
                if CGPDFObjectGetValue(object, CGPDFObjectType.Dictionary, &objectDictionary) {
                    if stringKey != "Parent" && stringKey != "P" {
                        
                        var attributes:[String:AnyObject] = [:]
                        var context = PDFObjectParserContext(
                            dictionaryRef: objectDictionary,
                            info: context.info,
                            attributes: attributes)
                        
                        CGPDFDictionaryApplyFunction(objectDictionary, objSelf.getDictionaryObjects, &context)
                        
                        temp.append(context.attributes)
                    }
                }
                break
            case CGPDFObjectType.Stream:
                var objectStream:CGPDFStreamRef = nil
                if CGPDFObjectGetValue(object, CGPDFObjectType.Stream, &objectStream) {
 
                    let objectDictionary = CGPDFStreamGetDictionary(objectStream)
                    
                    
//                    var fmt:CGPDFDataFormat = CGPDFDataFormat.Raw
//                    var streamData:CFDataRef = CGPDFStreamCopyData(objectStream, &fmt)!
//                    var dataString = NSString(data: streamData, encoding: NSUTF8StringEncoding)
                    
                    if stringKey != "Parent" && stringKey != "P" {
                        
                        var attributes:[String:AnyObject] = [:]
                        var context = PDFObjectParserContext(
                            dictionaryRef: objectDictionary,
                            info: context.info,
                            attributes: attributes)
                        
                        CGPDFDictionaryApplyFunction(objectDictionary, objSelf.getDictionaryObjects, &context)
                        temp.append(context.attributes)
                    }
                }

                break
            default:
                break
            }
        }
        
        return temp
    }
}
