//
//  PDFArray.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import UIKit

class PDFArray: NSObject, PDFObject {
    
    private var arr:CGPDFArrayRef
    
    var array:[AnyObject] = []
    
    init(arrayRef: CGPDFArrayRef) {
        self.arr = arrayRef
        super.init()
        
        self.array = self.copyAsArray()
    }
    
    func type() -> CGPDFObjectType {
        return CGPDFObjectType.Array
    }
    
    func count() -> Int {
        return self.array.count
    }
    
    func rect() -> CGRect? {
        if self.array.count != 4 {
            return nil
        }
        
        for entry in self.array {
            guard let _ = entry as? CGFloat else {
                return nil
            }
        }
        
        let x0 = self.array[0] as! CGFloat
        let y0 = self.array[1] as! CGFloat
        let x1 = self.array[2] as! CGFloat
        let y1 = self.array[3] as! CGFloat

        return CGRectMake(min(x0, x1), min(y0, y1), abs(x1-x0), abs(y1-x0))
    }
    
    func pdfObjectAtIndex(index: Int) -> AnyObject? {
        
        var object:CGPDFObjectRef = nil
        if CGPDFArrayGetObject(self.arr, index, &object) {
            
            let type = CGPDFObjectGetType(object)
            switch type {
            case CGPDFObjectType.Boolean: return self.booleanAtIndex(index)
            case CGPDFObjectType.Integer: return self.intAtIndex(index)
            case CGPDFObjectType.Real: return self.realAtIndex(index)
            case CGPDFObjectType.Name: return self.nameAtIndex(index)
            case CGPDFObjectType.String: return self.stringAtIndex(index)
            case CGPDFObjectType.Array: return self.arrayAtIndex(index)
            case CGPDFObjectType.Dictionary: return self.dictionaryAtIndex(index)
            case CGPDFObjectType.Stream: return self.streamAtIndex(index)
            default:
                break
            }
        }
        
        return nil
    }
    
    func dictionaryAtIndex(index: Int) -> PDFDictionary? {
        var dictionary:CGPDFDictionaryRef = nil
        if CGPDFArrayGetDictionary(self.arr, index, &dictionary) {
            return PDFDictionary(dictionaryRef: dictionary)
        }
        return nil
    }
    
    func arrayAtIndex(index: Int) -> PDFArray? {
        var array:CGPDFArrayRef = nil
        if CGPDFArrayGetArray(self.arr, index, &array) {
            return PDFArray(arrayRef: array)
        }
        return nil
    }
    
    func stringAtIndex(index: Int) -> String? {
        var string:CGPDFStringRef = nil
        if CGPDFArrayGetString(self.arr, index, &string) {
            if let ref:CFStringRef = CGPDFStringCopyTextString(string) {
                return ref as String
            }
        }
        return nil
    }
    
    func nameAtIndex(index: Int) -> String? {
        var name:UnsafePointer<Int8> = nil
        if CGPDFArrayGetName(self.arr, index, &name) {
            if let dictionaryName = String.fromCString(name) {
                return dictionaryName
            }
        }
        return nil
    }
    
    func intAtIndex(index: Int) -> Int? {
        var intObj:CGPDFInteger = 0
        if CGPDFArrayGetInteger(self.arr, index, &intObj) {
            return Int(intObj)
        }
        return nil
    }
    
    func realAtIndex(index: Int) -> CGFloat? {
        var realObj:CGPDFReal = 0.0
        if CGPDFArrayGetNumber(self.arr, index, &realObj) {
            return CGFloat(realObj)
        }
        return nil
    }
    
    func booleanAtIndex(index: Int) -> Bool? {
        var boolObj:CGPDFBoolean = 0
        if CGPDFArrayGetBoolean(self.arr, index, &boolObj) {
            return Bool(Int(boolObj))
        }
        return nil
    }
    
    func streamAtIndex(index: Int) -> PDFDictionary? {
        var stream:CGPDFStreamRef = nil
        if CGPDFArrayGetStream(self.arr, index, &stream) {
            let dictionaryRef = CGPDFStreamGetDictionary(stream)
            return PDFDictionary(dictionaryRef: dictionaryRef)
        }
        return nil
    }
    
    func copyAsArray() -> [AnyObject] {
        
        var temp:[AnyObject] = []
        for i in 0...CGPDFArrayGetCount(self.arr) {
            if let obj = self.pdfObjectAtIndex(i) {
                temp.append(obj)
            }
        }
        
        return temp
    }
}


extension PDFArray: SequenceType {

    func generate() -> AnyGenerator<AnyObject> {
        var nextIndex = self.array.count - 1
        
        return AnyGenerator {
            if nextIndex < 0 {
                return nil
            }
            let obj = self.array[nextIndex]
            nextIndex = nextIndex - 1
            return obj
        }
    }
}

