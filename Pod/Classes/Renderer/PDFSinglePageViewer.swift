//
//  PDFSinglePageViewer.swift
//  Pods
//
//  Created by Chris Anderson on 3/6/16.
//
//

import UIKit

public protocol PDFSinglePageViewerDelegate {
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, didDisplayPage page: Int)
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, loadedContent content: PDFPageContentView)
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, selectedAction action: PDFAction)
    func singlePageViewer(_ collectionView: PDFSinglePageViewer, tapped recognizer: UITapGestureRecognizer)
}

open class PDFSinglePageViewer: UICollectionView {
    open var singlePageDelegate: PDFSinglePageViewerDelegate?
    
    open var document: PDFDocument?
    
    private static var flowLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        return layout
    }
    
    public init(frame: CGRect, document: PDFDocument) {
        self.document = document
        
        super.init(frame: frame, collectionViewLayout: PDFSinglePageViewer.flowLayout)
        
        setupCollectionView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        collectionViewLayout = PDFSinglePageViewer.flowLayout
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        isPagingEnabled = true
        backgroundColor = UIColor.groupTableViewBackground
        showsHorizontalScrollIndicator = false
        register(PDFSinglePageCell.self, forCellWithReuseIdentifier: "ContentCell")
        
        delegate = self
        dataSource = self
        
        guard let document = document else { return }
        
        displayPage(document.currentPage, animated: false)
        
        if let pageContentView = getPageContent(document.currentPage) {
            singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
        }
    }
    
    open func indexForPage(_ page: Int) -> Int {
        var currentPage = page - 1
        if currentPage <= 0 {
            currentPage = 0
        }
        if let document = document, currentPage > document.pageCount {
            currentPage = document.pageCount - 1
        }
        return currentPage
    }
    
    open func displayPage(_ page: Int, animated: Bool) {
        let currentPage = indexForPage(page)
        let indexPath = IndexPath(item: currentPage, section: 0)
        self.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    open func getPageContent(_ page: Int) -> PDFPageContentView? {
        if document == nil { return nil }
        let currentPage = indexForPage(page)
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
        let cell = self.dequeueReusableCell(withReuseIdentifier: "ContentCell", for: indexPath) as! PDFSinglePageCell
        
        let contentSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        let contentFrame = CGRect(origin: CGPoint.zero, size: contentSize)
        
        let page = (indexPath as NSIndexPath).row + 1
        
        cell.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        cell.pageContentView = PDFPageContentView(frame: contentFrame, document: document!, page: page)
        cell.pageContentView?.contentDelegate = self
        
        return cell
    }
}

extension PDFSinglePageViewer: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let pdfCell = cell as? PDFSinglePageCell, let pageContentView = pdfCell.pageContentView {
            singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
        }
    }
}

extension PDFSinglePageViewer: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        switch flowLayout.scrollDirection {
        case .horizontal:
            var size = bounds.size
            let contentInsetHeight = contentInset.bottom + contentInset.top + 1
            size.height -= contentInsetHeight
            return size
        case .vertical:
            return bounds.size
        }
    }
}

extension PDFSinglePageViewer: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didDisplayPage(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didDisplayPage(scrollView)
    }
    
    private func didDisplayPage(_ scrollView: UIScrollView) {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let page: Int
        switch flowLayout.scrollDirection {
        case .horizontal:
            page = Int((scrollView.contentOffset.x + scrollView.frame.width) / scrollView.frame.width)
        case .vertical:
            page = Int((scrollView.contentOffset.y + scrollView.frame.height) / scrollView.frame.height)
        }
        singlePageDelegate?.singlePageViewer(self, didDisplayPage: page)
        
        let indexPath = IndexPath(row: page - 1, section: 0)
        if let cell = cellForItem(at: indexPath) as? PDFSinglePageCell {
            if let pageContentView = cell.pageContentView {
                singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
            }
        }
    }
}

extension PDFSinglePageViewer: PDFPageContentViewDelegate {
    public func contentView(_ contentView: PDFPageContentView, didSelectAction action: PDFAction) {
        if let singlePageDelegate = singlePageDelegate {
            singlePageDelegate.singlePageViewer(self, selectedAction: action)
        } else if let action = action as? PDFActionGoTo {
            displayPage(action.pageIndex, animated: true)
        }
    }
    
    public func contentView(_ contentView: PDFPageContentView, tapped recognizer: UITapGestureRecognizer) {
        singlePageDelegate?.singlePageViewer(self, tapped: recognizer)
    }
}

open class PDFSinglePageCell: UICollectionViewCell {
    private var _pageContentView: PDFPageContentView?
    
    open var pageContentView: PDFPageContentView? {
        get {
            return _pageContentView
        }
        set {
            if let pageContentView = _pageContentView {
                removeConstraints(constraints)
                pageContentView.removeFromSuperview()
            }
            if let pageContentView = newValue {
                _pageContentView = pageContentView
                contentView.addSubview(pageContentView)
            }
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override open func prepareForReuse() {
        pageContentView = nil
    }
    
}
