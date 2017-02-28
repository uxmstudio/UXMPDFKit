//
//  CGRect.swift
//  Pods
//
//  Created by Chris Anderson on 2/1/17.
//
//

import Foundation

extension CGRect {
    
    mutating func expandToFit(point: CGPoint) {
        
        let frame = self.containing(point: point)
        self.origin.x = frame.origin.x
        self.origin.y = frame.origin.y
        self.size.width = frame.size.width
        self.size.height = frame.size.height
    }
    
    func containing(point: CGPoint) -> CGRect {
        
        let points = [
            CGPoint(x: self.minX, y: self.minY),
            CGPoint(x: self.minX, y: self.maxY),
            CGPoint(x: self.maxX, y: self.minY),
            CGPoint(x: self.maxX, y: self.maxY),
            point
        ]
        
        var minX: CGFloat = self.minX
        var minY: CGFloat = self.minY
        var maxX: CGFloat = self.maxX
        var maxY: CGFloat = self.maxY
        
        for subPoint in points {
            minX = min(minX, subPoint.x)
            maxX = max(maxX, subPoint.x)
            minY = min(minY, subPoint.y)
            maxY = max(maxY, subPoint.y)
        }
        
        return CGRect(
            x: minX,
            y: minY,
            width: fabs(maxX - minX),
            height: fabs(maxY - minY)
        )
    }
}
