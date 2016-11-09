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
    
    open var hidesBarsOnTap: Bool = false
    open var showsScrubber: Bool = true {
        didSet {
            pageScrubber.isHidden = !showsScrubber
        }
    }
    open var allowsFormFilling: Bool = true
    open var allowsAnnotations: Bool = true
    open var allowsSharing: Bool = true
    open var isPresentingInModal: Bool = false
    
    var document: PDFDocument!
    
    var collectionView: PDFSinglePageViewer!
    
    var pageScrubber: PDFPageScrubber!
    
    public var scrollDirection: UICollectionViewScrollDirection = .horizontal
    
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
        pageScrubber.isHidden = !showsScrubber
        
        collectionView = PDFSinglePageViewer(frame: view.bounds, document: document)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.singlePageDelegate = self
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = scrollDirection
        
        switch scrollDirection {
        case .horizontal:
            collectionView.isPagingEnabled = true
            pageScrubber.isHidden = showsScrubber
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
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": view, "collectionView": collectionView])
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: .alignAllLeft, metrics: nil, views: [ "superview": view, "collectionView": collectionView]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrubber]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": view, "scrubber": pageScrubber]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[scrubber(44)]-0-[bottomLayout]", options: .alignAllLeft, metrics: nil, views: [ "scrubber": pageScrubber, "bottomLayout": bottomLayoutGuide ]))
        
        view.addConstraints(constraints)
        
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
            buttons.append(UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(PDFViewController.shareForm)
                )
            )
        }
        
        if allowsFormFilling {
            buttons.append(UIBarButtonItem(
                image: UIImage.bundledImage("form"),
                style: .plain,
                target: self,
                action: #selector(PDFViewController.showForm)
                )
            )
        }
        
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
    
    func showForm() {
        showingFormFilling = true
        showingAnnotations = false
        
        annotationController.finishAnnotation()
        reloadBarButtons()
    }
    
    //MARK: - IBActions
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        if let nvc = navigationController, nvc.isNavigationBarHidden {
            navigationController?.setNavigationBarHidden(false, animated: true)
            pageScrubber.isHidden = false
        } else {
            navigationController?.setNavigationBarHidden(true, animated: true)
            pageScrubber.isHidden = true
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func shareForm() {
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
            popController?.sourceView = self.view
            popController?.sourceRect = CGRect(x: self.view.frame.width - 34, y: 64, width: 0, height: 0)
            popController?.permittedArrowDirections = .up
        }
        present(activityVC, animated: true, completion: nil)
    }
    
    func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}

extension PDFViewController: PDFAnnotationControllerProtocol {
    public func annotationWillStart(touch: UITouch) -> Int? {
        let tapPoint = touch.location(in: collectionView)
        return collectionView.indexPathForItem(at: tapPoint)?.row
    }
}


extension PDFViewController: PDFPageScrubberDelegate {
    public func scrubber(_ scrubber: PDFPageScrubber, selectedPage: Int) {
        document.currentPage = selectedPage
        collectionView.displayPage(selectedPage, animated: false)
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
}


open class PDFBarButton: UIBarButtonItem {
    fileprivate var button = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    fileprivate var toggled = false
    fileprivate lazy var defaultTint = UIColor.blue
    
    override open var tintColor: UIColor? {
        didSet {
            button.tintColor = tintColor
        }
    }
    
    convenience init(image: UIImage?, toggled: Bool, target: AnyObject?, action: Selector) {
        self.init()
        
        customView = button
        defaultTint = button.tintColor
        
        toggle(toggled)
        
        self.target = target
        self.action = action
        
        button.addTarget(self, action: #selector(PDFBarButton.tapped), for: .touchUpInside)
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    
    open func toggle(_ state: Bool) {
        toggled = state
        if toggled {
            button.tintColor = UIColor.white
            button.layer.backgroundColor = (tintColor ?? defaultTint).cgColor
            button.layer.cornerRadius = 4.0
        } else {
            button.tintColor = tintColor
            button.layer.backgroundColor = UIColor.clear.cgColor
            button.layer.cornerRadius = 4.0
        }
    }
    
    func tapped() {
        let _ = self.target?.perform(self.action, with: self)
    }
}
