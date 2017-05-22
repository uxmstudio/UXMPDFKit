//
//  PDFTextAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

class PDFTextAnnotation: NSObject, NSCoding {
    
    var page: Int?
    var uuid: String = UUID().uuidString
    var saved: Bool = false
    var delegate: PDFAnnotationEvent?
    
    var text: String = "" {
        didSet {
            view.text = text
        }
    }
    
    var rect: CGRect = CGRect.zero {
        didSet {
            view.frame = self.rect
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 14.0) {
        didSet {
            view.font = self.font
        }
    }
    
    lazy var view: PDFTextAnnotationView = PDFTextAnnotationView(parent: self)
    
    fileprivate var isEditing: Bool = false
    
    override required init() { super.init() }
    
    func didEnd() {
        self.view.hideEditingHandles()
        self.view.textView.resignFirstResponder()
        self.view.textView.isUserInteractionEnabled = false
    }
    
    required init(coder aDecoder: NSCoder) {
        page = aDecoder.decodeObject(forKey: "page") as? Int
        text = aDecoder.decodeObject(forKey: "text") as! String
        rect = aDecoder.decodeCGRect(forKey: "rect")
        font = aDecoder.decodeObject(forKey: "font") as! UIFont
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(page, forKey: "page")
        aCoder.encode(text, forKey: "text")
        aCoder.encode(rect, forKey: "rect")
        aCoder.encode(font, forKey: "font")
    }
}

extension PDFTextAnnotation: PDFAnnotation {
    
    func mutableView() -> UIView {
        view = PDFTextAnnotationView(parent: self)
        return view
    }
    
    func touchStarted(_ touch: UITouch, point: CGPoint) {
        if rect == CGRect.zero {
            rect = CGRect(origin: point, size: CGSize(width: 150, height: 48))
        }
        self.view.touchesBegan([touch], with: nil)
    }
    
    func touchMoved(_ touch: UITouch, point: CGPoint) {
        self.view.touchesMoved([touch], with: nil)
    }
    
    func touchEnded(_ touch: UITouch, point: CGPoint) {
        self.view.touchesEnded([touch], with: nil)
    }
    
    func save() {
        self.saved = true
    }
    
    func drawInContext(_ context: CGContext) {
        UIGraphicsPushContext(context)
        context.setAlpha(1.0)
        
        let nsText = self.text as NSString
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.left
        
        let attributes: [String:AnyObject] = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.black,
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let size = nsText.size(attributes: attributes)
        let textRect = CGRect(origin: rect.origin, size: size)
        
        nsText.draw(in: textRect, withAttributes: attributes)
        
        UIGraphicsPopContext()
    }
}

extension PDFTextAnnotation: ResizableViewDelegate {
    func resizableViewDidBeginEditing(view: ResizableView) {}
    
    func resizableViewDidEndEditing(view: ResizableView) {
        self.rect = self.view.frame
    }
    
    func resizableViewDidSelectAction(view: ResizableView, action: String) {
        self.delegate?.annotation(annotation: self, selected: action)
    }
}

extension PDFTextAnnotation: PDFAnnotationButtonable {
    
    static var name: String? { return "Text" }
    static var buttonImage: UIImage? { return UIImage.bundledImage("text-symbol") }
}

extension PDFTextAnnotation: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.sizeToFit()
        
        var width: CGFloat = 150.0
        if self.view.frame.width > width {
            width = self.view.frame.width
        }
        
        rect = CGRect(x: self.view.frame.origin.x,
                      y: self.view.frame.origin.y,
                      width: width,
                      height: self.view.frame.height)
        
        if text != textView.text {
            text = textView.text
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.isUserInteractionEnabled = false
    }
}


class PDFTextAnnotationView: ResizableView, PDFAnnotationView {
    
    var parent: PDFAnnotation?
    override var canBecomeFirstResponder: Bool { return true }
    override var menuItems: [UIMenuItem] {
        return [
            UIMenuItem(
                title: "Delete",
                action: #selector(PDFTextAnnotationView.menuActionDelete(_:))
            ),
            UIMenuItem(
                title: "Edit",
                action: #selector(PDFTextAnnotationView.menuActionEdit(_:))
            )
        ]
    }
    
    var textView: UITextView = UITextView()
    
    var text: String = "" {
        didSet {
            textView.text = text
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 14.0) {
        didSet {
            textView.font = self.font
        }
    }
    
    override var frame: CGRect {
        didSet {
            textView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        }
    }
    
    convenience init(parent: PDFTextAnnotation) {
        
        self.init()
        
        self.parent = parent
        self.delegate = parent
        self.frame = parent.rect
        self.text = parent.text
        self.font = parent.font
        
        self.textView.text = parent.text
        self.textView.delegate = parent
        self.textView.isUserInteractionEnabled = false
        self.textView.backgroundColor = UIColor.clear
        
        self.backgroundColor = UIColor.clear
        
        self.addSubview(textView)
    }
    
    func menuActionEdit(_ sender: Any!) {
        self.delegate?.resizableViewDidSelectAction(view: self, action: "edit")
        
        self.isLocked = true
        self.textView.isUserInteractionEnabled = true
        self.textView.becomeFirstResponder()
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if action == #selector(menuActionEdit(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
