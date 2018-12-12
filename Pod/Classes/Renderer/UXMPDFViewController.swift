//
//  UXMPDFViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/7/16.
//
//

import UIKit
import SafariServices

public protocol UXMPDFViewControllerDelegate : class {
    func editingDidEnd(_ document: UXMPDFDocument)
}

open class UXMPDFViewController: UIViewController {
    /// Delegate reference for editing events
    open weak var delegate: UXMPDFViewControllerDelegate? = nil
    
    /// A boolean value that determines whether show and use only pen tool
    open var signatureMode: Bool = false
    
    /// A boolean value that determines whether the navigation bar and scrubber bar hide on screen tap
    open var hidesBarsOnTap: Bool = false
    
    /// A boolean value that determines if the scrubber bar should be visible
    open var showsScrubber: Bool = true {
        didSet {
            guard isViewLoaded else {
                return
            }
            pageScrubber.isHidden = !showsScrubber
        }
    }
    
    /// A boolean value that determines if a PDF should have fillable form elements
    open var allowsFormFilling: Bool = true
    
    /// A boolean value that determines if annotations are allowed
    open var allowsAnnotations: Bool = true
    
    /// A boolean value that determines if sharing should be allowed
    open var allowsSharing: Bool = true
    
    /// A boolean value that determines if view controller is displayed as modal
    open var isPresentingInModal: Bool = false
    
    open var modalDoneButtonTouched: (() -> ())?
    
    /// The scroll direction of the reader
    open var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    /// A reference to the document that is being displayed
    open var document: UXMPDFDocument! {
        didSet {
            if self.isViewLoaded {
                self.setupUI()
            }
        }
    }
    
    /// A reference to the share button
    var shareBarButtonItem: UIBarButtonItem?
    
    /// A closure that defines an action to take upon selecting the share button.
    /// The default action brings up a UIActivityViewController
    open lazy var shareBarButtonAction: () -> () = { self.showActivitySheet() }
    
    /// A closure that defines what happens on viewWillDisappear.
    /// The default is to assign the annotations out of the annotationController into
    /// the document, then call document.save()
    open lazy var autoSaveAction: (UXMPDFDocument, UXMAnnotationController) -> () = { document, annotationController in
        document.annotations = annotationController.annotations
        document.save()
        
        if self.edited {
            self.delegate?.editingDidEnd(document)
        }
    }
    
    /// A reference to the collection view handling page presentation
    var collectionView: UXMSinglePageViewer!
    
    /// A reference to the page scrubber bar
    var pageScrubber: UXMPageScrubber!
    
    private(set) open lazy var formController: UXMFormViewController = UXMFormViewController(document: self.document)
    private(set) open lazy var annotationController: UXMAnnotationController = UXMAnnotationController(document: self.document, delegate: self)
    
    fileprivate var showingAnnotations = false
    fileprivate var showingFormFilling = true
    
    fileprivate var edited = false
    
