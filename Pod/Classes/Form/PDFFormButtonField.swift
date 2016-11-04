//
//  PDFFormButtonField.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

open class PDFFormButtonField: PDFFormField {
    
    open var radio = false
    open var noOff = false
    open var pushButton = false
    open var name = ""
    open var exportValue = ""
    
    var isSelected: Bool {
        if let value = self.value as? String {
            return value == exportValue
        }
        return false
    }
    
    fileprivate var button = UIButton(type: .custom)
    fileprivate let inset: CGFloat = 0.8
    
    init(frame: CGRect, radio: Bool) {
        self.radio = radio
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        isOpaque = false
        backgroundColor = UIColor.clear
        
        if radio {
            button.layer.cornerRadius = button.frame.width / 2
        }
        button.frame = CGRect(
            x: (frame.width - frame.width * inset) / 2,
            y: (frame.height - frame.height * inset) / 2,
            width: frame.width * inset,
            height: frame.height * inset)
        button.isOpaque = false
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(PDFFormButtonField.buttonPressed), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.isExclusiveTouch = true
        addSubview(button)
    }
    
    override func didSetValue(_ value: AnyObject?) {
        if let value = value as? String {
            setButtonState(value == exportValue)
        }
    }
    
    func setButtonState(_ selected: Bool) {
        if selected {
            button.backgroundColor = UIColor.black
        } else {
            button.backgroundColor = UIColor.clear
        }
    }
    
    func buttonPressed() {
        value = (isSelected ? "" : exportValue) as AnyObject?
        delegate?.formFieldValueChanged(self)
    }
    
    override func renderInContext(_ context: CGContext) {
        var frame = button.frame
        frame.origin.x += self.frame.origin.x
        frame.origin.y += self.frame.origin.y
        
        if isSelected {
            context.setFillColor(UIColor.black.cgColor)
        } else {
            context.setFillColor(UIColor.clear.cgColor)
        }
        context.addRect(frame)
        context.drawPath(using: .fillStroke)
    }
}
