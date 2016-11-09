//
//  PDFAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

protocol PDFAnnotation {
    var page: Int? { get set }
    func mutableView() -> UIView
    func touchStarted(_ touch: UITouch, point: CGPoint)
    func touchMoved(_ touch: UITouch, point: CGPoint)
    func touchEnded(_ touch: UITouch, point: CGPoint)
    func drawInContext(_ context: CGContext)
}
