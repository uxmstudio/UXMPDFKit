//
//  UXMAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

public protocol UXMAnnotation {
    
    /// The page number the annotation is located on
    var page: Int? { get set }
    
    /// Unique identifier to be able to select annotation by
    var uuid: String { get }
    
    /// Boolean representing if the annotation has been saved
    var saved: Bool { get set }
    
    var delegate: UXMPDFAnnotationEvent? { get set }
    
    /// Force implementations to have an init
    init()
    
    /// A function to return a view composed of the annotations properties
    func mutableView() -> UIView
    
    /// Set of handlers to pass touches to annotation
    func touchStarted(_ touch: UITouch, point: CGPoint)
    func touchMoved(_ touch: UITouch, point: CGPoint)
    func touchEnded(_ touch: UITouch, point: CGPoint)
    
    /// Method to save annotation locally
    func save()
    func drawInContext(_ context: CGContext)
    
    func didEnd()
    
    func encode(with aCoder: NSCoder)
}

public protocol UXMPDFAnnotationButtonable: UXMAnnotation {
    
    /// Name for UIBarButtonItem representation of annotation
    static var name: String? { get }
    
    /// Image for UIBarButtonItem representation of annotation 
    static var buttonImage: UIImage? { get }
}

public protocol UXMPDFAnnotationEvent : class {
    func annotationUpdated(annotation: UXMAnnotation)
    func annotation(annotation: UXMAnnotation, selected action: String)
}

public protocol UXMPDFAnnotationView {
    var parent: UXMAnnotation? { get }
    var canBecomeFirstResponder: Bool { get }
}
