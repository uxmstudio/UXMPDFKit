//
//  PDFFormButtonField.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

let ballotBox = "\u{2610}"
let ballotBoxWithCheck = "\u{2611}"
let ballotBoxWithX = "\u{2612}"
let checkmark = "\u{2713}"
let heavyCheckmark = "\u{2714}"

public enum ButtonType {
    case radio, checkbox, push
}

open class PDFFormButtonField: PDFFormField {
    open var buttonType = ButtonType.checkbox
    open var noOff = false
    open var name = ""
    open var exportValue = ""
    
    var isSelected: Bool {
        if let value = self.value as? String {
            return value == exportValue
        }
        return false
    }
    
    fileprivate var button = PDFToggleButton(frame: CGRect.zero)
    fileprivate let inset: CGFloat = 1.0

    init(frame: CGRect, radio: Bool) {
        if radio {
            self.buttonType = .radio
        }
        super.init(frame: frame)
        setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupUI() {
        isOpaque = false
        backgroundColor = UIColor.pdfBackgroundBlue().withAlphaComponent(0.7)

        if buttonType == .radio {
            button.layer.cornerRadius = button.frame.width / 2
        }
        button.frame = CGRect(
            x: inset,
            y: inset,
            width: frame.width - inset * 2,
            height: frame.height - inset * 2)
        button.isOpaque = false
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(PDFFormButtonField.buttonPressed), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        button.isExclusiveTouch = true
        addSubview(button)
    }

    @objc func buttonPressed() {
        value = (isSelected ? "" : exportValue) as AnyObject?
        delegate?.formFieldValueChanged(self)
    }

    override func renderInContext(_ context: CGContext) {
        switch buttonType {
        case .radio:
            break
        case .checkbox:
            renderCheckbox(in: context)
        case .push:
            break
        }
    }

    fileprivate func renderCheckbox(in context: CGContext) {
            
       UIGraphicsPushContext(context)
        context.setAlpha(1.0)

        var frame = button.frame
        frame.origin.x += self.frame.origin.x
        frame.origin.y += self.frame.origin.y

        let state = isSelected ? UIControl.State.selected : UIControl.State.normal
        var title: NSString = ""
        let titleColor = button.titleColor(for: state) ?? UIColor.black
        let font: UIFont = button.titleLabel!.font

        let title1 = button.title(for: state)

        if let title1 = title1 {
            title = title1 as NSString
        }

        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.center

        let attributes: [String:AnyObject] = [
            convertFromNSAttributedStringKey(NSAttributedString.Key.font): font,
            convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): titleColor,
            convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle
        ]

        title.draw(in: frame, withAttributes: convertToOptionalNSAttributedStringKeyDictionary(attributes))

        UIGraphicsPopContext()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
