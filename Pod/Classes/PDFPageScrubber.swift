//
//  PDFPageScrubber.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

public protocol PDFPageScrubberDelegate {
    
    func scrubber(scrubber:PDFPageScrubber, selectedPage:Int)
}

public class PDFPageScrubber: UIToolbar {
    
    var document:PDFDocument
    var scrubber:PDFPageScrubberTrackControl = PDFPageScrubberTrackControl()
    
    var scrubberDelegate:PDFPageScrubberDelegate?
    var thumbBackgroundColor:UIColor = UIColor(white: 255, alpha: 0.7)
    
    var thumbSmallGap:CGFloat = 2.0
    var thumbSmallWidth:CGFloat = 22.0
    var thumbSmallHeight:CGFloat = 28.0
    var thumbLargeWidth:CGFloat = 32.0
    var thumbLargeHeight:CGFloat = 42.0
    
    var pageNumberWidth:CGFloat = 96.0
    var pageNumberHeight:CGFloat = 30.0
    var pageNumberSpace:CGFloat = 20.0
    
    var thumbViews:[Int:PDFThumbnailView] = [:]
    
    var pageThumbView:PDFPageScrubberThumb?
    
    var enableTimer:NSTimer?
    var trackTimer:NSTimer?
    
    lazy var containerView:UIView = {
        
        let containerWidth:CGFloat = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? UIScreen.mainScreen().bounds.size.width : UIScreen.mainScreen().bounds.size.height
        let containerView = UIView(frame: CGRectMake(0, 0, containerWidth - self.pageNumberSpace * 2, 44.0))
        
        containerView.autoresizesSubviews = false
        containerView.userInteractionEnabled = false
        containerView.contentMode = .Redraw
        containerView.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        containerView.backgroundColor = UIColor.clearColor()
        
        return containerView
    }()
    
    lazy var pageNumberView:UIView = {
       
        var numberY:CGFloat = 0.0 - (self.pageNumberHeight + self.pageNumberSpace)
        var numberX:CGFloat = (self.containerView.bounds.size.width - self.pageNumberWidth) / 2.0
        var numberRect:CGRect  = CGRectMake(numberX, numberY, self.pageNumberWidth, self.pageNumberHeight)
        
        var pageNumberView = UIView(frame: numberRect)
        
        pageNumberView.autoresizesSubviews = false
        pageNumberView.userInteractionEnabled = false
        pageNumberView.clipsToBounds = false
        pageNumberView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        
        return pageNumberView
    }()
    
    lazy var pageNumberLabel:UILabel = {
       
        let textRect:CGRect = CGRectInset(self.pageNumberView.bounds, 4.0, 2.0)

        var pageNumberLabel = UILabel(frame: textRect)
        
        pageNumberLabel.autoresizesSubviews = false
        pageNumberLabel.autoresizingMask = .None
        pageNumberLabel.textAlignment = .Center
        pageNumberLabel.backgroundColor = UIColor.clearColor()
        pageNumberLabel.textColor = UIColor.darkTextColor()
        pageNumberLabel.font = UIFont.systemFontOfSize(16.0)
        pageNumberLabel.adjustsFontSizeToFitWidth = false
        pageNumberLabel.minimumScaleFactor = 0.75
        
        return pageNumberLabel
    }()
    
    
    
