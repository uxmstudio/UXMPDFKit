//
//  PDFDocumentLink.swift
//  Pods
//
//  Created by Ricardo Nunez on 11/11/16.
//
//

import UIKit

internal class PDFDocumentLink: NSObject {
    var rect: CGRect
    var dictionary: CGPDFDictionaryRef
    
    static func new(_ rect: CGRect, dictionary: CGPDFDictionaryRef) -> PDFDocumentLink {
        return PDFDocumentLink(rect: rect, dictionary: dictionary)
    }
    
    init(rect: CGRect, dictionary: CGPDFDictionaryRef) {
        self.rect = rect
        self.dictionary = dictionary
        
        super.init()
    }
}
