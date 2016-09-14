//
//  PDFAnnotationStore.swift
//  Pods
//
//  Created by Chris Anderson on 5/8/16.
//
//

import UIKit

open class PDFAnnotationStore {
    
    var pages:[Int:PDFAnnotationPage] = [:]
    
    func add(_ annotation: PDFAnnotation, page: Int) {
        
        if let storePage:PDFAnnotationPage = pages[page] {
            
            storePage.addAnnotation(annotation)
        }
        else {
            
            let storePage = PDFAnnotationPage()
            storePage.addAnnotation(annotation)
            storePage.page = page
            pages[page] = storePage
        }
    }
    
    func get(_ page: Int) -> PDFAnnotationPage? {
        return self.pages[page]
    }
    
    func undo(_ page: Int) -> PDFAnnotation? {
        guard let storePage = pages[page] else { return nil }
        return storePage.undo()
    }
    
    func annotationsForPage(_ page: Int) -> [PDFAnnotation] {
        guard let storePage = pages[page] else { return [] }
        return storePage.annotations
    }
}

open class PDFAnnotationPage {
    
    var annotations:[PDFAnnotation] = []
    var page:Int = 0
    
    func addAnnotation(_ annotation: PDFAnnotation) {
        annotations.append(annotation)
    }
    
    func renderInContext(_ context: CGContext, size: CGRect) {
        
        for annotation in self.annotations {
            annotation.drawInContext(context)
        }
    }
    
    func undo() -> PDFAnnotation? {
        
        return self.annotations.popLast()
    }
}