    init(frame: CGRect, document: PDFDocument) {
        
        self.document = document
        
        super.init(frame: frame)

        self.clipsToBounds = false
        
        let containerItem:UIBarButtonItem = UIBarButtonItem(customView: self.containerView)
        self.setItems([containerItem], animated: false)
        
        let pageNumberToolbar = UIToolbar(frame: CGRectInset(self.pageNumberView.bounds, -2, -2))
        self.pageNumberView.addSubview(pageNumberToolbar)
        self.pageNumberView.addSubview(pageNumberLabel)

        self.containerView.addSubview(pageNumberView)
        
        self.scrubber = PDFPageScrubberTrackControl(frame: self.containerView.bounds)
        
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberTouchDown(_:)), forControlEvents: .TouchDown)
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberValueChanged(_:)), forControlEvents: .ValueChanged)
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberTouchUp(_:)), forControlEvents: .TouchUpInside)
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberTouchUp(_:)), forControlEvents: .TouchUpOutside)
        
        self.containerView.addSubview(self.scrubber)
        
        self.updatePageNumberText(self.document.currentPage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    

    
    public override func layoutSubviews() {
        
        let containerWidth:CGFloat = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? UIScreen.mainScreen().bounds.size.width : UIScreen.mainScreen().bounds.size.height
        self.containerView.frame = CGRectMake(0, 0, containerWidth - self.pageNumberSpace * 2, 44.0)
        
        super.layoutSubviews()
        
        
        var controlRect:CGRect = CGRectInset(containerView.bounds, 4.0, 0.0)
        let thumbWidth:CGFloat = thumbSmallWidth + thumbSmallGap
        var thumbs:Int = Int(controlRect.size.width / thumbWidth)
        let pages:Int = document.pageCount
        
        if thumbs > pages {
            thumbs = pages
        }
        
        let controlWidth:CGFloat = CGFloat(thumbs) * thumbWidth - thumbSmallGap
        controlRect.size.width = controlWidth
        
        let widthDelta:CGFloat = containerView.bounds.size.width - controlWidth
        let x:Int = Int(widthDelta / 2.0)
        controlRect.origin.x = CGFloat(x)
        self.scrubber.frame = controlRect
        
        if self.pageThumbView == nil {
            
            let heightDelta = controlRect.size.height - thumbLargeHeight
            let thumbY:CGFloat = heightDelta / 2.0
            let thumbX:CGFloat = 0.0
            
            let thumbRect = CGRectMake(thumbX, thumbY, thumbLargeWidth, thumbLargeHeight)
            
            self.pageThumbView = PDFPageScrubberThumb(frame: thumbRect, small: false, color: self.thumbBackgroundColor)
            self.pageThumbView?.layer.zPosition = 1.0
            
            self.scrubber.addSubview(self.pageThumbView!)
        }
        
        self.updatePageThumbView(self.document.currentPage)
        
        var strideThumbs = thumbs - 1
        if strideThumbs < 1 {
            strideThumbs = 1
        }
        
        let stride:CGFloat = CGFloat(pages) / CGFloat(strideThumbs)
        let heightDelta = controlRect.size.height - thumbSmallHeight
        let thumbY:CGFloat = heightDelta / 2.0
        let thumbX:CGFloat = 0.0
        var thumbRect = CGRectMake(thumbX, thumbY, thumbLargeWidth, thumbLargeHeight)
        
        var thumbsToHide = self.thumbViews
        
        for thumb in 0..<thumbs {
            
            var page:Int = Int(stride * CGFloat(thumb) + 1)
            if page > pages {
                page = pages
            }
            
            if let smallThumbView = self.thumbViews[page] {
                
                smallThumbView.hidden = false
                thumbsToHide.removeValueForKey(page)
                
                if !CGRectEqualToRect(smallThumbView.frame, thumbRect) {
                    smallThumbView.frame = thumbRect
                }
            }
            else {
                
                let smallThumbView:PDFPageScrubberThumb = PDFPageScrubberThumb(frame: thumbRect,
                                                                               small: true,
                                                                               color: self.thumbBackgroundColor)
                smallThumbView.showImage(self.document, page: page)
                self.scrubber.addSubview(smallThumbView)
                self.thumbViews[page] = smallThumbView
            }
            
            thumbRect.origin.x += thumbWidth
        }
        
        for thumb in thumbsToHide.values {
            thumb.hidden = true
        }
    }
    
    
    public func updateScrubber() {
        self.updatePagebarViews()
    }
    
    public func updatePagebarViews() {
        
        let page = self.document.currentPage
        
        self.updatePageNumberText(page)
        self.updatePageThumbView(page)
    }
    
    func updatePageNumberText(page: Int) {
        
        if page != self.pageNumberLabel.tag {
            
            let pages = document.pageCount

            self.pageNumberLabel.text = "\(page) of \(pages)"
            self.pageNumberLabel.tag = page
        }
    }
    
    func updatePageThumbView(page: Int) {
        
        let pages = document.pageCount
        
        if pages > 1 {
            
            let controlWidth:CGFloat = self.scrubber.bounds.size.width
            let useableWidth:CGFloat = controlWidth - thumbLargeWidth
            
            let stride = useableWidth / CGFloat(pages - 1)
            let x:Int = Int(stride) * (page - 1)
            let pageThumbX:CGFloat = CGFloat(x)
            var pageThumbRect = pageThumbView!.frame
            
            if pageThumbX != pageThumbRect.origin.x {
                pageThumbRect.origin.x = pageThumbX
                pageThumbView?.frame = pageThumbRect
            }
        }
        
        if page != pageThumbView?.tag {
            
            pageThumbView?.tag = page
            
            if let pageThumbView = self.pageThumbView {
                let smallThumbView:PDFPageScrubberThumb = PDFPageScrubberThumb(frame: pageThumbView.frame,
                                                                               small: true,
                                                                               color: self.thumbBackgroundColor)
                smallThumbView.showImage(self.document, page: page)
            }
        }
    }
    
    
    
    func trackTimerFired(timer: NSTimer) {
        self.trackTimer?.invalidate()
        self.trackTimer = nil
        if self.scrubber.tag != document.currentPage {
            self.scrubberDelegate?.scrubber(self, selectedPage: self.scrubber.tag)
        }
    }
    
    func enableTimerFired(timer: NSTimer) {
        self.enableTimer?.invalidate()
        self.enableTimer = nil
        self.scrubber.userInteractionEnabled = true
    }
    
    func restartTrackTimer() {
        
        if trackTimer != nil {
            trackTimer?.invalidate()
            trackTimer = nil
        }
        trackTimer = NSTimer.scheduledTimerWithTimeInterval(0.25,
                                                            target: self,
                                                            selector: #selector(PDFPageScrubber.trackTimerFired(_:)),
                                                            userInfo: nil,
                                                            repeats: false)
    }
    
    func startEnableTimer() {
        
        if enableTimer != nil {
            enableTimer?.invalidate()
            enableTimer = nil
        }

        enableTimer = NSTimer.scheduledTimerWithTimeInterval(0.25,
                                                             target: self,
                                                             selector: #selector(PDFPageScrubber.enableTimerFired(_:)),
                                                             userInfo: nil,
                                                             repeats: false)
    }
    
    
    
    func scrubberPageNumber(scrubber: PDFPageScrubberTrackControl) -> Int {
        
        let controlWidth:CGFloat = scrubber.bounds.size.width
        let stride:CGFloat = controlWidth / CGFloat(document.pageCount)
        let page:Int = Int(scrubber.value / stride)
        
        return page + 1
    }
    
    func scrubberTouchDown(scrubber: PDFPageScrubberTrackControl) {
        let page = self.scrubberPageNumber(scrubber)
        
        if page != document.currentPage {
            
            self.updatePageNumberText(page)
            self.updatePageThumbView(page)
            
            self.restartTrackTimer()
        }
        scrubber.tag = page
    }
    
    func scrubberTouchUp(scrubber: PDFPageScrubberTrackControl) {
        
        if self.trackTimer != nil {
            self.trackTimer?.invalidate()
            self.trackTimer = nil
        }

        if scrubber.tag != document.currentPage {
            scrubber.userInteractionEnabled = false
            self.scrubberDelegate?.scrubber(self, selectedPage: scrubber.tag)
            self.startEnableTimer()
        }
        
        scrubber.tag = 0
    }
    
    func scrubberValueChanged(scrubber: PDFPageScrubberTrackControl) {
        
        let page = self.scrubberPageNumber(scrubber)
        if page != scrubber.tag {
            
            self.updatePageNumberText(page)
            self.updatePageThumbView(page)
            
            scrubber.tag = page
            
            self.restartTrackTimer()
        }
    }
}

