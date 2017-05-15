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
    fileprivate var block: ((PDFBarButton) -> ())?
    
    override open var tintColor: UIColor? {
        didSet {
            button.tintColor = tintColor
        }
    }

    convenience init(
        image: UIImage?,
        toggled: Bool,
        target: AnyObject? = nil,
        action: Selector? = nil,
        block: ((PDFBarButton) -> ())? = nil
        ) {
        
        self.init()
        
        customView = button
        defaultTint = button.tintColor
        
        toggle(toggled)
        
        self.target = target
        self.action = action
        self.block = block
        
        button.addTarget(self, action: #selector(PDFBarButton.tapped), for: .touchUpInside)
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    
    open func toggle(_ state: Bool) {
        toggled = state
        if toggled {
            button.tintColor = UIColor.white
            button.layer.backgroundColor = (tintColor ?? defaultTint).cgColor
            button.layer.cornerRadius = 4.0
        }
        else {
            button.tintColor = tintColor
            button.layer.backgroundColor = UIColor.clear.cgColor
            button.layer.cornerRadius = 4.0
        }
    }
    
    func tapped() {
        let _ = self.target?.perform(self.action, with: self)
        self.block?(self)
    }
}

open class PDFAnnotationBarButton: PDFBarButton {
    var annotationType: PDFAnnotation.Type? = nil
    
    convenience init(
        toggled: Bool,
        type: PDFAnnotationButtonable.Type,
        block: ((PDFBarButton) -> ())? = nil
        ) {
        self.init(image: type.buttonImage, toggled: toggled, target: nil, action: nil, block: block)
        self.annotationType = type
    }
}
