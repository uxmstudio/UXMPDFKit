//
//  UXMFormTextField.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

open class UXMFormTextField: UXMFormField {
    let multiline: Bool
    let textEntryBox: UIView
    let baseFontSize: CGFloat
    let currentFontSize: CGFloat
    let alignment: NSTextAlignment
    
    var text: String {
        get {
            if let textField = textEntryBox as? UITextField {
                return textField.text ?? ""
            }
            if let textView = textEntryBox as? UITextView {
                return textView.text ?? ""
            }
            return ""
        }
        set(updatedText) {
            if let textField = textEntryBox as? UITextField {
                textField.text = updatedText
            }
            if let textView = textEntryBox as? UITextView {
                textView.text = updatedText
            }
        }
    }
    
    init(frame: CGRect, multiline: Bool, alignment: NSTextAlignment) {
        let rect = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        
        textEntryBox = multiline
            ? UITextView(frame: rect)
            : UITextField(frame: rect)
        self.multiline = multiline
        baseFontSize = 12.0
        currentFontSize = baseFontSize
        self.alignment = alignment
        
        super.init(frame: frame)
        
        setupUI()
    }
    
    func setupUI() {
        backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.7)
        if multiline {
            if let textView = textEntryBox as? UITextView {
                textView.textAlignment = alignment
                textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                textView.delegate = self
                textView.isScrollEnabled = true
                textView.textContainerInset = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
                let fontSize = fontSizeForRect(frame) < 13.0 ? fontSizeForRect(frame) : 13.0
                textView.font = UIFont.systemFont(ofSize: fontSize)
            }
        }
        else {
            if let textField = textEntryBox as? UITextField {
                textField.textAlignment = alignment
                textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                textField.delegate = self
                textField.adjustsFontSizeToFitWidth = true
                textField.minimumFontSize = 6.0
                textField.font = UIFont.systemFont(ofSize: fontSizeForRect(self.frame))
                textField.addTarget(self, action: #selector(UXMFormTextField.textChanged), for: .editingChanged)
            }
            
            layer.cornerRadius = frame.size.height / 6
        }
        
        textEntryBox.isOpaque = false
        textEntryBox.backgroundColor = UIColor.clear
        
        addSubview(textEntryBox)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func refresh() {
        setNeedsDisplay()
        textEntryBox.setNeedsDisplay()
    }
    
    override func didSetValue(_ value: AnyObject?) {
        if let value = value as? String {
            text = value
        }
    }
    
    func fontSizeForRect(_ rect: CGRect) -> CGFloat {
        return rect.size.height * 0.7
    }
    
    override func renderInContext(_ context: CGContext) {
        let text: String
        let font: UIFont
        if let textField = textEntryBox as? UITextField {
            text = textField.text ?? ""
            font = textField.font!
        }
        else if let textView = textEntryBox as? UITextView {
            text = textView.text
            font = textView.font!
        }
        else {
            fatalError()
        }
        
        /// UGLY
        text.draw(in: frame, withAttributes: [
          NSAttributedString.Key.font: font
            ])
    }

    override func resign() {
      textEntryBox.resignFirstResponder()
    }
}

extension UXMFormTextField: UITextFieldDelegate {
    @objc func textChanged() {
        value = text as AnyObject?
        delegate?.formFieldValueChanged(self)
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.formFieldEntered(self)
        self.parent?.activeWidgetAnnotationView = self
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.parent?.activeWidgetAnnotationView = nil
    }
}

extension UXMFormTextField: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.formFieldEntered(self)
        self.parent?.activeWidgetAnnotationView = self
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.parent?.activeWidgetAnnotationView = nil;
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        delegate?.formFieldValueChanged(self)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newString = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        value = newString as AnyObject?

        delegate?.formFieldValueChanged(self)
        return false
    }
}
