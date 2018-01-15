//
//  UXMAnnotationStore.swift
//  Pods
//
//  Created by Chris Anderson on 5/8/16.
//
//

import UIKit


public protocol UXMAnnotationStoreDelegate {

    func annotationStore(store: UXMAnnotationStore, addedAnnotation: UXMAnnotation)
    func annotationStore(store: UXMAnnotationStore, removedAnnotation: UXMAnnotation)
}

open class UXMAnnotationStore: NSObject, NSCoding {

    var annotations: [UXMAnnotation] = []
    var delegate: UXMAnnotationStoreDelegate?


    func add(annotation: UXMAnnotation) {
        annotations.append(annotation)
        self.delegate?.annotationStore(store: self, addedAnnotation: annotation)
    }

    func remove(annotation: UXMAnnotation) {
        if let index = annotations.index(where: { $0.uuid == annotation.uuid }), index > -1 {
            self.delegate?.annotationStore(store: self, removedAnnotation: annotation)
            self.annotations.remove(at: index)
        }
    }

    func undo() -> UXMAnnotation? {

        if let annotation = annotations.popLast() {
            self.delegate?.annotationStore(store: self, removedAnnotation: annotation)
            return annotation
        }
        return nil
    }

    func annotations(page: Int) -> [UXMAnnotation] {
        return annotations.filter({ $0.page == page })
    }

    func renderInContext(_ context: CGContext, size: CGRect, page: Int) {
        for annotation in annotations(page: page) {
            annotation.drawInContext(context)
        }
    }

    override init() { super.init() }

    required public init(coder aDecoder: NSCoder) {
        annotations = aDecoder.decodeObject(forKey: "annotations") as! [UXMAnnotation]
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(annotations, forKey: "annotations")
    }
}
