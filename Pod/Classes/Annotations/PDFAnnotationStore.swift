//
//  PDFAnnotationStore.swift
//  Pods
//
//  Created by Chris Anderson on 5/8/16.
//
//

import UIKit

public class PDFAnnotationStore {
    
    var pages:[Int:PDFAnnotationPage] = [:]
    
    func add(annotation: PDFAnnotation, page: Int) {
        
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
    
    func get(page: Int) -> PDFAnnotationPage? {
        return self.pages[page]
    }
    
    func undo(page: Int) -> PDFAnnotation? {
        guard let storePage = pages[page] else { return nil }
        return storePage.undo()
    }
    
    func annotationsForPage(page: Int) -> [PDFAnnotation] {
        guard let storePage = pages[page] else { return [] }
        return storePage.annotations
    }
}

public class PDFAnnotationPage {
    
    var annotations:[PDFAnnotation] = []
    var page:Int = 0
    
    func addAnnotation(annotation: PDFAnnotation) {
        annotations.append(annotation)
    }
    
    func renderInContext(context: CGContext, size: CGRect) {
        
        for annotation in self.annotations {
            annotation.drawInContext(context)
        }
    }
    
    func undo() -> PDFAnnotation? {
        
        return self.annotations.popLast()
    }
}