//
//  PDFBarButton.swift
//  Pods
//
//  Created by Ricardo Nunez on 11/11/16.
//
//

import UIKit

open class PDFBarButton: UIBarButtonItem {
    fileprivate let button = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    fileprivate var toggled = false
    fileprivate lazy var defaultTint = UIColor.blue
    
    override open var tintColor: UIColor? {
        didSet {
            button.tintColor = tintColor
        }
    }
    
    convenience init(image: UIImage?, toggled: Bool, target: AnyObject?, action: Selector) {
        self.init()
        
        customView = button
        defaultTint = button.tintColor
        
        toggle(toggled)
        
        self.target = target
        self.action = action
        
        button.addTarget(self, action: #selector(PDFBarButton.tapped), for: .touchUpInside)
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    
    open func toggle(_ state: Bool) {
        toggled = state
        if toggled {
            button.tintColor = UIColor.white
            button.layer.backgroundColor = (tintColor ?? defaultTint).cgColor
            button.layer.cornerRadius = 4.0
        } else {
            button.tintColor = tintColor
            button.layer.backgroundColor = UIColor.clear.cgColor
            button.layer.cornerRadius = 4.0
        }
    }
    
    func tapped() {
        let _ = self.target?.perform(self.action, with: self)
    }
}
