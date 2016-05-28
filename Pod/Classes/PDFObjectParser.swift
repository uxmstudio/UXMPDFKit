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
    var attributes:PDFDictionary?
    
    public init(document: PDFDocument) {
        
        self.document = document
        super.init()
        
        self.getFormFields()
    }
    
    func getFormFields() -> AnyObject? {
        var acroForm:CGPDFDictionaryRef = nil
        
        guard let ref = self.document.documentRef() else {
            return nil
        }
        
        let catalogue = CGPDFDocumentGetCatalog(ref)
        
        if CGPDFDictionaryGetDictionary(catalogue, "AcroForm", &acroForm) {
            
            self.attributes = PDFDictionary(dictionaryRef: acroForm)
        }

        return self.attributes
    }
    
    func getCatalogue() -> CGPDFDictionaryRef? {
        
        guard let ref = self.document.documentRef() else {
            return nil
        }
        return CGPDFDocumentGetCatalog(ref)
    }
    
}