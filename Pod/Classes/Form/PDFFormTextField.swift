//
//  PDFFormTextField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}


open class PDFFormTextField: PDFFormField {
    
    var multiline: Bool
    var textEntryBox: UIView
    var baseFontSize: CGFloat
    var currentFontSize: CGFloat
    var alignment: NSTextAlignment
    
    init(frame: CGRect, multiline: Bool, alignment: NSTextAlignment) {
        
        let rect = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        
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
                textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                textView.delegate = self
                textView.isScrollEnabled = true
                textView.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4)
                let fontSize = self.fontSizeForRect(self.frame) < 13.0 ? self.fontSizeForRect(self.frame) : 13.0
                textView.font = UIFont.systemFont(ofSize: fontSize)
            }
        }
        else {
            if let textField = self.textEntryBox as? UITextField {
                textField.textAlignment = alignment
                textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                textField.delegate = self
                textField.adjustsFontSizeToFitWidth = true
                textField.minimumFontSize = 6.0
                textField.font = UIFont.systemFont(ofSize: self.fontSizeForRect(self.frame))
                textField.addTarget(self, action: #selector(PDFFormTextField.textChanged), for: .editingChanged)
            }
            
            self.layer.cornerRadius = self.frame.size.height / 6
        }
        
        self.textEntryBox.isOpaque = false
        self.textEntryBox.backgroundColor = UIColor.clear
        
        self.addSubview(self.textEntryBox)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func refresh() {
        self.setNeedsDisplay()
        self.textEntryBox.setNeedsDisplay()
    }
    
    override func didSetValue(_ value: AnyObject?) {
        if let value = value as? String {
            self.setText(value)
        }
    }
    
    func fontSizeForRect(_ rect: CGRect) -> CGFloat {
        
        return rect.size.height * 0.7
    }
    
    func setText(_ text: String) {
        
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
    
    override func renderInContext(_ context: CGContext) {
        
        var text = ""
        var font: UIFont? = nil
        if let textField = self.textEntryBox as? UITextField {
            text = textField.text ?? ""
            font = textField.font
        }
        if let textView = self.textEntryBox as? UITextView {
            text = textView.text
            font = textView.font
        }
        
        /// UGLY
        (text as NSString!).draw(in: self.frame, withAttributes: [
            NSFontAttributeName: font!
            ])
    }
}

extension PDFFormTextField: UITextFieldDelegate {

    func textChanged() {
        self.value = self.getText() as AnyObject?
        self.delegate?.formFieldValueChanged(self)
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.formFieldEntered(self)
    }
}

extension PDFFormTextField: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.formFieldEntered(self)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        self.delegate?.formFieldValueChanged(self)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newString = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        self.value = newString as AnyObject?

        self.delegate?.formFieldValueChanged(self)
        return false
    }
}
