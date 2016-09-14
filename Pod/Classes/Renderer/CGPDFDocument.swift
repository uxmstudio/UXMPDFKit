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
}

extension CGPDFDocument {
    
    public static func create(_ url: URL, password: String?) throws -> CGPDFDocument {

        guard let docRef = CGPDFDocument(url) else {
            throw CGPDFDocumentError.fileDoesNotExist
        }
        
        if docRef.isEncrypted {
            
            guard let password = password else {
                
                throw CGPDFDocumentError.passwordRequired
            }
            
            if docRef.unlockWithPassword("") == false {
                
                docRef.unlockWithPassword((password as NSString).utf8String)
            }
            
            if docRef.isUnlocked == false {
                
                throw CGPDFDocumentError.couldNotUnlock
            }
        }
        
        return docRef
    }
}
