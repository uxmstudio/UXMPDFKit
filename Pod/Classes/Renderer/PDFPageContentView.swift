//
//  PDFPageContentView.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

public protocol PDFPageContentViewDelegate {
    
    func contentView(contentView: PDFPageContentView, didSelectAction action: PDFAction)
}

public class PDFPageContentView: UIScrollView, UIScrollViewDelegate {

    var contentView:PDFPageContent
    var containerView:UIView
    
    public var page:Int
    public var contentDelegate: PDFPageContentViewDelegate?
    public var viewDidZoom:((CGFloat) -> Void)?
    private var PDFPageContentViewContext = 0
    private var previousScale:CGFloat = 1.0
    
    let bottomKeyboardPadding:CGFloat = 20.0
    
    init(frame:CGRect, document: PDFDocument, page:Int) {
        
        self.page = page
        self.contentView = PDFPageContent(document: document, page: page)
        
        self.containerView = UIView(frame: self.contentView.bounds)
        self.containerView.userInteractionEnabled = true
        self.containerView.contentMode = .Redraw
        self.containerView.backgroundColor = UIColor.whiteColor()
        self.containerView.autoresizesSubviews = true
        self.containerView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        super.init(frame: frame)
        
        self.scrollsToTop = false
        self.delaysContentTouches = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.contentMode = .Redraw
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = true
        self.autoresizesSubviews = false
        self.pagingEnabled = false
        self.bouncesZoom = true
        self.delegate = self
        self.scrollEnabled = true
        self.clipsToBounds = true
        self.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentSize = self.contentView.bounds.size
        
        self.containerView.addSubview(self.contentView)
        self.addSubview(self.containerView)
        
        self.updateMinimumMaximumZoom()
        
        self.zoomScale = self.minimumZoomScale
        self.tag = page
        
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(PDFPageContentView.keyboardWillShowNotification(_:)),
            name: UIKeyboardWillShowNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(PDFPageContentView.keyboardWillHideNotification(_:)),
            name: UIKeyboardWillHideNotification,
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override public func layoutSubviews() {
        
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
    
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard context == &PDFPageContentViewContext else {
            return
        }
        
        guard let keyPath = keyPath where keyPath == "frame" else {
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
    
    public func processSingleTap(recognizer: UITapGestureRecognizer) {
        
        guard let action = self.contentView.processSingleTap(recognizer) else { return }
        self.contentDelegate?.contentView(self, didSelectAction: action)
    }
    
    
    //MARK: - Zoom methods
    public func zoomIncrement() {
        
        var zoomScale = self.zoomScale
        
        if zoomScale < self.minimumZoomScale {
            zoomScale /= 2.0
            
            if zoomScale > self.minimumZoomScale {
                zoomScale = self.maximumZoomScale
            }
            
            self.setZoomScale(zoomScale, animated: true)
        }
    }
    
    public func zoomDecrement() {
        
        var zoomScale = self.zoomScale
        
        if zoomScale < self.minimumZoomScale {
            zoomScale *= 2.0
            
            if zoomScale > self.minimumZoomScale {
                zoomScale = self.maximumZoomScale
            }
            
            self.setZoomScale(zoomScale, animated: true)
        }
    }
    
    public func zoomReset() {
        if self.zoomScale > self.minimumZoomScale {
            self.zoomScale = self.minimumZoomScale
        }
    }
    
    //MARK: - UIScrollViewDelegate methods
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        self.viewDidZoom?(scrollView.zoomScale)
    }
    
    
    func keyboardWillShowNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification, show: true)
    }
    
    func keyboardWillHideNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification, show: false)
    }
    
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification, show:Bool) {
        let userInfo = notification.userInfo!
        
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = self.convertRect(keyboardEndFrame, fromView: self.window)
        
        var height:CGFloat = 0.0
        if convertedKeyboardEndFrame.height > 0 && show {
            height = convertedKeyboardEndFrame.height + bottomKeyboardPadding
        }

        self.contentInset = UIEdgeInsetsMake(0, 0, height, 0)
    }
    
    
    //MARK: - Helper methods
    static func zoomScaleThatFits(target: CGSize, source:CGSize) -> CGFloat {
        
        let widthScale:CGFloat = target.width / source.width
        let heightScale:CGFloat = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }
    
    func updateMinimumMaximumZoom() {
        self.previousScale = self.zoomScale
        let targetRect = CGRectInset(self.bounds, 0, 0)
        let zoomScale = PDFPageContentView.zoomScaleThatFits(targetRect.size, source: self.contentView.bounds.size)
        
        self.minimumZoomScale = zoomScale
        self.maximumZoomScale = zoomScale * 16.0
    }
}