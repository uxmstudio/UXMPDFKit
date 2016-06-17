//
//  PDFFormTextField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

public class PDFFormTextField: PDFFormField {
    
    var multiline:Bool
    var textEntryBox:UIView
    var baseFontSize:CGFloat
    var currentFontSize:CGFloat
    var alignment:NSTextAlignment
    
    init(frame: CGRect, multiline: Bool, alignment: NSTextAlignment) {
        
        let rect = CGRectMake(0, 0, frame.size.width, frame.size.height)
        
        self.textEntryBox = multiline
            ? UITextView(frame: rect)
            : UITextField(frame: rect)
        self.multiline = multiline
        self.baseFontSize = 12.0
        self.currentFontSize = baseFontSize
        self.alignment = alignment
        
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    func setupUI() {
        
        self.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.7)
        if multiline {
            if let textView = self.textEntryBox as? UITextView {
                textView.textAlignment = alignment
                textView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                textView.delegate = self
                textView.scrollEnabled = true
                textView.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4)
                var fontSize = self.fontSizeForRect(self.frame) < 13.0 ? self.fontSizeForRect(self.frame) : 13.0
                textView.font = UIFont.systemFontOfSize(fontSize)
            }
        }
        else {
            if let textField = self.textEntryBox as? UITextField {
                textField.textAlignment = alignment
                textField.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                textField.delegate = self
                textField.adjustsFontSizeToFitWidth = true
                textField.minimumFontSize = 6.0
                textField.font = UIFont.systemFontOfSize(self.fontSizeForRect(self.frame))
                textField.addTarget(self, action: #selector(PDFFormTextField.textChanged), forControlEvents: .EditingChanged)
            }
            
            self.layer.cornerRadius = self.frame.size.height / 6
        }
        
        self.textEntryBox.opaque = false
        self.textEntryBox.backgroundColor = UIColor.clearColor()
        
        self.addSubview(self.textEntryBox)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func refresh() {
        self.setNeedsDisplay()
        self.textEntryBox.setNeedsDisplay()
    }
    
    override func didSetValue(value: AnyObject?) {
        if let value = value as? String {
            self.setText(value)
        }
    }
    
    func fontSizeForRect(rect: CGRect) -> CGFloat {
        
        return rect.size.height * 0.7
    }
    
    func setText(text: String) {
        
        if let textField = self.textEntryBox as? UITextField {
            textField.text = text
        }
        if let textView = self.textEntryBox as? UITextView {
            textView.text = text
        }
    }
    
    func getText() -> String {
        
        if let textField = self.textEntryBox as? UITextField {
            return textField.text ?? ""
        }
        if let textView = self.textEntryBox as? UITextView {
            return textView.text ?? ""
        }
        return ""
    }
    
    override func renderInContext(context: CGContext) {
        
        var text = ""
        var font:UIFont? = nil
        if let textField = self.textEntryBox as? UITextField {
            text = textField.text ?? ""
            font = textField.font
        }
        if let textView = self.textEntryBox as? UITextView {
            text = textView.text
            font = textView.font
        }
        
        /// UGLY
        (text as NSString!).drawInRect(self.frame, withAttributes: [
            NSFontAttributeName: font!
        ])
    }
}

extension PDFFormTextField: UITextFieldDelegate {
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        if newString.characters.count <= textField.text?.characters.count {
            return true
        }
        return true
    }
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        self.delegate?.formFieldEntered(self)
    }
}

extension PDFFormTextField: UITextViewDelegate {
    public func textViewDidBeginEditing(textView: UITextView) {
        self.delegate?.formFieldEntered(self)
    }
    
    public func textViewDidChange(textView: UITextView) {
        self.delegate?.formFieldValueChanged(self)
    }
    
    func textChanged() {
        self.value = self.getText()
        self.delegate?.formFieldValueChanged(self)
    }
}