//
//  PDFObjectParser.swift
//  Pods
//
//  Created by Chris Anderson on 5/25/16.
//
//

import UIKit

class PDFObjectParserContext {
    var keys:[UnsafePointer<Int8>] = []
    
    init(keys: [UnsafePointer<Int8>]) {
        self.keys = keys
    }
}

open class PDFObjectParser: NSObject {
    let document: PDFDocument
    var attributes: PDFDictionary?
    
    public init(document: PDFDocument) {
        self.document = document
        super.init()
        
        let _ = self.getFormFields()
    }
    
    func getFormFields() -> AnyObject? {
        guard let ref = document.documentRef else {
            return nil
        }
        
        let catalogue = ref.catalog

        attributes = PDFDictionary(dictionaryRef: catalogue!)

        return attributes
    }
    
    func getCatalogue() -> CGPDFDictionaryRef? {
        guard let ref = document.documentRef else {
            return nil
        }
        return ref.catalog
    }
    
}
