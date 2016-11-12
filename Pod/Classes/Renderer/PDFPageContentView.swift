//
//  PDFPageContentView.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

public protocol PDFPageContentViewDelegate {
    func contentView(_ contentView: PDFPageContentView, didSelectAction action: PDFAction)
    func contentView(_ contentView: PDFPageContentView, tapped recognizer: UITapGestureRecognizer)
}

open class PDFPageContentView: UIScrollView, UIScrollViewDelegate {
    var contentView: PDFPageContent
    var containerView: UIView
    
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
        
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PDFPageContentView.keyboardWillShowNotification(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PDFPageContentView.keyboardWillHideNotification(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
        
        let singleTapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(PDFPageContentView.processSingleTap(_:))
        )
        singleTapRecognizer.numberOfTouchesRequired = 1
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let boundsSize = bounds.size
        var viewFrame = containerView.frame
        
        if viewFrame.size.width < boundsSize.width {
            viewFrame.origin.x = (boundsSize.width - viewFrame.size.width) / 2.0 + self.contentOffset.x
        } else {
            viewFrame.origin.x = 0.0
        }
        
        if viewFrame.size.height < boundsSize.height {
            viewFrame.origin.y = (boundsSize.height - viewFrame.size.height) / 2.0 + self.contentOffset.y
        } else {
            viewFrame.origin.y = 0.0
        }
        
        containerView.frame = viewFrame
        contentView.frame = containerView.bounds
    }
    
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &PDFPageContentViewContext else {
            return
        }
        
        guard let keyPath = keyPath , keyPath == "frame" else {
            return
        }
        
        guard self == (object as? PDFPageContentView) else {
            return
        }
        
        let oldMinimumZoomScale = minimumZoomScale
        
        updateMinimumMaximumZoom()
        
        if zoomScale == oldMinimumZoomScale || zoomScale < minimumZoomScale {
            zoomScale = minimumZoomScale
        } else if (zoomScale > maximumZoomScale) {
            zoomScale = maximumZoomScale
        }
    }
    
    open func processSingleTap(_ recognizer: UITapGestureRecognizer) {
        guard let action = contentView.processSingleTap(recognizer) else {
            contentDelegate?.contentView(self, tapped: recognizer)
            return
        }
        contentDelegate?.contentView(self, didSelectAction: action)
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
        if zoomScale > minimumZoomScale {
            zoomScale = minimumZoomScale
        }
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

        self.contentInset = UIEdgeInsetsMake(0, 0, height, 0)
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
