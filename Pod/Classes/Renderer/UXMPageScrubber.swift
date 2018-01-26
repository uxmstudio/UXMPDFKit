//
//  UXMPageScrubber.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

public protocol UXMPageScrubberDelegate : class {
    func scrubber(_ scrubber: UXMPageScrubber, selectedPage: Int)
}

open class UXMPageScrubber: UIToolbar {
    let document: UXMPDFDocument
    var scrubber = UXMPageScrubberTrackControl()
    
    open weak var scrubberDelegate: UXMPageScrubberDelegate?
    let thumbBackgroundColor = UIColor.white.withAlphaComponent(0.7)
    
    let thumbSmallGap: CGFloat = 2.0
    let thumbSmallWidth: CGFloat = 22.0
    let thumbSmallHeight: CGFloat = 28.0
    let thumbLargeWidth: CGFloat = 32.0
    let thumbLargeHeight: CGFloat = 36.0
    
    let pageNumberWidth: CGFloat = 96.0
    let pageNumberHeight: CGFloat = 30.0
    let pageNumberSpace: CGFloat = 20.0
    
    var thumbViews: [Int: UXMThumbnailView] = [:]
    
    var pageThumbView: UXMPageScrubberThumb?
    
    var enableTimer: Timer?
    var trackTimer: Timer?
    
