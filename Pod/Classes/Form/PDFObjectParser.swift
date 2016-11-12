//
//  PDFObjectParser.swift
//  Pods
//
//  Created by Chris Anderson on 5/25/16.
//
//

import UIKit

open class PDFObjectParser {
    let document: PDFDocument
    let attributes: PDFDictionary?
    
    public init(document: PDFDocument) {
        self.document = document
        if let catalogue = document.documentRef?.catalog {
            attributes = PDFDictionary(dictionaryRef: catalogue)
        } else {
            attributes = nil
        }
        
    }
}
