//
//  PDFPageContentView.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

public protocol PDFPageContentViewDelegate {
    func contentView(_ contentView: PDFPageContentView, didSelect action: PDFAction)
    func contentView(_ contentView: PDFPageContentView, didSelect annotation: PDFAnnotationView)
    func contentView(_ contentView: PDFPageContentView, tapped recognizer: UITapGestureRecognizer)
}

open class PDFPageContentView: UIScrollView, UIScrollViewDelegate {
    let contentView: PDFPageContent
    let containerView: UIView

    open var pdfContentView: UIView {
        return contentView as UIView
    }

    open var page: Int
    open var contentDelegate: PDFPageContentViewDelegate?
    open var viewDidZoom: ((CGFloat) -> Void)?
    fileprivate var PDFPageContentViewContext = 0
    fileprivate var previousScale: CGFloat = 1.0

    let bottomKeyboardPadding: CGFloat = 20.0

    init(frame: CGRect, document: PDFDocument, page: Int) {
        self.page = page
        contentView = PDFPageContent(document: document, page: page)

        containerView = UIView(frame: contentView.bounds)
        containerView.isUserInteractionEnabled = true
        containerView.contentMode = .redraw
        containerView.backgroundColor = UIColor.white
        containerView.autoresizesSubviews = true
        containerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        super.init(frame: frame)

        scrollsToTop = false
        delaysContentTouches = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentMode = .redraw
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
        autoresizesSubviews = false
        isPagingEnabled = false
        bouncesZoom = true
        delegate = self
        isScrollEnabled = true
        clipsToBounds = true

        autoresizingMask = [.flexibleHeight, .flexibleWidth]

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentSize = contentView.bounds.size

        containerView.addSubview(contentView)
        addSubview(containerView)

        updateMinimumMaximumZoom()

        zoomScale = minimumZoomScale
        tag = page

        self.addObserver(self, forKeyPath: "frame", options: [.new, .old], context: &PDFPageContentViewContext)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PDFPageContentView.keyboardWillShowNotification(_:)),
            name: .UIKeyboardWillShow,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PDFPageContentView.keyboardWillHideNotification(_:)),
            name: .UIKeyboardWillHide,
            object: nil
        )

        let singleTapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(PDFPageContentView.processSingleTap(_:))
        )
        singleTapRecognizer.numberOfTouchesRequired = 1
        singleTapRecognizer.numberOfTapsRequired = 1
        singleTapRecognizer.cancelsTouchesInView = false
        self.addGestureRecognizer(singleTapRecognizer)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)

        self.removeObserver(self, forKeyPath: "frame")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        let boundsSize = bounds.size
        var viewFrame = containerView.frame

        if viewFrame.size.width < boundsSize.width {
            viewFrame.origin.x = (boundsSize.width - viewFrame.size.width) / 2.0 + contentOffset.x
        } else {
            viewFrame.origin.x = 0.0
        }

        if viewFrame.size.height < boundsSize.height {
            viewFrame.origin.y = (boundsSize.height - viewFrame.size.height) / 2.0 + contentOffset.y
        }
        else {
            viewFrame.origin.y = 0.0
        }

        containerView.frame = viewFrame
        contentView.frame = containerView.bounds
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        guard context == &PDFPageContentViewContext,
            let keyPath = keyPath, keyPath == "frame",
            self == (object as? PDFPageContentView) else {
            return
        }

        updateMinimumMaximumZoom()
        self.zoomReset()
    }

    open func processSingleTap(_ recognizer: UITapGestureRecognizer) {
        if let action = contentView.processSingleTap(recognizer) as? PDFAction {
            contentDelegate?.contentView(self, didSelect: action)
        }
        else if let annotation = contentView.processSingleTap(recognizer) as? PDFAnnotationView {
            contentDelegate?.contentView(self, didSelect: annotation)
        }
        else {
            contentDelegate?.contentView(self, tapped: recognizer)
        }
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        self.isScrollEnabled = !(result is ResizableBorderView)
        return result
    }


    //MARK: - Zoom methods
    open func zoomIncrement() {
        var zoomScale = self.zoomScale

        if zoomScale < minimumZoomScale {
            zoomScale /= 2.0

            if zoomScale > minimumZoomScale {
                zoomScale = maximumZoomScale
            }

            setZoomScale(zoomScale, animated: true)
        }
    }

    open func zoomDecrement() {
        var zoomScale = self.zoomScale

        if zoomScale < minimumZoomScale {
            zoomScale *= 2.0

            if zoomScale > minimumZoomScale {
                zoomScale = maximumZoomScale
            }

            setZoomScale(zoomScale, animated: true)
        }
    }

    open func zoomReset() {
        zoomScale = minimumZoomScale

        let offsetX = max((self.bounds.size.width - self.contentSize.width) * 0.5, 0.0)
        let offsetY = max((self.bounds.size.height - self.contentSize.height) * 0.5, 0.0)

        containerView.center = CGPoint(x: self.contentSize.width * 0.5 + offsetX,
                                       y: self.contentSize.height * 0.5 + offsetY)
    }

    //MARK: - UIScrollViewDelegate methods
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        viewDidZoom?(scrollView.zoomScale)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        updateBottomLayoutConstraintWithNotification(notification, show: true)
    }

    func keyboardWillHideNotification(_ notification: Notification) {
        updateBottomLayoutConstraintWithNotification(notification, show: false)
    }

    func updateBottomLayoutConstraintWithNotification(_ notification: Notification, show:Bool) {
        let userInfo = (notification as NSNotification).userInfo!

        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = self.convert(keyboardEndFrame, from: self.window)

        let height: CGFloat
        if convertedKeyboardEndFrame.height > 0 && show {
            height = convertedKeyboardEndFrame.height + bottomKeyboardPadding
        } else {
            height = 0
        }

        contentInset = UIEdgeInsetsMake(0, 0, height, 0)
    }


    //MARK: - Helper methods
    static func zoomScaleThatFits(_ target: CGSize, source: CGSize) -> CGFloat {
        let widthScale = target.width / source.width
        let heightScale = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }

    func updateMinimumMaximumZoom() {
        previousScale = self.zoomScale
        let targetRect = bounds.insetBy(dx: 0, dy: 0)
        let zoomScale = PDFPageContentView.zoomScaleThatFits(targetRect.size, source: contentView.bounds.size)

        minimumZoomScale = zoomScale
        maximumZoomScale = zoomScale * 16.0
    }
}
