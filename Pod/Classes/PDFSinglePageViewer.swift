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
    public var singlePageDelegate:PDFSinglePageViewerProtocol?
    
    public var document:PDFDocument?
    private var bookmarkedPages:[String]?
    
    public init(frame: CGRect, document: PDFDocument) {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        
        self.document = document
        
        super.init(frame: frame, collectionViewLayout: layout)
        
        setupCollectionView()
    }

    required public init?(coder aDecoder: NSCoder) {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        
        super.init(coder: aDecoder)
        self.collectionViewLayout = layout
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        
        self.pagingEnabled = true
        self.backgroundColor = UIColor.groupTableViewBackgroundColor()
        self.showsHorizontalScrollIndicator = false
        self.registerClass(PDFSinglePageCell.self, forCellWithReuseIdentifier:"ContentCell")
        
        self.delegate = self
        self.dataSource = self
    }
    
    
    func displayPage(page: Int, animated: Bool) {
        
        let indexPath = NSIndexPath(forItem: (page - 1), inSection: 0)
        self.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: animated)
    }
}

extension PDFSinglePageViewer: UICollectionViewDataSource {
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let document = self.document else {
            return 0
        }
        return document.pageCount
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:PDFSinglePageCell = self.dequeueReusableCellWithReuseIdentifier("ContentCell", forIndexPath: indexPath) as! PDFSinglePageCell
        
        var contentSize:CGRect = CGRectZero
        contentSize.size = self.collectionView(collectionView, layout: self.collectionViewLayout, sizeForItemAtIndexPath: indexPath)
        
        let page = indexPath.row + 1
        
        cell.contentView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        cell.pageContentView = PDFPageContentView(frame: contentSize, document: self.document!, page: page)
        
        return cell
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
        self.singlePageDelegate?.singlePageViewer(self, didDisplayPage: page)
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