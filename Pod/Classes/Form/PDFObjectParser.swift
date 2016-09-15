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
    
    var document:PDFDocument
    var attributes:PDFDictionary?
    
    public init(document: PDFDocument) {
        
        self.document = document
        super.init()
        
        let _ = self.getFormFields()
    }
    
    func getFormFields() -> AnyObject? {

        guard let ref = self.document.documentRef else {
            return nil
        }
        
        let catalogue = ref.catalog

        self.attributes = PDFDictionary(dictionaryRef: catalogue!)

        return self.attributes
    }
    
    func getCatalogue() -> CGPDFDictionaryRef? {
        
        guard let ref = self.document.documentRef else {
            return nil
        }
        return ref.catalog
    }
    
}
