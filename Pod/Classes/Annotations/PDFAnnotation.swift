//
//  PDFAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

public protocol PDFAnnotation {
    var page: Int? { get set }
    var uuid: String { get }
    var saved: Bool { get set }
    func mutableView() -> UIView
    func touchStarted(_ touch: UITouch, point: CGPoint)
    func touchMoved(_ touch: UITouch, point: CGPoint)
    func touchEnded(_ touch: UITouch, point: CGPoint)
    func save()
    func drawInContext(_ context: CGContext)
    
    func encode(with aCoder: NSCoder)
}

public protocol PDFAnnotationView {
    var parent: PDFAnnotation? { get }
    var canBecomeFirstResponder: Bool { get }
}
