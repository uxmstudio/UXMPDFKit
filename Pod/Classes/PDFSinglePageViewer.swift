//
//  PDFSinglePageViewer.swift
//  Pods
//
//  Created by Chris Anderson on 3/6/16.
//
//

import UIKit

public protocol PDFSinglePageViewerProtocol {
    
    func singlePageViewer(collectionView: PDFSinglePageViewer, didDisplayPage page:Int)
}

public class PDFSinglePageViewer: UICollectionView {
    
    
    public private(set) var currentPage = 0
    public var singlePageDelegate:PDFSinglePageViewerProtocol
    
    private var document:PDFDocument
    private var bookmarkedPages:[String]?
    
    func displayPage(page: Int, animated: Bool) {
        
    }
    
    
    
    
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
    
}

extension PDFSinglePageViewer: UICollectionViewDataSource {
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.document.pageCount
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
    }
}

extension PDFSinglePageViewer: UICollectionViewDelegate {
    
}

extension PDFSinglePageViewer: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var size = self.bounds.size
        size.height -= self.contentInset.bottom + self.contentInset.top + 1
        
        return size
    }
}

extension PDFSinglePageViewer: UIScrollViewDelegate {
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.didDisplayPage(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.didDisplayPage(scrollView)
    }
    
    func didDisplayPage(scrollView: UIScrollView) {
        let page:Int = Int((scrollView.contentOffset.x + scrollView.frame.size.width) / scrollView.frame.size.width)
        self.singlePageDelegate.singlePageViewer(self, didDisplayPage: page)
    }
}




public class PDFSinglePageCell:UICollectionViewCell {
    
    private var _pageContentView:PDFPageContentView?
    public var pageContentView:PDFPageContentView? {
        get {
            return self._pageContentView
        }
        set {
            if let pageContentView = self._pageContentView {
                self.removeConstraints(self.constraints)
                pageContentView.removeFromSuperview()
            }
            if let pageContentView = newValue{
                self._pageContentView = pageContentView
                self.contentView.addSubview(pageContentView)
            }
            
        }
    }
    
    override public func prepareForReuse() {
        
        self.pageContentView = nil
    }
    
}