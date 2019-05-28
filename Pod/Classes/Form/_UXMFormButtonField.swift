//
//  UXMFormButtonField.swift
//  Pods
//
//  Created by Chris Anderson on 6/1/16.
//
//

import UIKit

open class _UXMFormButtonField: UXMFormField {
    open var buttonType = ButtonType.radio
    open var noOff = false
    open var pushButton = false
    open var name = ""
    open var exportValue = ""

    var _value: AnyObject?
    
    var isSelected: Bool {
        if let value = self.value as? String {
            return value == exportValue
        }
        return false
    }

    var _radio = false
    
    fileprivate var button = UIButton(type: .custom) // UXMToggleButton(frame: CGRect.zero)
    fileprivate let inset: CGFloat = 1.0

    init(frame: CGRect, radio: Bool) {
        if radio {
            self.buttonType = .radio
        }
        super.init(frame: frame)
        self._radio = radio
        setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupUI() {
        isOpaque = false
        backgroundColor = UIColor.pdfBackgroundBlue().withAlphaComponent(0.7)

        let minDim = min(frame.size.width,frame.size.height) * 0.85
        let center: CGPoint = CGPoint(x: frame.size.width/2, y: frame.size.height/2)

        button.frame = CGRect(
            x: center.x-minDim,
            y: center.y-minDim,
            width: minDim - inset * 2,
            height: minDim * 2)
        button.isOpaque = false
        if _radio {
          button.layer.cornerRadius = button.frame.width / 2
        }
        button.backgroundColor = UIColor.clear
        addSubview(button)
        button.addTarget(self, action: #selector(UXMFormButtonField.buttonPressed), for: .touchUpInside)
        isUserInteractionEnabled = false
        button.isUserInteractionEnabled = true
        button.isExclusiveTouch = true
    }

    @objc func buttonPressed() {
        value = (button.isSelected ? "" : exportValue) as AnyObject?
        button.isSelected = !button.isSelected
        delegate?.formFieldValueChanged(self)
    }

  open func setButtonInSuperview() {
    button.removeFromSuperview()
    let frame = self.bounds
    let minDim = min(frame.size.width,frame.size.height) * 0.85
    let center: CGPoint = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
    button.frame = CGRect(x: center.x-minDim+self.frame.origin.x, y: center.y-minDim+self.frame.origin.y, width: 2*minDim, height: 2*minDim)
    self.superview?.insertSubview(button, aboveSubview: self)
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

        let attributes: [NSAttributedString.Key:AnyObject] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: titleColor,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        title.draw(in: frame, withAttributes: attributes)

        UIGraphicsPopContext()
    }

  override func didSetValue(_ value: AnyObject?) {

    if (value != nil) {
      button.isSelected = value!.isEqual(exportValue)
    } else {
      button.isSelected = false
    }

    setNeedsDisplay()
  }

  func drawWithRect(frame: CGRect, context: CGContext, back: Bool, selected: Bool, radio: Bool) {
    let minDim = min(frame.size.width,frame.size.height) * 0.85
    let center: CGPoint = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
    let rect: CGRect = CGRect(x: center.x/minDim/2, y: center.y-minDim/2, width: minDim, height: minDim)

    if (back) {
      context.saveGState()
      context.setFillColor(UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.7).cgColor)
      if (!radio) {
        let radius = minDim/6
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + radius))
        context.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height - radius))
        context.addArc(center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + rect.size.height - radius), radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi/2, clockwise: true)
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + rect.size.height))
        context.addArc(center: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + rect.size.height - radius), radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi/2, clockwise: true)
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + radius))

        context.addArc(center: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + radius), radius: radius, startAngle: 0.0, endAngle: -(CGFloat.pi/2), clockwise: true)

        context.addLine(to: CGPoint(x: rect.origin.x + radius, y: rect.origin.y))
        context.addArc(center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + radius), radius: radius, startAngle: -(CGFloat.pi/2), endAngle: CGFloat.pi, clockwise: true)
        context.fillPath()

      } else {
        context.fillEllipse(in: rect)
      }

      context.restoreGState()

    }

    if(selected) {
      context.saveGState()
      let margin = minDim/3
      if (radio) {
        context.setFillColor(UIColor.black.cgColor)
        context.translateBy(x: rect.origin.x, y: rect.origin.y)
        context.addEllipse(in: CGRect(x: margin, y: margin, width: rect.size.width-2*margin, height: rect.size.height-2*margin))
        context.fillPath()
      } else {
        context.translateBy(x: rect.origin.x, y: rect.origin.y)
        context.setLineWidth(rect.size.width/8)
        context.setLineCap(.round)
        context.setStrokeColor(UIColor.black.cgColor)
        context.move(to: CGPoint(x: margin*0.75, y: rect.size.height/2))
        context.addLine(to: CGPoint(x: rect.size.width/2-margin/4, y: rect.size.height-margin))
        context.addLine(to: CGPoint(x: rect.size.width-margin*0.75, y: margin/2))
        context.strokePath()
      }

      context.restoreGState()
    }

  }

  open override func draw(_ rect: CGRect) {
    if(pushButton) {
      super.draw(rect)
      return
    }

    guard let context = UIGraphicsGetCurrentContext() else { return }
    drawWithRect(frame: rect, context: context, back: true, selected: button.isSelected, radio: self._radio)

  }
}
