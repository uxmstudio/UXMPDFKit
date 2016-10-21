//
//  PDFSinglePageViewer.swift
//  Pods
//
//  Created by Chris Anderson on 3/6/16.
//
//

import UIKit

public protocol PDFSinglePageViewerDelegate {
    
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, didDisplayPage page:Int)
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, loadedContent content:PDFPageContentView)
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, selectedAction action:PDFAction)
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, tapped recognizer: UITapGestureRecognizer)
}

open class PDFSinglePageViewer: UICollectionView {
    
    open var singlePageDelegate: PDFSinglePageViewerDelegate?
    
    open var document: PDFDocument?
    fileprivate var bookmarkedPages: [String]?
    
    public init(frame: CGRect, document: PDFDocument) {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        
        self.document = document
        
        super.init(frame: frame, collectionViewLayout: layout)
        
        setupCollectionView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        
        super.init(coder: aDecoder)
        self.collectionViewLayout = layout
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        
        self.isPagingEnabled = true
        self.backgroundColor = UIColor.groupTableViewBackground
        self.showsHorizontalScrollIndicator = false
        self.register(PDFSinglePageCell.self, forCellWithReuseIdentifier: "ContentCell")
        
        self.delegate = self
        self.dataSource = self
        
        guard let document = self.document else { return }
        
        self.displayPage(document.currentPage, animated: false)
        
        if let pageContentView = self.getPageContent(document.currentPage) {
            self.singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
        }
    }
    
    open func indexForPage(_ page: Int) -> Int {
        
        var currentPage = page - 1
        if currentPage <= 0 {
            currentPage = 0
        }
        if let document = self.document , currentPage > document.pageCount {
            currentPage = document.pageCount - 1
        }
        return currentPage
    }
    
    open func displayPage(_ page: Int, animated: Bool) {
        
        let currentPage = self.indexForPage(page)
        let indexPath = IndexPath(item: currentPage, section: 0)
        self.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    open func getPageContent(_ page: Int) -> PDFPageContentView? {
        if self.document == nil { return nil }
        let currentPage = self.indexForPage(page)
        if let cell = self.collectionView(self, cellForItemAt: IndexPath(item: currentPage, section: 0)) as? PDFSinglePageCell,
            let pageContentView = cell.pageContentView {
            return pageContentView
        }
        return nil
    }
}

extension PDFSinglePageViewer: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let document = self.document else {
            return 0
        }
        return document.pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:PDFSinglePageCell = self.dequeueReusableCell(withReuseIdentifier: "ContentCell", for: indexPath) as! PDFSinglePageCell
        
        var contentSize:CGRect = CGRect.zero
        contentSize.size = self.collectionView(collectionView, layout: self.collectionViewLayout, sizeForItemAt: indexPath)
        
        let page = (indexPath as NSIndexPath).row + 1
        
        cell.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        cell.pageContentView = PDFPageContentView(frame: contentSize, document: self.document!, page: page)
        cell.pageContentView?.contentDelegate = self
        
        return cell
    }
}

extension PDFSinglePageViewer: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let pdfCell = cell as! PDFSinglePageCell
        if let pageContentView = pdfCell.pageContentView {
            self.singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
        }
    }
}

extension PDFSinglePageViewer: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size = self.bounds.size
        size.height -= self.contentInset.bottom + self.contentInset.top + 1
        
        return size
    }
}

extension PDFSinglePageViewer: UIScrollViewDelegate {
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didDisplayPage(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.didDisplayPage(scrollView)
    }
    
    func didDisplayPage(_ scrollView: UIScrollView) {
        let page: Int = Int((scrollView.contentOffset.x + scrollView.frame.size.width) / scrollView.frame.size.width)
        self.singlePageDelegate?.singlePageViewer(self, didDisplayPage: page)
    }
}

extension PDFSinglePageViewer: PDFPageContentViewDelegate {
    
    public func contentView(_ contentView: PDFPageContentView, didSelectAction action: PDFAction) {
        
        if let singlePageDelegate = singlePageDelegate {
            singlePageDelegate.singlePageViewer(self, selectedAction: action)
        }
        else if let action = action as? PDFActionGoTo {
            self.displayPage(action.pageIndex, animated: true)
        }
    }
    
    public func contentView(_ contentView: PDFPageContentView, tapped recognizer: UITapGestureRecognizer) {
        singlePageDelegate?.singlePageViewer(self, tapped: recognizer)
    }
}




open class PDFSinglePageCell:UICollectionViewCell {
    
    fileprivate var _pageContentView: PDFPageContentView?
    open var pageContentView: PDFPageContentView? {
        get {
            return self._pageContentView
        }
        set {
            if let pageContentView = self._pageContentView {
                self.removeConstraints(self.constraints)
                pageContentView.removeFromSuperview()
            }
            if let pageContentView = newValue {
                self._pageContentView = pageContentView
                self.contentView.addSubview(pageContentView)
            }
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override open func prepareForReuse() {
        
        self.pageContentView = nil
    }
    
}
