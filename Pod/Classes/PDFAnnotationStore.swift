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
    
    func addAnnotation(annotation: PDFAnnotation, page: Int) {
        
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
    
    func drawAnnotations(page: Int, context:CGContextRef) {
        
        if let storePage = pages[page] {
            for annotation in storePage.annotations {
                annotation.drawInContext(context)
            }
        }
    }
}

public class PDFAnnotationPage {
    
    var annotations:[PDFAnnotation] = []
    var page:Int = 0
    
    func addAnnotation(annotation: PDFAnnotation) {
        annotations.append(annotation)
    }
}