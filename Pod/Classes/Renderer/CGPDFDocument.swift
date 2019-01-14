//
//  CGPDFDocument.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import Foundation

public enum CGPDFDocumentError: Error {
    case fileDoesNotExist
    case passwordRequired
    case couldNotUnlock
    case unableToOpen
}

extension CGPDFDocument {
    
    public static func create(url: URL, password: String?) throws -> CGPDFDocument {
        guard let docRef = CGPDFDocument((url as CFURL)) else {
            throw CGPDFDocumentError.fileDoesNotExist
        }
        
        if docRef.isEncrypted {
            try CGPDFDocument.unlock(docRef: docRef, password: password)
        }
        
        return docRef
    }
    
    public static func create(data: NSData, password: String?) throws -> CGPDFDocument {
        guard let dataProvider = CGDataProvider(data: data),
            let docRef = CGPDFDocument(dataProvider) else {
            throw CGPDFDocumentError.fileDoesNotExist
        }
        
        if docRef.isEncrypted {
            try CGPDFDocument.unlock(docRef: docRef, password: password)
        }
        
        return docRef
    }
    
    public static func unlock(docRef: CGPDFDocument, password: String?) throws {
        if docRef.unlockWithPassword("") == false {
            
            guard let password = password else {
                throw CGPDFDocumentError.passwordRequired
            }
            
            docRef.unlockWithPassword((password as NSString).utf8String!)
        }
        
        if docRef.isUnlocked == false {
            throw CGPDFDocumentError.couldNotUnlock
        }
    }
}
