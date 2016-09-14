//
//  PDFPageScrubber.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

public protocol PDFPageScrubberDelegate {
    
    func scrubber(_ scrubber:PDFPageScrubber, selectedPage:Int)
}

open class PDFPageScrubber: UIToolbar {
    
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
    
    var enableTimer:Timer?
    var trackTimer:Timer?
    
    lazy var containerView:UIView = {
        
        let containerWidth:CGFloat = UIScreen.main.bounds.size.width
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth - self.pageNumberSpace * 2, height: 44.0))
        containerView.autoresizesSubviews = false
        containerView.isUserInteractionEnabled = false
        containerView.contentMode = .redraw
        containerView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        containerView.backgroundColor = UIColor.clear
        
        return containerView
    }()
    
    lazy var pageNumberView:UIView = {
       
        var numberY:CGFloat = 0.0 - (self.pageNumberHeight + self.pageNumberSpace)
        var numberX:CGFloat = (self.containerView.bounds.size.width - self.pageNumberWidth) / 2.0
        var numberRect:CGRect  = CGRect(x: numberX, y: numberY, width: self.pageNumberWidth, height: self.pageNumberHeight)
        
        var pageNumberView = UIView(frame: numberRect)
        
        pageNumberView.autoresizesSubviews = false
        pageNumberView.isUserInteractionEnabled = false
        pageNumberView.clipsToBounds = true
        pageNumberView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        pageNumberView.layer.cornerRadius = 3.0
        
        return pageNumberView
    }()
    
    lazy var pageNumberLabel:UILabel = {
       
        let textRect:CGRect = self.pageNumberView.bounds.insetBy(dx: 4.0, dy: 2.0)

        var pageNumberLabel = UILabel(frame: textRect)
        
        pageNumberLabel.autoresizesSubviews = false
        pageNumberLabel.autoresizingMask = UIViewAutoresizing()
        pageNumberLabel.textAlignment = .center
        pageNumberLabel.backgroundColor = UIColor.clear
        pageNumberLabel.textColor = UIColor.darkText
        pageNumberLabel.font = UIFont.systemFont(ofSize: 16.0)
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
        
        let pageNumberToolbar = UIToolbar(frame: self.pageNumberView.bounds.insetBy(dx: -2, dy: -2))
        self.pageNumberView.addSubview(pageNumberToolbar)
        self.pageNumberView.addSubview(pageNumberLabel)

        self.containerView.addSubview(pageNumberView)
        
        self.scrubber = PDFPageScrubberTrackControl(frame: self.containerView.bounds)
        
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberTouchDown(_:)), for: .touchDown)
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberValueChanged(_:)), for: .valueChanged)
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberTouchUp(_:)), for: .touchUpInside)
        self.scrubber.addTarget(self, action: #selector(PDFPageScrubber.scrubberTouchUp(_:)), for: .touchUpOutside)
        
        self.containerView.addSubview(self.scrubber)
        
        self.updatePageNumberText(self.document.currentPage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    open override func layoutSubviews() {
        
        let containerWidth:CGFloat = UIScreen.main.bounds.size.width
        self.containerView.frame = CGRect(x: 0, y: 0, width: containerWidth - self.pageNumberSpace * 2, height: 44.0)
        
        super.layoutSubviews()
        
        var controlRect:CGRect = containerView.bounds.insetBy(dx: 4.0, dy: 0.0)
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
            
            let thumbRect = CGRect(x: thumbX, y: thumbY, width: thumbLargeWidth, height: thumbLargeHeight)
            
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
        var thumbRect = CGRect(x: thumbX, y: thumbY, width: thumbSmallWidth, height: thumbSmallHeight)
        
        var thumbsToHide = self.thumbViews
        
        for thumb in 0..<thumbs {
            
            var page:Int = Int(stride * CGFloat(thumb) + 1)
            if page > pages {
                page = pages
            }
            
            if let smallThumbView = self.thumbViews[page] {
                
                smallThumbView.isHidden = false
                thumbsToHide.removeValue(forKey: page)
                
                if !smallThumbView.frame.equalTo(thumbRect) {
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
            thumb.isHidden = true
        }
    }
    
    
    open func updateScrubber() {
        self.updatePagebarViews()
    }
    
    open func updatePagebarViews() {
        
        let page = self.document.currentPage
        
        self.updatePageNumberText(page)
        self.updatePageThumbView(page)
    }
    
    func updatePageNumberText(_ page: Int) {
        
        if page != self.pageNumberLabel.tag {
            
            let pages = document.pageCount

            self.pageNumberLabel.text = "\(page) of \(pages)"
            self.pageNumberLabel.tag = page
        }
    }
    
    func updatePageThumbView(_ page: Int) {
        
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
                pageThumbView.showImage(self.document, page: page)
            }
        }
    }
    
    
    
    func trackTimerFired(_ timer: Timer) {
        self.trackTimer?.invalidate()
        self.trackTimer = nil
        if self.scrubber.tag != document.currentPage {
            self.scrubberDelegate?.scrubber(self, selectedPage: self.scrubber.tag)
        }
    }
    
    func enableTimerFired(_ timer: Timer) {
        self.enableTimer?.invalidate()
        self.enableTimer = nil
        self.scrubber.isUserInteractionEnabled = true
    }
    
    func restartTrackTimer() {
        
        if trackTimer != nil {
            trackTimer?.invalidate()
            trackTimer = nil
        }
        trackTimer = Timer.scheduledTimer(timeInterval: 0.25,
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

        enableTimer = Timer.scheduledTimer(timeInterval: 0.25,
                                                             target: self,
                                                             selector: #selector(PDFPageScrubber.enableTimerFired(_:)),
                                                             userInfo: nil,
                                                             repeats: false)
    }
    
    
    
    func scrubberPageNumber(_ scrubber: PDFPageScrubberTrackControl) -> Int {
        
        let controlWidth:CGFloat = scrubber.bounds.size.width
        let stride:CGFloat = controlWidth / CGFloat(document.pageCount)
        let page:Int = Int(scrubber.value / stride)
        
        return page + 1
    }
    
    func scrubberTouchDown(_ scrubber: PDFPageScrubberTrackControl) {
        let page = self.scrubberPageNumber(scrubber)
        
        if page != document.currentPage {
            
            self.updatePageNumberText(page)
            self.updatePageThumbView(page)
            
            self.restartTrackTimer()
        }
        scrubber.tag = page
    }
    
    func scrubberTouchUp(_ scrubber: PDFPageScrubberTrackControl) {
        
        if self.trackTimer != nil {
            self.trackTimer?.invalidate()
            self.trackTimer = nil
        }

        if scrubber.tag != document.currentPage {
            scrubber.isUserInteractionEnabled = false
            self.scrubberDelegate?.scrubber(self, selectedPage: scrubber.tag)
            self.startEnableTimer()
        }
        
        scrubber.tag = 0
    }
    
    func scrubberValueChanged(_ scrubber: PDFPageScrubberTrackControl) {
        
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.autoresizesSubviews = false
        self.isUserInteractionEnabled = true
        self.contentMode = .redraw
        self.autoresizingMask = UIViewAutoresizing()
        self.backgroundColor = UIColor.clear
        self.isExclusiveTouch = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func limitValue(_ x: CGFloat) -> CGFloat {
        
        var valueX = x
        let minX:CGFloat = self.bounds.origin.x
        let maxX:CGFloat = self.bounds.size.width - 1.0
        
        if valueX < minX {
            valueX = minX
        }
        
        if valueX > maxX {
            valueX = maxX
        }
        
        return valueX
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let point = touch.location(in: self)
        self.value = self.limitValue(point.x)
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        if self.isTouchInside {
            
            let point = touch.location(in: touch.view)
            let x:CGFloat = self.limitValue(point.x)
            if x != self.value {
                self.value = x
                self.sendActions(for: .valueChanged)
            }
        }
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        
        if let point = touch?.location(in: self) {
            self.value = self.limitValue(point.x)
        }
    }
}

class PDFPageScrubberThumb:PDFThumbnailView {
    
    var small:Bool = false
    var color:UIColor = UIColor.white
    
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
        let background = color.withAlphaComponent(alpha)
        
        self.backgroundColor = background
        self.imageView.backgroundColor = background
        self.imageView.layer.borderColor = UIColor.lightGray.cgColor
        self.imageView.layer.borderWidth = 0.5
    }
}
