//
//  PDFAnnotationStore.swift
//  Pods
//
//  Created by Chris Anderson on 5/8/16.
//
//

import UIKit


public protocol PDFAnnotationStoreDelegate {
    
    func annotationStore(store: PDFAnnotationStore, addedAnnotation: PDFAnnotation)
    func annotationStore(store: PDFAnnotationStore, removedAnnotation: PDFAnnotation)
}

open class PDFAnnotationStore: NSObject, NSCoding {
    
    var annotations: [PDFAnnotation] = []
    var delegate: PDFAnnotationStoreDelegate?
    
    func add(annotation: PDFAnnotation) {
        annotations.append(annotation)
        self.delegate?.annotationStore(store: self, addedAnnotation: annotation)
    }
    
    func undo() -> PDFAnnotation? {
        
        if let annotation = annotations.popLast() {
            self.delegate?.annotationStore(store: self, addedAnnotation: annotation)
            return annotation
        }
        return nil
    }
    
    func annotations(page: Int) -> [PDFAnnotation] {
        return annotations.filter({ $0.page == page })
    }
    
    func renderInContext(_ context: CGContext, size: CGRect, page: Int) {
        for annotation in annotations(page: page) {
            annotation.drawInContext(context)
        }
    }
    
    override init() { super.init() }
    
    required public init(coder aDecoder: NSCoder) {
        annotations = aDecoder.decodeObject(forKey: "annotations") as! [PDFAnnotation]
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(annotations, forKey: "annotations")
    }
}
