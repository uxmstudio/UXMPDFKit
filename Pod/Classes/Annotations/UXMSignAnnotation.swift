//
//  UXMSignAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

open class UXMSignAnnotation: NSObject, NSCoding {

  public var page: Int?
  public var uuid: String = UUID().uuidString
  public var saved: Bool = false
  public weak var delegate: UXMPDFAnnotationEvent?

  var image: UIImage? = nil {
    didSet {
      view.signImage.image = image
    }
  }

  var rect: CGRect = CGRect.zero {
    didSet {
      view.frame = self.rect
    }
  }

  lazy var view: PDFSignAnnotationView = PDFSignAnnotationView(parent: self)

  fileprivate var isEditing: Bool = false

  override required public init() { super.init() }

  public func didEnd() {
  }

  required public init(coder aDecoder: NSCoder) {
    page = aDecoder.decodeObject(forKey: "page") as? Int
    image = aDecoder.decodeObject(forKey: "image") as? UIImage
    rect = aDecoder.decodeCGRect(forKey: "rect")
//    font = aDecoder.decodeObject(forKey: "font") as! UIFont
  }

  public func encode(with aCoder: NSCoder) {
    aCoder.encode(page, forKey: "page")
    aCoder.encode(image, forKey: "image")
    aCoder.encode(rect, forKey: "rect")
//    aCoder.encode(font, forKey: "font")
  }
}

extension UXMSignAnnotation: UXMAnnotation {

  public func mutableView() -> UIView {
    view = PDFSignAnnotationView(parent: self)
    return view
  }

  public func touchStarted(_ touch: UITouch, point: CGPoint) {
    if rect == CGRect.zero {
      rect = CGRect(origin: point, size: CGSize(width: 150, height: 48))
    }
    self.view.touchesBegan([touch], with: nil)
  }

  public func touchMoved(_ touch: UITouch, point: CGPoint) {
    self.view.touchesMoved([touch], with: nil)
  }

  public func touchEnded(_ touch: UITouch, point: CGPoint) {
    self.view.touchesEnded([touch], with: nil)
  }

  public func save() {
    self.saved = true
  }

  public func drawInContext(_ context: CGContext) {
    UIGraphicsPushContext(context)

    guard let size = self.image?.size else { return }
    let imageRect = CGRect(origin: rect.origin, size: size)

    guard let cgImage = self.image?.cgImage else { return }
    // Draw our CGImage in the context of our PDFAnnotation bounds
    context.draw(cgImage, in: imageRect)

    UIGraphicsPopContext()
  }
}

extension UXMSignAnnotation: ResizableViewDelegate {
  func resizableViewDidBeginEditing(view: ResizableView) { }

  func resizableViewDidEndEditing(view: ResizableView) {
    self.rect = self.view.frame
  }

  func resizableViewDidSelectAction(view: ResizableView, action: String) {
    self.delegate?.annotation(annotation: self, selected: action)
  }
}

extension UXMSignAnnotation: UXMPDFAnnotationButtonable {

  public static var name: String? { return "Sign" }
  public static var buttonImage: UIImage? { return UIImage.bundledImage("sign") }
}

//extension UXMSignAnnotation: UITextViewDelegate {
//  public func textViewDidChange(_ textView: UITextView) {
//    textView.sizeToFit()
//
//    var width: CGFloat = 150.0
//    if self.view.frame.width > width {
//      width = self.view.frame.width
//    }
//
//    rect = CGRect(x: self.view.frame.origin.x,
//                  y: self.view.frame.origin.y,
//                  width: width,
//                  height: self.view.frame.height)
//
//    if text != textView.text {
//      text = textView.text
//    }
//  }
//
//  public func textViewDidEndEditing(_ textView: UITextView) {
//    textView.isUserInteractionEnabled = false
//  }
//}


class PDFSignAnnotationView: ResizableView, UXMPDFAnnotationView {

  let signExtraPadding: CGFloat = 22.0

  var parent: UXMAnnotation?
  let signController = UXMFormSignatureViewController()
  override var canBecomeFirstResponder: Bool { return true }
  override var menuItems: [UIMenuItem] {
    return [
      UIMenuItem(
        title: "Delete",
        action: #selector(PDFSignAnnotationView.menuActionDelete(_:))
      ),
      UIMenuItem(
        title: "Sign",
        action: #selector(PDFSignAnnotationView.menuActionSign(_:))
      )
    ]
  }

  var signImage: UIImageView = {
    var image = UIImageView()
    image.contentMode = .scaleAspectFit
    image.backgroundColor = UIColor.clear
    return image
  }()


  override var frame: CGRect {
    didSet {
      signImage.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }
  }

  convenience init(parent: UXMSignAnnotation) {

    self.init()

    self.parent = parent
    self.delegate = parent
    self.frame = parent.rect
    self.signImage.image = parent.image

    signController.delegate = parent

    self.signImage.backgroundColor = UIColor.clear
    self.signImage.isUserInteractionEnabled = false
    self.backgroundColor = UIColor.clear

    self.addSubview(signImage)
  }

  @objc func menuActionSign(_ sender: Any!) {
    self.delegate?.resizableViewDidSelectAction(view: self, action: "sign")

    self.isLocked = true
    self.signImage.isUserInteractionEnabled = true
    self.signImage.becomeFirstResponder()
    self.addSignature()
  }

  @objc func addSignature() {


    let nvc = UINavigationController(rootViewController: signController)
    nvc.modalPresentationStyle = .formSheet
    nvc.preferredContentSize = CGSize(width: 640, height: 300)
    UIViewController.topController()?.present(nvc, animated: true)
  }

  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

    if action == #selector(menuActionSign(_:)) {
      return true
    }
    return super.canPerformAction(action, withSender: sender)
  }
}

extension UXMSignAnnotation: UXMFormSignatureDelegate {
  func completedSignatureDrawing(field: UXMFormFieldSignatureCaptureView) {

    if let image = field.getSignature() {
      self.image = image
    }

    self.view.isLocked = false
  }
}
