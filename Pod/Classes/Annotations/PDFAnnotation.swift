//
//  PDFAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

protocol PDFAnnotation {
    
    func mutableView() -> UIView
    func touchStarted(touch: UITouch, point:CGPoint)
    func touchMoved(touch:UITouch, point:CGPoint)
    func touchEnded(touch:UITouch, point:CGPoint)
    func drawInContext(context: CGContextRef)
}