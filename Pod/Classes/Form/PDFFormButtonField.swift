//
//  PDFFormButtonField.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

open class PDFFormButtonField: PDFFormField {
    
    open var radio:Bool = false
    open var noOff:Bool = false
    open var pushButton:Bool = false
    open var name:String = ""
    open var exportValue:String = ""
    
    fileprivate var button:UIButton = UIButton(type: .custom)
    fileprivate let inset:CGFloat = 0.8
    
    init(frame: CGRect, radio: Bool) {
        self.radio = radio
        super.init(frame: frame)
        self.setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        
        if self.radio {
            self.button.layer.cornerRadius = self.button.frame.width/2
        }
        self.button.frame = CGRect(
            x: (frame.width - frame.width * inset) / 2,
            y: (frame.height - frame.height * inset) / 2,
            width: frame.width * inset,
            height: frame.height * inset)
        self.button.isOpaque = false
        self.button.backgroundColor = UIColor.clear
        self.button.addTarget(self, action: #selector(PDFFormButtonField.buttonPressed), for: .touchUpInside)
        self.button.isUserInteractionEnabled = true
        self.button.isExclusiveTouch = true
        self.addSubview(self.button)
    }
    
    override func didSetValue(_ value: AnyObject?) {
        if let value = value as? String {
            self.setButtonState(value == self.exportValue)
        }
    }
    
    func setButtonState(_ selected: Bool) {
        if selected {
            self.button.backgroundColor = UIColor.black
        }
        else {
            self.button.backgroundColor = UIColor.clear
        }
    }
    
    func isSelected() -> Bool {
        if let value = self.value as? String {
            return value == exportValue
        }
        return false
    }
    
    func buttonPressed() {
        
        self.value = (isSelected() ? "" : exportValue) as AnyObject?
        self.delegate?.formFieldValueChanged(self)
    }
    
    override func renderInContext(_ context: CGContext) {
        
        var frame = self.button.frame
        frame.origin.x += self.frame.origin.x
        frame.origin.y += self.frame.origin.y
        
        if isSelected() {
            context.setFillColor(UIColor.black.cgColor)
        }
        else {
            context.setFillColor(UIColor.clear.cgColor)
        }
        context.addRect(frame)
        context.drawPath(using: .fillStroke)
    }
}
