//
//  UXMAction.swift
//  Pods
//
//  Created by Chris Anderson on 9/12/16.
//
//

import Foundation

open class UXMAction {
    open static func fromPDFDictionary(_ sourceDictionary: CGPDFDictionaryRef, documentReference: CGPDFDocument) -> UXMAction? {
        var action: UXMAction?
        var destinationName: CGPDFStringRef? = nil
        var destinationString: UnsafePointer<Int8>? = nil
        var actionDictionary: CGPDFDictionaryRef? = nil
        var destinationArray: CGPDFArrayRef? = nil
        
        if CGPDFDictionaryGetDictionary(sourceDictionary, "A", &actionDictionary) {
            
            var actionType: UnsafePointer<Int8>? = nil
            
            if CGPDFDictionaryGetName(actionDictionary!, "S", &actionType) {
                
                /// Handle GoTo action types
                if strcmp(actionType, "GoTo") == 0 {
                    if !CGPDFDictionaryGetArray(actionDictionary!, "D", &destinationArray) {
                        CGPDFDictionaryGetString(actionDictionary!, "D", &destinationName)
                    }
                }
                else { /// Handle other link action type possibility
                    
                    /// URI action type
                    if strcmp(actionType, "URI") == 0 {
                        
                        var uriString: CGPDFStringRef? = nil
                        if CGPDFDictionaryGetString(actionDictionary!, "URI", &uriString) {
                            
                            let uri = UnsafeRawPointer(CGPDFStringGetBytePtr(uriString!)!).assumingMemoryBound(to: Int8.self)
                            if let target = String(validatingUTF8: uri) {
                                action = UXMActionURL(stringUrl: target)
                            }
                        }
                    }
                }
            }
        }
        else {
            /// Handle other link target possibilities
            if !CGPDFDictionaryGetArray(sourceDictionary, "Dest", &destinationArray) {
                if !CGPDFDictionaryGetString(sourceDictionary, "Dest", &destinationName) {
                    CGPDFDictionaryGetName(sourceDictionary, "Dest", &destinationString)
                }
            }
        }
        
        /// Handle a destination name
        if destinationName != nil {
            let catalogDictionary: CGPDFDictionaryRef = documentReference.catalog!
            var namesDictionary: CGPDFDictionaryRef? = nil
            
            if CGPDFDictionaryGetDictionary(catalogDictionary, "Names", &namesDictionary) {
                
                var destsDictionary: CGPDFDictionaryRef? = nil
                
                if CGPDFDictionaryGetDictionary(namesDictionary!, "Dests", &destsDictionary) {
                    let localDestinationName = UnsafeRawPointer(CGPDFStringGetBytePtr(destinationName!)!).assumingMemoryBound(to: Int8.self)
                    destinationArray = self.destinationWithName(localDestinationName, node: destsDictionary!)
                }
            }
        }
        
        /// Handle a destination string
        if destinationString != nil {
            let catalogDictionary: CGPDFDictionaryRef = documentReference.catalog!
            var destsDictionary: CGPDFDictionaryRef? = nil
            
            if CGPDFDictionaryGetDictionary(catalogDictionary, "Dests", &destsDictionary) {
                
                var targetDictionary: CGPDFDictionaryRef? = nil
                if CGPDFDictionaryGetDictionary(destsDictionary!, destinationString!, &targetDictionary) {
                    CGPDFDictionaryGetArray(targetDictionary!, "D", &destinationArray)
                }
            }
        }
        
        /// Handle a destination array
        if (destinationArray != nil) {
            var targetPageNumber = 0
            var pageDictionaryFromDestArray: CGPDFDictionaryRef? = nil
            
            if CGPDFArrayGetDictionary(destinationArray!, 0, &pageDictionaryFromDestArray) {
                
                let pageCount = documentReference.numberOfPages
                for pageNumber in 1...pageCount {
                    
                    let pageRef: CGPDFPage = documentReference.page(at: pageNumber)!
                    let pageDictionaryFromPage: CGPDFDictionaryRef = pageRef.dictionary!
                    
                    if pageDictionaryFromPage == pageDictionaryFromDestArray {
                        targetPageNumber = pageNumber
                        break
                    }
                }
                
            }
            else {
                
                var pageNumber: CGPDFInteger = 0
                
                if CGPDFArrayGetInteger(destinationArray!, 0, &pageNumber) {
                    targetPageNumber = (pageNumber + 1)
                }
            }
            
            /// We have a target page number, make GoTo link
            if targetPageNumber > 0 {
                action = UXMActionGoTo(pageIndex: targetPageNumber)
            }
        }
        
        return action
    }
    
    
    fileprivate static func destinationWithName(_ destinationName: UnsafePointer<Int8>, node: CGPDFDictionaryRef) -> CGPDFArrayRef? {
        
        var destinationArray: CGPDFArrayRef? = nil
        var limitsArray: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(node, "Limits", &limitsArray) {
            
            var lowerLimit: CGPDFStringRef? = nil
            var upperLimit: CGPDFStringRef? = nil
            
            if CGPDFArrayGetString(limitsArray!, 0, &lowerLimit)
                && CGPDFArrayGetString(limitsArray!, 1, &upperLimit) {
                
                let llu = CGPDFStringGetBytePtr(lowerLimit!)!
                let ulu = CGPDFStringGetBytePtr(upperLimit!)!
                
                let ll:UnsafePointer<Int8> = UnsafeRawPointer(llu).assumingMemoryBound(to: Int8.self)
                let ul:UnsafePointer<Int8> = UnsafeRawPointer(ulu).assumingMemoryBound(to: Int8.self)
                
                if (strcmp(destinationName, ll) < 0) || (strcmp(destinationName, ul) > 0) {
                    return nil
                }
            }
        }
        
        var namesArray: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(node, "Names", &namesArray) {
            
            let namesCount = CGPDFArrayGetCount(namesArray!)
            for i in stride(from: 0, to: namesCount, by: 2) {
                
                var destName: CGPDFStringRef? = nil
                if CGPDFArrayGetString(namesArray!, i, &destName) {
                    
                    let dnu = CGPDFStringGetBytePtr(destName!)!
                    let dn: UnsafePointer<Int8> = UnsafeRawPointer(dnu).assumingMemoryBound(to: Int8.self)
                    if strcmp(dn, destinationName) == 0 {
                        
                        if !CGPDFArrayGetArray(namesArray!, (i + 1), &destinationArray) {
                            
                            var destinationDictionary: CGPDFDictionaryRef? = nil
                            
                            if CGPDFArrayGetDictionary(namesArray!, (i + 1), &destinationDictionary) {
                                CGPDFDictionaryGetArray(destinationDictionary!, "D", &destinationArray)
                            }
                        }
                        return destinationArray!
                    }
                }
            }
        }
        
        var kidsArray: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(node, "Kids", &kidsArray) {
            
            let kidsCount = CGPDFArrayGetCount(kidsArray!)
            
            for i in 0..<kidsCount {
                
                var kidNode: CGPDFDictionaryRef? = nil
                
                if CGPDFArrayGetDictionary(kidsArray!, i, &kidNode) {
                    destinationArray = self.destinationWithName(destinationName, node: kidNode!)
                    if destinationArray != nil {
                        return destinationArray!
                    }
                }
            }
        }
        
        return nil
    }
}