    lazy var containerView: UIView = {
        let containerWidth = UIScreen.main.bounds.size.width
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth - self.pageNumberSpace * 2, height: 44.0))
        containerView.autoresizesSubviews = false
        containerView.isUserInteractionEnabled = false
        containerView.contentMode = .redraw
        containerView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        containerView.backgroundColor = UIColor.clear
        
        return containerView
    }()
    
    lazy var pageNumberView: UIView = {
        let numberY = 0.0 - (self.pageNumberHeight + self.pageNumberSpace)
        let numberX = (self.containerView.bounds.size.width - self.pageNumberWidth) / 2.0
        let numberRect = CGRect(x: numberX, y: numberY, width: self.pageNumberWidth, height: self.pageNumberHeight)
        
        let pageNumberView = UIView(frame: numberRect)
        
        pageNumberView.autoresizesSubviews = false
        pageNumberView.isUserInteractionEnabled = false
        pageNumberView.clipsToBounds = true
        pageNumberView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        pageNumberView.layer.cornerRadius = 3.0
        
        return pageNumberView
    }()
    
    lazy var pageNumberLabel: UILabel = {
        let textRect = self.pageNumberView.bounds.insetBy(dx: 4.0, dy: 2.0)

        let pageNumberLabel = UILabel(frame: textRect)
        
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
    
    public init(frame: CGRect, document: UXMPDFDocument) {
        self.document = document
        
        super.init(frame: frame)

        clipsToBounds = false
        
        let containerItem:UIBarButtonItem = UIBarButtonItem(customView: containerView)
        setItems([containerItem], animated: false)
        
        let pageNumberToolbar = UIToolbar(frame: pageNumberView.bounds.insetBy(dx: -2, dy: -2))
        pageNumberView.addSubview(pageNumberToolbar)
        pageNumberView.addSubview(pageNumberLabel)

        containerView.addSubview(pageNumberView)
        
        scrubber = UXMPageScrubberTrackControl(frame: containerView.bounds)
        
        scrubber.addTarget(self, action: #selector(UXMPageScrubber.scrubberTouchDown(_:)), for: .touchDown)
        scrubber.addTarget(self, action: #selector(UXMPageScrubber.scrubberValueChanged(_:)), for: .valueChanged)
        scrubber.addTarget(self, action: #selector(UXMPageScrubber.scrubberTouchUp(_:)), for: .touchUpInside)
        scrubber.addTarget(self, action: #selector(UXMPageScrubber.scrubberTouchUp(_:)), for: .touchUpOutside)
        
        containerView.addSubview(scrubber)
        
        updatePageNumberText(document.currentPage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    open override func layoutSubviews() {
        let containerWidth = UIScreen.main.bounds.size.width
        containerView.frame = CGRect(x: 0, y: 0, width: containerWidth - pageNumberSpace * 2, height: 44.0)
        
        super.layoutSubviews()
        
        var controlRect = containerView.bounds.insetBy(dx: 4.0, dy: 0.0)
        let thumbWidth = thumbSmallWidth + thumbSmallGap
        var thumbs = Int(controlRect.size.width / thumbWidth)
        let pages = document.pageCount
        
        if thumbs > pages {
            thumbs = pages
        }
        
        let controlWidth = CGFloat(thumbs) * thumbWidth - thumbSmallGap
        controlRect.size.width = controlWidth
        
        let widthDelta = containerView.bounds.size.width - controlWidth
        let x = CGFloat(widthDelta / 2.0)
        controlRect.origin.x = x
        scrubber.frame = controlRect
        
        if pageThumbView == nil {
            let heightDelta = controlRect.size.height - thumbLargeHeight
            let thumbY = heightDelta / 2.0
            let thumbX: CGFloat = 0.0
            
            let thumbRect = CGRect(x: thumbX, y: thumbY, width: thumbLargeWidth, height: thumbLargeHeight)
            
            pageThumbView = UXMPageScrubberThumb(frame: thumbRect, small: false, color: thumbBackgroundColor)
            pageThumbView?.layer.zPosition = 1.0
            
            scrubber.addSubview(pageThumbView!)
        }
        
        updatePageThumbView(document.currentPage)
        
        var strideThumbs = thumbs - 1
        if strideThumbs < 1 {
            strideThumbs = 1
        }
        
        let stride = CGFloat(pages) / CGFloat(strideThumbs)
        let heightDelta = controlRect.size.height - thumbSmallHeight
        let thumbY = heightDelta / 2.0
        let thumbX: CGFloat = 0.0
        var thumbRect = CGRect(x: thumbX, y: thumbY, width: thumbSmallWidth, height: thumbSmallHeight)
        
        var thumbsToHide = thumbViews
        
        for thumb in 0..<thumbs {
            
            var page = Int(stride * CGFloat(thumb) + 1)
            if page > pages {
                page = pages
            }
            
            if let smallThumbView = thumbViews[page] {
                smallThumbView.isHidden = false
                thumbsToHide.removeValue(forKey: page)
                
                if !smallThumbView.frame.equalTo(thumbRect) {
                    smallThumbView.frame = thumbRect
                }
            } else {
                let smallThumbView = UXMPageScrubberThumb(frame: thumbRect,
                                                          small: true,
                                                          color: thumbBackgroundColor)
                smallThumbView.showImage(document, page: page)
                scrubber.addSubview(smallThumbView)
                thumbViews[page] = smallThumbView
            }
            
            thumbRect.origin.x += thumbWidth
        }
        
        for thumb in thumbsToHide.values {
            thumb.isHidden = true
        }
    }
    
    
    open func updateScrubber() {
        updatePagebarViews()
    }
    
    open func updatePagebarViews() {
        let page = document.currentPage
        
        updatePageNumberText(page)
        updatePageThumbView(page)
    }
    
    func updatePageNumberText(_ page: Int) {
        if page != pageNumberLabel.tag {
            
            let pages = document.pageCount

            pageNumberLabel.text = "\(page) of \(pages)"
            pageNumberLabel.tag = page
        }
    }
    
    func updatePageThumbView(_ page: Int) {
        let pages = document.pageCount
        
        if pages > 1 {
            let controlWidth = scrubber.bounds.size.width
            let useableWidth = controlWidth - thumbLargeWidth
            
            let stride = useableWidth / CGFloat(pages - 1)
            let x = Int(stride) * (page - 1)
            let pageThumbX = CGFloat(x)
            var pageThumbRect = pageThumbView!.frame
            
            if pageThumbX != pageThumbRect.origin.x {
                pageThumbRect.origin.x = pageThumbX + CGFloat(page - 1)
                pageThumbView?.frame = pageThumbRect
            }
        }
        
        if page != pageThumbView?.tag {
            pageThumbView?.tag = page
            
            if let pageThumbView = pageThumbView {
                pageThumbView.showImage(document, page: page)
            }
        }
    }
    
    @objc func trackTimerFired(_ timer: Timer) {
        trackTimer?.invalidate()
        trackTimer = nil
        if scrubber.tag != document.currentPage {
            scrubberDelegate?.scrubber(self, selectedPage: scrubber.tag)
        }
    }
    
    @objc func enableTimerFired(_ timer: Timer) {
        enableTimer?.invalidate()
        enableTimer = nil
        scrubber.isUserInteractionEnabled = true
    }
    
    func restartTrackTimer() {
        if trackTimer != nil {
            trackTimer?.invalidate()
            trackTimer = nil
        }
        trackTimer = Timer.scheduledTimer(timeInterval: 0.25,
                                          target: self,
                                          selector: #selector(UXMPageScrubber.trackTimerFired(_:)),
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
                                           selector: #selector(UXMPageScrubber.enableTimerFired(_:)),
                                           userInfo: nil,
                                           repeats: false)
    }
    
    func scrubberPageNumber(_ scrubber: UXMPageScrubberTrackControl) -> Int {
        let controlWidth = scrubber.bounds.size.width
        let stride = controlWidth / CGFloat(document.pageCount)
        let page = Int(scrubber.value / stride)
        
        return page + 1
    }
    
    func refreshScrubber(_ scrubber: UXMPageScrubberTrackControl? = nil) {
        let innerScrubber = scrubber != nil ? scrubber : self.scrubber
        guard innerScrubber != nil else { return }
        
        let page = scrubberPageNumber(self.scrubber)
        
        if page != document.currentPage {
            updatePageNumberText(page)
            updatePageThumbView(page)
            
            restartTrackTimer()
        }
        
        innerScrubber!.tag = page
    }
    
    @objc func scrubberTouchDown(_ scrubber: UXMPageScrubberTrackControl) {
        refreshScrubber(scrubber)
    }
    
    @objc func scrubberTouchUp(_ scrubber: UXMPageScrubberTrackControl) {
        if trackTimer != nil {
            trackTimer?.invalidate()
            trackTimer = nil
        }

        if scrubber.tag != document.currentPage {
            scrubber.isUserInteractionEnabled = false
            scrubberDelegate?.scrubber(self, selectedPage: scrubber.tag)
            startEnableTimer()
        }
        
        scrubber.tag = 0
    }
    
    @objc func scrubberValueChanged(_ scrubber: UXMPageScrubberTrackControl) {
        let page = self.scrubberPageNumber(scrubber)
        if page != scrubber.tag {
            updatePageNumberText(page)
            updatePageThumbView(page)
            
            scrubber.tag = page
            
            restartTrackTimer()
        }
    }
}