class PDFPageScrubberTrackControl: UIControl {
    
    var value:CGFloat = 0.0
    
    func limitValue(x: CGFloat) -> CGFloat {
        
        let minX:CGFloat = self.bounds.origin.x
        let maxX:CGFloat = self.bounds.size.width - 1.0
        
        if x < minX {
            return minX
        }
        if x > maxX {
            return maxX
        }
        
        return x
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        
        let point = touch.locationInView(self)
        self.value = self.limitValue(point.x)
        return true
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        
        if self.touchInside {
            
            let point = touch.locationInView(touch.view)
            let x:CGFloat = self.limitValue(point.x)
            if x != self.value {
                self.value = x
                self.sendActionsForControlEvents(.ValueChanged)
            }
        }
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        
        if let point = touch?.locationInView(self) {
            self.value = self.limitValue(point.x)
        }
    }
}

class PDFPageScrubberThumb:PDFThumbnailView {
    
    var small:Bool = false
    var color:UIColor = UIColor.whiteColor()
    
    init(frame: CGRect, small: Bool, color: UIColor) {
        
        self.small = small
        self.color = color
        
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    func setupUI() {
        
        let alpha:CGFloat = small ? 0.6 : 0.7
        let background = color.colorWithAlphaComponent(alpha)
        
        self.backgroundColor = background
        self.imageView.backgroundColor = background
        self.imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.imageView.layer.borderWidth = 0.5
    }
}