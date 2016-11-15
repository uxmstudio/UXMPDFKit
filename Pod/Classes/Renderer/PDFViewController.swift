//
//  PDFViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/7/16.
//
//

import UIKit
import SafariServices

open class PDFViewController: UIViewController {
    
    open var hidesBarsOnTap: Bool = true
    open var showsScrubber: Bool = true {
        didSet {
            pageScrubber.isHidden = !showsScrubber
        }
    }
    open var allowsFormFilling: Bool = true
    open var allowsAnnotations: Bool = true
    open var allowsSharing: Bool = true
    open var isPresentingInModal: Bool = false
    open var scrollDirection: UICollectionViewScrollDirection = .horizontal
    
    var document: PDFDocument!
    
    var shareBarButtonItem: UIBarButtonItem?
    open lazy var shareBarButtonAction: () -> () = { self.showActivitySheet() }
    
    var collectionView: PDFSinglePageViewer!
    var pageScrubber: PDFPageScrubber!
    lazy var formController: PDFFormViewController = PDFFormViewController(document: self.document)
    lazy var annotationController: PDFAnnotationController = PDFAnnotationController(document: self.document, delegate: self)
    
    fileprivate var showingAnnotations = false
    fileprivate var showingFormFilling = true
    
    public init(document: PDFDocument) {
        super.init(nibName: nil, bundle: nil)
        self.document = document
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        pageScrubber = PDFPageScrubber(frame: CGRect(x: 0, y: view.frame.size.height - bottomLayoutGuide.length, width: view.frame.size.width, height: 44.0), document: document)
        pageScrubber.scrubberDelegate = self
        pageScrubber.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView = PDFSinglePageViewer(frame: view.bounds, document: document)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.singlePageDelegate = self
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = scrollDirection
        
        switch scrollDirection {
        case .horizontal:
            collectionView.isPagingEnabled = true
            pageScrubber.isHidden = !showsScrubber
        case .vertical:
            collectionView.isPagingEnabled = false
            pageScrubber.isHidden = true
        }
        
        self.setupUI()
        collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
    }
    
    func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(pageScrubber)
        view.addSubview(annotationController.view)
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        pageScrubber.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pageScrubber.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageScrubber.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageScrubber.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        automaticallyAdjustsScrollViewInsets = false
        
        pageScrubber.sizeToFit()
        
        reloadBarButtons()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length, 0, bottomLayoutGuide.length, 0)
        collectionView.collectionViewLayout.invalidateLayout()
        
        view.layoutSubviews()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.pageScrubber.sizeToFit()
            }, completion: { (context) in
                self.collectionView.displayPage(self.document.currentPage, animated: false)
        })
    }
    
    //MARK: - Private helpers
    fileprivate func scrollTo(page: Int) {
        document.currentPage = page
        collectionView.displayPage(page, animated: false)
        if showsScrubber {
            pageScrubber.updateScrubber()
        }
    }
    
    fileprivate func reloadBarButtons() {
        navigationItem.rightBarButtonItems = rightBarButtons()
        
        if isPresentingInModal {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done",
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(PDFViewController.dismissModal))
        }
    }
    
    fileprivate func rightBarButtons() -> [UIBarButtonItem] {
        var buttons: [UIBarButtonItem] = []
        
        if allowsSharing {
            let shareFormBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(PDFViewController.shareDocument)
            )
            buttons.append(shareFormBarButtonItem)
            self.shareBarButtonItem = shareFormBarButtonItem
        }
        
        buttons.append(UIBarButtonItem(
            image: UIImage.bundledImage("thumbs"),
            style: .plain,
            target: self,
            action: #selector(PDFViewController.showThumbnailView)
            )
        )
        
        
        if allowsAnnotations {
            if showingAnnotations {
                buttons.append(annotationController.highlighterButton)
                buttons.append(annotationController.penButton)
                buttons.append(annotationController.textButton)
                buttons.append(annotationController.undoButton)
            }
            
            buttons.append(PDFBarButton(
                image: UIImage.bundledImage("annot"),
                toggled: showingAnnotations,
                target: self,
                action: #selector(PDFViewController.toggleAnnotations(_:))
                )
            )
        }
        
        return buttons
    }
    
    func toggleAnnotations(_ button: PDFBarButton) {
        showingAnnotations = !showingAnnotations
        reloadBarButtons()
    }
    
    func showActivitySheet() {
        let renderer = PDFRenderController(document: document, controllers: [
            annotationController,
            formController
            ])
        let pdf = renderer.renderOntoPDF()
        
        let items = [pdf]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.modalPresentationStyle = .popover
            let popController = activityVC.popoverPresentationController
            popController?.barButtonItem = shareBarButtonItem
            popController?.permittedArrowDirections = .up
        }
        present(activityVC, animated: true, completion: nil)
    }
    
    func showThumbnailView() {
        let vc = PDFThumbnailViewController(document: document)
        vc.delegate = self
        let nvc = UINavigationController(rootViewController: vc)
        nvc.modalTransitionStyle = .crossDissolve
        present(nvc, animated: true, completion: nil)
    }
    
    func hideBars(state: Bool) {
        navigationController?.setNavigationBarHidden(state, animated: true)
        
        switch scrollDirection {
        case .horizontal:
            if showsScrubber {
                pageScrubber.isHidden = state
            } else {
                pageScrubber.isHidden = true
            }
        case .vertical:
            pageScrubber.isHidden = true
        }
    }
    
    func toggleBars() {
        hideBars(state: navigationController?.isNavigationBarHidden ?? false)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - IBActions
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        self.toggleBars()
    }
    
    func shareDocument() {
        self.shareBarButtonAction()
    }
    
    func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}

extension PDFViewController: PDFAnnotationControllerProtocol {
    public func annotationWillStart(touch: UITouch) -> Int? {
        let tapPoint = touch.location(in: collectionView)
        guard let pageIndex = collectionView.indexPathForItem(at: tapPoint)?.row else { return nil }
        return pageIndex + 1
    }
}


extension PDFViewController: PDFPageScrubberDelegate {
    public func scrubber(_ scrubber: PDFPageScrubber, selectedPage: Int) {
        self.scrollTo(page: selectedPage)
    }
}

extension PDFViewController: PDFSinglePageViewerDelegate {
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, didDisplayPage page: Int) {
        document.currentPage = page
        if showsScrubber {
            pageScrubber.updateScrubber()
        }
    }
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, loadedContent content: PDFPageContentView) {
        if allowsFormFilling {
            formController.showForm(content)
        }
        if allowsAnnotations {
            annotationController.showAnnotations(content)
        }
    }
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, selectedAction action: PDFAction) {
        if let action = action as? PDFActionURL {
            let svc = SFSafariViewController(url: action.url as URL)
            present(svc, animated: true, completion: nil)
        } else if let action = action as? PDFActionGoTo {
            collectionView.displayPage(action.pageIndex, animated: true)
        }
    }
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, tapped recognizer: UITapGestureRecognizer) {
        if hidesBarsOnTap {
            handleTap(recognizer)
        }
    }
    
    public func singlePageViewerDidBeginDragging() {
        self.hideBars(state: true)
    }
    
    public func singlePageViewerDidEndDragging() { }
}

extension PDFViewController: PDFThumbnailViewControllerDelegate {
    public func thumbnailCollection(_ collection: PDFThumbnailViewController, didSelect page: Int) {
        self.scrollTo(page: page)
        self.dismiss(animated: true, completion: nil)
    }
}
