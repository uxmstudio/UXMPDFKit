//
//  PDFFormButtonField.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

public class PDFFormButtonField: PDFFormField {
    
    public var radio:Bool = false
    public var noOff:Bool = false
    public var pushButton:Bool = false
    public var name:String = ""
    public var exportValue:String = ""
    
    private var button:UIButton = UIButton(type: .Custom)
    private let inset:CGFloat = 0.8
    
    init(frame: CGRect, radio: Bool) {
        self.radio = radio
        super.init(frame: frame)
        self.setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        self.opaque = false
        self.backgroundColor = UIColor.clearColor()
        
        if self.radio {
            self.button.layer.cornerRadius = self.button.frame.width/2
        }
        self.button.frame = CGRectMake(
            (frame.width - frame.width * inset) / 2,
            (frame.height - frame.height * inset) / 2,
            frame.width * inset,
            frame.height * inset)
        self.button.opaque = false
        self.button.backgroundColor = UIColor.clearColor()
        self.button.addTarget(self, action: #selector(PDFFormButtonField.buttonPressed), forControlEvents: .TouchUpInside)
        self.button.userInteractionEnabled = true
        self.button.exclusiveTouch = true
        self.addSubview(self.button)
    }
    
    override func didSetValue(value: AnyObject?) {
        if let value = value as? String {
            self.setButtonState(value == self.exportValue)
        }
    }
    
    func setButtonState(selected: Bool) {
        if selected {
            self.button.backgroundColor = UIColor.blackColor()
        }
        else {
            self.button.backgroundColor = UIColor.clearColor()
        }
    }
    
    func isSelected() -> Bool {
        if let value = self.value as? String {
            return value == exportValue
        }
        return false
    }
    
    func buttonPressed() {
        
        self.value = isSelected() ? "" : exportValue
        self.delegate?.formFieldValueChanged(self)
    }
    
    override func renderInContext(context: CGContext) {
        
        var frame = self.button.frame
        frame.origin.x += self.frame.origin.x
        frame.origin.y += self.frame.origin.y
        
        if isSelected() {
            CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        }
        else {
            CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        }
        CGContextAddRect(context, frame)
        CGContextDrawPath(context, .FillStroke)
    }
}
