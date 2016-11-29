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

    func buttonPressed() {
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

        let state = isSelected ? UIControlState.selected : UIControlState.normal
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
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: titleColor,
            NSParagraphStyleAttributeName: paragraphStyle
        ]

        title.draw(in: frame, withAttributes: attributes)

        UIGraphicsPopContext()
    }
}
