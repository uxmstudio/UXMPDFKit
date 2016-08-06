//
//  CGPDFDocument.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import Foundation

public enum CGPDFDocumentError: ErrorType {
    case FileDoesNotExist
    case PasswordRequired
    case CouldNotUnlock
}

extension CGPDFDocument {
    
    public static func create(url: NSURL, password: String?) throws -> CGPDFDocumentRef {

        guard let docRef = CGPDFDocumentCreateWithURL(url) else {
            
            throw CGPDFDocumentError.FileDoesNotExist
        }
        
        if CGPDFDocumentIsEncrypted(docRef) {
            
            guard let password = password else {
                
                throw CGPDFDocumentError.PasswordRequired
            }
            
            if CGPDFDocumentUnlockWithPassword(docRef, "") == false {
                
                CGPDFDocumentUnlockWithPassword(docRef, (password as NSString).UTF8String)
            }
            
            if CGPDFDocumentIsUnlocked(docRef) == false {
                
                throw CGPDFDocumentError.CouldNotUnlock
            }
        }
        
        return docRef
    }
}