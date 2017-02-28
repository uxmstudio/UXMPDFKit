//
//  CGPoint.swift
//  Pods
//
//  Created by Chris Anderson on 2/1/17.
//
//

import Foundation

extension CGPoint {
    
    func rect(from point: CGPoint) -> CGRect {
        return CGRect(x: min(self.x, point.x),
                      y: min(self.y, point.y),
                      width: fabs(self.x - point.x),
                      height: fabs(self.y - point.y))
    }
}
