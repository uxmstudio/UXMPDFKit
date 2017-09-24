//
//  UXMPageScrubberTrackControl.swift
//  Pods
//
//  Created by Ricardo Nunez on 11/11/16.
//
//

import UIKit

internal class UXMPageScrubberTrackControl: UIControl {
    var value: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        autoresizesSubviews = false
        isUserInteractionEnabled = true
        contentMode = .redraw
        autoresizingMask = UIViewAutoresizing()
        backgroundColor = UIColor.clear
        isExclusiveTouch = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func limitValue(_ x: CGFloat) -> CGFloat {
        var valueX = x
        let minX = bounds.origin.x
        let maxX = bounds.size.width - 1.0
        
        if valueX < minX {
            valueX = minX
        }
        
        if valueX > maxX {
            valueX = maxX
        }
        
        return valueX
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        value = limitValue(point.x)
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if isTouchInside {
            let point = touch.location(in: touch.view)
            let x = limitValue(point.x)
            if x != value {
                value = x
                sendActions(for: .valueChanged)
            }
        }
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let point = touch?.location(in: self) {
            value = limitValue(point.x)
        }
    }
}
