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

    var contentView:PDFPageContent
    var containerView:UIView
    
    open var page:Int
    open var contentDelegate: PDFPageContentViewDelegate?
    open var viewDidZoom:((CGFloat) -> Void)?
    fileprivate var PDFPageContentViewContext = 0
    fileprivate var previousScale:CGFloat = 1.0
    
    let bottomKeyboardPadding:CGFloat = 20.0
    
    init(frame:CGRect, document: PDFDocument, page:Int) {
        
        self.page = page
        self.contentView = PDFPageContent(document: document, page: page)
        
        self.containerView = UIView(frame: self.contentView.bounds)
        self.containerView.isUserInteractionEnabled = true
        self.containerView.contentMode = .redraw
        self.containerView.backgroundColor = UIColor.white
        self.containerView.autoresizesSubviews = true
        self.containerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        super.init(frame: frame)
        
        self.scrollsToTop = false
        self.delaysContentTouches = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.contentMode = .redraw
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        self.autoresizesSubviews = false
        self.isPagingEnabled = false
        self.bouncesZoom = true
        self.delegate = self
        self.isScrollEnabled = true
        self.clipsToBounds = true
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentSize = self.contentView.bounds.size
        
        self.containerView.addSubview(self.contentView)
        self.addSubview(self.containerView)
        
        self.updateMinimumMaximumZoom()
        
        self.zoomScale = self.minimumZoomScale
        self.tag = page
        
        
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        let boundsSize = self.bounds.size
        var viewFrame = self.containerView.frame
        
        if viewFrame.size.width < boundsSize.width {
            viewFrame.origin.x = (boundsSize.width - viewFrame.size.width) / 2.0 + self.contentOffset.x
        }
        else {
            viewFrame.origin.x = 0.0
        }
        
        if viewFrame.size.height < boundsSize.height {
            viewFrame.origin.y = (boundsSize.height - viewFrame.size.height) / 2.0 + self.contentOffset.y
        }
        else {
            viewFrame.origin.y = 0.0
        }
        
        self.containerView.frame = viewFrame
        self.contentView.frame = containerView.bounds
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
        
        
        let oldMinimumZoomScale = self.minimumZoomScale
        
        self.updateMinimumMaximumZoom()
        
        if self.zoomScale == oldMinimumZoomScale || self.zoomScale < self.minimumZoomScale {
            self.zoomScale = self.minimumZoomScale
        }
        else if (self.zoomScale > self.maximumZoomScale) {
            self.zoomScale = self.maximumZoomScale
        }
    }
    
    open func processSingleTap(_ recognizer: UITapGestureRecognizer) {
        
        guard let action = self.contentView.processSingleTap(recognizer) else {
            contentDelegate?.contentView(self, tapped: recognizer)
            return
        }
        self.contentDelegate?.contentView(self, didSelectAction: action)
    }
    
    
    //MARK: - Zoom methods
    open func zoomIncrement() {
        
        var zoomScale = self.zoomScale
        
        if zoomScale < self.minimumZoomScale {
            zoomScale /= 2.0
            
            if zoomScale > self.minimumZoomScale {
                zoomScale = self.maximumZoomScale
            }
            
            self.setZoomScale(zoomScale, animated: true)
        }
    }
    
    open func zoomDecrement() {
        
        var zoomScale = self.zoomScale
        
        if zoomScale < self.minimumZoomScale {
            zoomScale *= 2.0
            
            if zoomScale > self.minimumZoomScale {
                zoomScale = self.maximumZoomScale
            }
            
            self.setZoomScale(zoomScale, animated: true)
        }
    }
    
    open func zoomReset() {
        if self.zoomScale > self.minimumZoomScale {
            self.zoomScale = self.minimumZoomScale
        }
    }
    
    //MARK: - UIScrollViewDelegate methods
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.viewDidZoom?(scrollView.zoomScale)
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
        
        var height:CGFloat = 0.0
        if convertedKeyboardEndFrame.height > 0 && show {
            height = convertedKeyboardEndFrame.height + bottomKeyboardPadding
        }

        self.contentInset = UIEdgeInsetsMake(0, 0, height, 0)
    }
    
    
    //MARK: - Helper methods
    static func zoomScaleThatFits(_ target: CGSize, source:CGSize) -> CGFloat {
        
        let widthScale:CGFloat = target.width / source.width
        let heightScale:CGFloat = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }
    
    func updateMinimumMaximumZoom() {
        self.previousScale = self.zoomScale
        let targetRect = self.bounds.insetBy(dx: 0, dy: 0)
        let zoomScale = PDFPageContentView.zoomScaleThatFits(targetRect.size, source: self.contentView.bounds.size)
        
        self.minimumZoomScale = zoomScale
        self.maximumZoomScale = zoomScale * 16.0
    }
}
