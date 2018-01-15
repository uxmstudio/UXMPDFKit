//
//  PDFObjectParser.swift
//  Pods
//
//  Created by Chris Anderson on 5/25/16.
//
//

import UIKit

open class UXMObjectParser {
    let document: UXMPDFDocument
    let attributes: UXMDictionary?
    
    public init(document: UXMPDFDocument) {
        self.document = document
        if let catalogue = document.documentRef?.catalog {
            attributes = UXMDictionary(dictionaryRef: catalogue)
        }
        else {
            attributes = nil
        }
    }
}
