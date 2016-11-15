//
//  PDFActionURL.swift
//  Pods
//
//  Created by Chris Anderson on 11/15/16.
//
//

import Foundation

open class PDFActionURL: PDFAction {
    var url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public init(stringUrl: String) {
        self.url = URL(string: stringUrl)!
    }
}
