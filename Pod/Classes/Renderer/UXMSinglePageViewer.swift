//
//  PDFSinglePageViewer.swift
//  Pods
//
//  Created by Chris Anderson on 3/6/16.
//
//

import UIKit

public protocol UXMSinglePageViewerDelegate : class {
    func singlePageViewer(_ collectionView: UXMSinglePageViewer, didDisplayPage page: Int)
    func singlePageViewer(_ collectionView: UXMSinglePageViewer, loadedContent content: UXMPageContentView)
    func singlePageViewer(_ collectionView: UXMSinglePageViewer, selected action: UXMAction)
    func singlePageViewer(_ collectionView: UXMSinglePageViewer, selected annotation: UXMPDFAnnotationView)
    func singlePageViewer(_ collectionView: UXMSinglePageViewer, tapped recognizer: UITapGestureRecognizer)
    func singlePageViewerDidBeginDragging()
    func singlePageViewerDidEndDragging()
}

open class UXMSinglePageFlowLayout: UICollectionViewFlowLayout {
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

open class UXMSinglePageViewer: UICollectionView {

    open weak var singlePageDelegate: UXMSinglePageViewerDelegate?
    open var document: UXMPDFDocument?

    var internalPage: Int = 0

    var scrollDirection: UICollectionView.ScrollDirection {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        return flowLayout.scrollDirection
    }

    private static var flowLayout: UICollectionViewFlowLayout {
        let layout = UXMSinglePageFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        return layout
    }

    public init(frame: CGRect, document: UXMPDFDocument) {
        self.document = document

        super.init(frame: frame, collectionViewLayout: UXMSinglePageViewer.flowLayout)

        setupCollectionView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        collectionViewLayout = UXMSinglePageViewer.flowLayout

        setupCollectionView()
    }

    func setupCollectionView() {
        isPagingEnabled = true
        backgroundColor = UIColor.groupTableViewBackground
        showsHorizontalScrollIndicator = false
        register(UXMSinglePageCell.self, forCellWithReuseIdentifier: "ContentCell")

        delegate = self
        dataSource = self

        guard let document = document else { return }

        displayPage(document.currentPage, animated: false)

        if let pageContentView = getPageContent(document.currentPage) {
            singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
        }
    }

    open func indexForPage(_ page: Int) -> Int? {
        guard let document = document, document.pageCount > 0 else { return nil }
        var currentPage = page - 1
        currentPage = max(currentPage, 0)
        currentPage = min(currentPage, document.pageCount - 1)
        return currentPage
    }

    open func displayPage(_ page: Int, animated: Bool) {
        guard let currentPage = indexForPage(page) else { return }
        let indexPath = IndexPath(item: currentPage, section: 0)
        switch scrollDirection {
        case .horizontal:
            scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        case .vertical:
            scrollToItem(at: indexPath, at: .top, animated: animated)
        }
    }

    open func getPageContent(_ page: Int) -> UXMPageContentView? {
        guard let currentPage = indexForPage(page) else { return nil }
        if let cell = self.collectionView(self, cellForItemAt: IndexPath(item: currentPage, section: 0)) as? UXMSinglePageCell,
            let pageContentView = cell.pageContentView {
            return pageContentView
        }
        return nil
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        self.isScrollEnabled = !(result is ResizableBorderView)
        return result
    }
}

extension UXMSinglePageViewer: UICollectionViewDataSource {
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
        let cell = self.dequeueReusableCell(withReuseIdentifier: "ContentCell", for: indexPath) as! UXMSinglePageCell

        let contentSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        let contentFrame = CGRect(origin: CGPoint.zero, size: contentSize)

        let page = indexPath.row + 1

        cell.pageContentView = UXMPageContentView(frame: contentFrame, document: document!, page: page)
        cell.pageContentView?.contentDelegate = self

        return cell
    }
}

extension UXMSinglePageViewer: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let pdfCell = cell as? UXMSinglePageCell, let pageContentView = pdfCell.pageContentView {
            singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
        }
    }
}

extension UXMSinglePageViewer: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch scrollDirection {
        case .horizontal:
            var size = bounds.size
            let contentInsetHeight: CGFloat
            if #available(iOS 11.0, *) {
                contentInsetHeight = adjustedContentInset.bottom + adjustedContentInset.top + 1
            } else {
                contentInsetHeight = contentInset.bottom + contentInset.top + 1
            }
            size.height -= contentInsetHeight
            return size
        case .vertical:
            let page = indexPath.row + 1
            let contentViewSize = UXMPageContentView(frame: bounds, document: document!, page: page).contentSize

            // Find proper aspect ratio so that cell is full width
            let widthMultiplier: CGFloat
            let heightMultiplier: CGFloat
            if contentViewSize.width == bounds.width {
                widthMultiplier = bounds.height / contentViewSize.height
                heightMultiplier = 1
            } else if contentViewSize.height == bounds.height {
                heightMultiplier = bounds.width / contentViewSize.width
                widthMultiplier = 1
            } else {
                fatalError()
            }

            return CGSize(width: bounds.size.width * widthMultiplier, height: bounds.size.height * heightMultiplier)
        }
    }
}

extension UXMSinglePageViewer: UIScrollViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.singlePageDelegate?.singlePageViewerDidBeginDragging()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.singlePageDelegate?.singlePageViewerDidEndDragging()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didDisplayPage(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didDisplayPage(scrollView)
    }

    private func didDisplayPage(_ scrollView: UIScrollView) {
        let page: Int
        switch scrollDirection {
        case .horizontal:
            page = Int((scrollView.contentOffset.x + scrollView.frame.width) / scrollView.frame.width)
        case .vertical:
            let currentlyShownIndexPath = indexPathsForVisibleItems.first ?? IndexPath(item: 0, section: 0)
            page = currentlyShownIndexPath.row + 1
        }

        /// If nothing has changed, dont reload
        if page == internalPage {
            return
        }
        
        internalPage = page

        singlePageDelegate?.singlePageViewer(self, didDisplayPage: page)

        let indexPath = IndexPath(row: page - 1, section: 0)
        if let cell = cellForItem(at: indexPath) as? UXMSinglePageCell {
            if let pageContentView = cell.pageContentView {
                singlePageDelegate?.singlePageViewer(self, loadedContent: pageContentView)
            }
        }
    }
}

extension UXMSinglePageViewer: UXMPageContentViewDelegate {
    public func contentView(_ contentView: UXMPageContentView, didSelect action: UXMAction) {
        if let singlePageDelegate = singlePageDelegate {
            singlePageDelegate.singlePageViewer(self, selected: action)
        } else if let action = action as? UXMActionGoTo {
            displayPage(action.pageIndex, animated: true)
        }
    }

    public func contentView(_ contentView: UXMPageContentView, didSelect annotation: UXMPDFAnnotationView) {
        singlePageDelegate?.singlePageViewer(self, selected: annotation)
    }

    public func contentView(_ contentView: UXMPageContentView, tapped recognizer: UITapGestureRecognizer) {
        singlePageDelegate?.singlePageViewer(self, tapped: recognizer)
    }

    public func contentView(_ contentView: UXMPageContentView, doubleTapped recognizer: UITapGestureRecognizer) {}
}
