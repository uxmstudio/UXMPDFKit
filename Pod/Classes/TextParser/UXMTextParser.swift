//
//  UXMTextParser.swift
//  Pods
//
//  Created by Chris Anderson on 11/15/16.
//
//

import UIKit

enum UXMTextParserError: Error {
    case noPageRef
}

class UXMTextParser {
    
    var document: UXMPDFDocument
    var pageRef: CGPDFPage?
    
    init(document: UXMPDFDocument, page: Int) throws {
        
        self.document = document
        self.pageRef = document.page(at: page)
        
        guard let pageRef = self.pageRef else {
            throw UXMTextParserError.noPageRef
        }
        var pageDict: CGPDFDictionaryRef? = pageRef.dictionary
        
        /// Start looking for fonts
        var hasParent = false
        repeat {
            
            var resources: CGPDFDictionaryRef? = nil
            CGPDFDictionaryGetDictionary(pageDict!, "Resources", &resources);

            var xObject: CGPDFDictionaryRef? = nil
            if (CGPDFDictionaryGetDictionary(resources!, "XObject", &xObject)) {
                
                //TODO: Start parse of XObject
            }

            var fontDictionary: CGPDFDictionaryRef? = nil
            CGPDFDictionaryGetDictionary(resources!, "Font", &fontDictionary);
            //TODO: Start parse of font dictionary
            
            /// Recurse
            hasParent = CGPDFDictionaryGetDictionary(pageDict!, "Parent", &pageDict);
            
        } while (hasParent)
    }
}
