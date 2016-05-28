//
//  PDFPageContentView.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

public protocol PDFPageContentViewDelegate {
    
    func contentView(contentView: PDFPageContentView, touchesBegan touches:Set<UITouch>)
}

public class PDFPageContentView: UIScrollView, UIScrollViewDelegate {

    var contentView:PDFPageContent
    var containerView:UIView
    
    public var page:Int
    public var contentDelegate: PDFPageContentViewDelegate?
    private var PDFPageContentViewContext = 0
    
    init(frame:CGRect, document: PDFDocument, page:Int) {
        
        self.page = page
        self.contentView = PDFPageContent(document: document, page: page)
        
        self.containerView = UIView(frame: self.contentView.bounds)
        self.containerView.userInteractionEnabled = false
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
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.contentView.processSingleTap(recognizer)
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
    
    
    //MARK: - UIResponder methods
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
    }
    
    override public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    
    //MARK: - Helper methods
    static func zoomScaleThatFits(target: CGSize, source:CGSize) -> CGFloat {
        
        let widthScale:CGFloat = target.width / source.width
        let heightScale:CGFloat = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }
    
    func updateMinimumMaximumZoom() {
        
        let targetRect = CGRectInset(self.bounds, 0, 0)
        let zoomScale = PDFPageContentView.zoomScaleThatFits(targetRect.size, source: self.contentView.bounds.size)
        
        self.minimumZoomScale = zoomScale
        self.maximumZoomScale = zoomScale * 16.0
    }
}