    /**
     Initializes a new reader with a given document
     
     - Parameters:
     - document: The document to display
     
     - Returns: An instance of the UXMPDFViewController
     */
    public init(document: UXMPDFDocument) {
        super.init(nibName: nil, bundle: nil)
        self.document = document
        self.modalDoneButtonTouched = { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /**
     Initializes a new reader with a given document and annotation controller
     
     - Parameters:
     - document: The document to display
     - annotationController: The controller to supervise annotations
     
     - Returns: An instance of the UXMPDFViewController
     */
    public convenience init(document: UXMPDFDocument, annotationController: UXMAnnotationController) {
        self.init(document: document)
        self.annotationController = UXMAnnotationController(document: self.document, delegate: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        if self.document != nil {
            self.setupUI()
        }
    }
    
    fileprivate func setupUI() {
        
        pageScrubber = UXMPageScrubber(frame: CGRect(x: 0, y: view.frame.size.height - bottomLayoutGuide.length, width: view.frame.size.width, height: 44), document: document)
        pageScrubber.scrubberDelegate = self
        pageScrubber.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView = UXMSinglePageViewer(frame: view.bounds, document: document)
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
        
        view.addSubview(collectionView)
        view.addSubview(pageScrubber)
        view.addSubview(annotationController.view)
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            pageScrubber.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }else {
            pageScrubber.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        pageScrubber.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageScrubber.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageScrubber.heightAnchor.constraint(equalToConstant: 44).isActive = true
        pageScrubber.sizeToFit()
        
        reloadBarButtons()
        
        collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        if self.document != nil {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.document != nil {
            collectionView.collectionViewLayout.invalidateLayout()
        }
        
        view.layoutSubviews()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        if self.document != nil {
            self.annotationController.finishAnnotation()
            autoSaveAction(self.document, self.annotationController)
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] (context) in
            guard let zelf = self else { return }
            zelf.collectionView.contentInset = UIEdgeInsets(top: zelf.topLayoutGuide.length, left: 0, bottom: zelf.bottomLayoutGuide.length, right: 0)
            zelf.collectionView.collectionViewLayout.invalidateLayout()
            zelf.pageScrubber.sizeToFit()
        }, completion: { [weak self] (context) in
            guard let zelf = self else { return }
            zelf.collectionView.displayPage(zelf.document.currentPage, animated: false)
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
                                                               action: #selector(UXMPDFViewController.dismissModal))
        }
    }
    
    open func rightBarButtons() -> [UIBarButtonItem] {
        if (signatureMode) {
            var buttons = self.navigationItem.rightBarButtonItems ?? []
            
            // undo button
            buttons.append(annotationController.undoButton)
            
            // find the draw button (hopefully you added that thing huh?)
            if let penButton = annotationController.buttons.filter({ (button: UXMBarButton) -> Bool in
                if let annotationButton = button as? PDFAnnotationBarButton {
                    return annotationButton.annotationType == PDFPenAnnotation.self
                }
                return false
            }).first {
                buttons.append(penButton);
            }
            else {
                assert(false, "Used 'signatureMode' of true, but did NOT provide the PDFPenAnnotationBarButton as an annotation! No Sign button for you!")
            }
            
            return buttons
        }
        
        var buttons: [UIBarButtonItem] = []
        
        if allowsSharing {

            let shareFormBarButtonItem = UXMBarButton(
                image: UIImage.bundledImage("share"),
                toggled: false,
                target: self,
                action: #selector(UXMPDFViewController.shareDocument)
            )
            buttons.append(shareFormBarButtonItem)
            self.shareBarButtonItem = shareFormBarButtonItem
        }
        
        buttons.append(UXMBarButton(
            image: UIImage.bundledImage("thumbs"),
            toggled: false,
            target: self,
            action: #selector(UXMPDFViewController.showThumbnailView)
            )
        )
        
        
        if allowsAnnotations {
            if showingAnnotations {
                buttons.append(annotationController.undoButton)
                for button in annotationController.buttons.reversed() {
                    buttons.append(button)
                }
            }
            
            buttons.append(UXMBarButton(
                image: UIImage.bundledImage("annot"),
                toggled: showingAnnotations,
                target: self,
                action: #selector(UXMPDFViewController.toggleAnnotations(_:))
                )
            )
        }
        
        return buttons
    }
    
    @objc func toggleAnnotations(_ button: UXMBarButton) {
        showingAnnotations = !showingAnnotations
        reloadBarButtons()
    }
    
    open func savePdfFile(_ clearEncodedAnnotations: Bool = false) -> URL {
        self.annotationController.finishAnnotation()
        let renderer = UXMRenderController(document: document, controllers: [
            annotationController,
            formController
        ])
        
        let pdf = renderer.renderOntoPDF()
        
        if clearEncodedAnnotations {
            document.clearEncodedAnnotations()
        }
        
        return pdf
    }
    
    func showActivitySheet() {
        let renderer = UXMRenderController(document: document, controllers: [
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
    
    @objc func showThumbnailView() {
        let vc = UXMThumbnailViewController(document: document)
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
            }
            else {
                pageScrubber.isHidden = true
            }
        case .vertical:
            pageScrubber.isHidden = true
        }
    }
    
    //MARK: - IBActions
    
    @objc func shareDocument() {
        self.shareBarButtonAction()
    }
    
    @objc func dismissModal() {
        modalDoneButtonTouched?()
    }
    
    @objc private func orientationDidChange(_ notification: Notification? = nil) {
        self.pageScrubber.refreshScrubber()
    }
}

extension UXMPDFViewController: UXMAnnotationControllerProtocol {
    public func annotationWillStart(touch: UITouch) -> Int? {
        self.edited = true
        
        let tapPoint = touch.location(in: collectionView)
        guard let pageIndex = collectionView.indexPathForItem(at: tapPoint)?.row else { return nil }
        let index = pageIndex + 1
        return index
    }
}

extension UXMPDFViewController: UXMPageScrubberDelegate {
    public func scrubber(_ scrubber: UXMPageScrubber, selectedPage: Int) {
        self.scrollTo(page: selectedPage)
    }
}

extension UXMPDFViewController: UXMSinglePageViewerDelegate {
    public func singlePageViewer(_ collectionView: UXMSinglePageViewer, didDisplayPage page: Int) {
        document.currentPage = page
        if showsScrubber {
            pageScrubber.updateScrubber()
        }
    }
    
    public func singlePageViewer(_ collectionView: UXMSinglePageViewer, loadedContent content: UXMPageContentView) {
        if allowsFormFilling {
            formController.showForm(content)
        }
        if allowsAnnotations {
            annotationController.showAnnotations(content)
        }
    }
    
    public func singlePageViewer(_ collectionView: UXMSinglePageViewer, selected action: UXMAction) {
        if let action = action as? UXMActionURL {
            let svc = SFSafariViewController(url: action.url as URL)
            present(svc, animated: true, completion: nil)
        } else if let action = action as? UXMActionGoTo {
            collectionView.displayPage(action.pageIndex, animated: true)
        }
    }
    
    public func singlePageViewer(_ collectionView: UXMSinglePageViewer, selected annotation: UXMPDFAnnotationView) {
        if let annotation = annotation.parent {
            annotationController.select(annotation: annotation)
        }
    }
    
    public func singlePageViewer(_ collectionView: UXMSinglePageViewer, tapped recognizer: UITapGestureRecognizer) {
        annotationController.select(annotation: nil)
    }
    
    public func singlePageViewerDidBeginDragging() {
      // Do not hide navbar
        self.hideBars(state: false)
    }
    
    public func singlePageViewerDidEndDragging() { }
}

extension UXMPDFViewController: UXMThumbnailViewControllerDelegate {
    public func thumbnailCollection(_ collection: UXMThumbnailViewController, didSelect page: Int) {
        self.scrollTo(page: page)
        self.dismiss(animated: true, completion: nil)
    }
}
