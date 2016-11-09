//
//  PDFAnnotationStore.swift
//  Pods
//
//  Created by Chris Anderson on 5/8/16.
//
//

import UIKit

open class PDFAnnotationStore {
    var annotations: [PDFAnnotation] = []
    
    func add(annotation: PDFAnnotation) {
        annotations.append(annotation)
    }
    
    func undo() -> PDFAnnotation? {
        return annotations.popLast()
    }
    
    func annotations(page: Int) -> [PDFAnnotation] {
        return annotations.filter({ $0.page == page })
    }
    
    func renderInContext(_ context: CGContext, size: CGRect, page: Int) {
        for annotation in annotations(page: page) {
            annotation.drawInContext(context)
        }
    }
}
