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
    
    open var hidesBarsOnTap:Bool = false
    open var showsScrubber:Bool = true {
        didSet {
            self.pageScrubber.isHidden = !self.showsScrubber
        }
    }
    open var allowsFormFilling:Bool = true
    open var allowsAnnotations:Bool = true
    open var allowsSharing:Bool = true
    open var isPresentingInModal:Bool = false
    
    var document:PDFDocument!
    
    lazy var collectionView:PDFSinglePageViewer = {
        var collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.singlePageDelegate = self
        return collectionView
    }()
    
    lazy var pageScrubber:PDFPageScrubber = {
        
        var pageScrubber = PDFPageScrubber(frame: CGRect(x: 0, y: self.view.frame.size.height - self.bottomLayoutGuide.length, width: self.view.frame.size.width, height: 44.0), document: self.document)
        pageScrubber.scrubberDelegate = self
        pageScrubber.translatesAutoresizingMaskIntoConstraints = false
        pageScrubber.isHidden = !self.showsScrubber
        return pageScrubber
    }()
    
    lazy var formController:PDFFormViewController = PDFFormViewController(document: self.document)
    lazy var annotationController:PDFAnnotationController = PDFAnnotationController(document: self.document)
    
    fileprivate var showingAnnotations:Bool = false
    fileprivate var showingFormFilling:Bool = true
    
    public init(document: PDFDocument) {
        super.init(nibName: nil, bundle: nil)
        self.document = document
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    func setupUI() {
        
        self.view.addSubview(collectionView)
        self.view.addSubview(pageScrubber)
        self.view.addSubview(annotationController.view)
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView])
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: .alignAllLeft, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrubber]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": self.view, "scrubber": self.pageScrubber]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[scrubber(44)]-0-[bottomLayout]", options: .alignAllLeft, metrics: nil, views: [ "scrubber": self.pageScrubber, "bottomLayout": self.bottomLayoutGuide ]))
        
        self.view.addConstraints(constraints)
        
        self.pageScrubber.sizeToFit()
        
        
        self.reloadBarButtons()
        
        
        if self.hidesBarsOnTap {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PDFViewController.handleTap(_:)))
            gestureRecognizer.cancelsTouchesInView = false
            self.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func loadDocument(_ document: PDFDocument) {
        self.collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        self.view.layoutSubviews()
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
        self.navigationItem.rightBarButtonItems = self.rightBarButtons()
        
        if self.isPresentingInModal {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done",
                                                                    style: .plain,
                                                                    target: self,
                                                                    action: #selector(PDFViewController.dismissModal))
        }
    }
    
    fileprivate func rightBarButtons() -> [UIBarButtonItem] {
        
        var buttons:[UIBarButtonItem] = []
        
        if self.allowsSharing {
            buttons.append(UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(PDFViewController.shareForm)
                )
            )
        }
        
        if self.allowsFormFilling {
            
            buttons.append(UIBarButtonItem(
                image: UIImage.bundledImage("form"),
                style: .plain,
                target: self,
                action: #selector(PDFViewController.showForm)
                )
            )
        }
        
        if self.allowsAnnotations {
            if self.showingAnnotations {
                
                buttons.append(self.annotationController.highlighterButton)
                buttons.append(self.annotationController.penButton)
                buttons.append(self.annotationController.textButton)
                buttons.append(self.annotationController.undoButton)
            }
            
            buttons.append(PDFBarButton(
                image: UIImage.bundledImage("annot"),
                toggled: self.showingAnnotations,
                target: self,
                action: #selector(PDFViewController.toggleAnnotations(_:))
                )
            )
        }
        
        return buttons
    }
    
    func toggleAnnotations(_ button: PDFBarButton) {
        self.showingAnnotations = !self.showingAnnotations
        self.reloadBarButtons()
    }
    
    func showForm() {
        self.showingFormFilling = true
        self.showingAnnotations = false
        
        self.annotationController.finishAnnotation()
        self.reloadBarButtons()
    }
    
    //MARK: - IBActions
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        
        if let nvc = self.navigationController , nvc.isNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.pageScrubber.isHidden = false
        }
        else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.pageScrubber.isHidden = true
        }
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func shareForm() {
        
        let renderer = PDFRenderController(document: self.document, controllers: [
            self.annotationController,
            self.formController
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
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
}


extension PDFViewController: PDFPageScrubberDelegate {
    
    public func scrubber(_ scrubber: PDFPageScrubber, selectedPage: Int) {
        
        self.document.currentPage = selectedPage
        self.collectionView.displayPage(selectedPage, animated: false)
    }
}

extension PDFViewController: PDFSinglePageViewerDelegate {
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, didDisplayPage page: Int) {
        
        self.document.currentPage = page
        if self.showsScrubber {
            self.pageScrubber.updateScrubber()
        }
    }
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, loadedContent content: PDFPageContentView) {
        
        if self.allowsFormFilling {
            self.formController.showForm(content)
        }
        if self.allowsAnnotations {
            self.annotationController.showAnnotations(content)
        }
    }
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, selectedAction action: PDFAction) {
        
        if let action = action as? PDFActionURL {
            
            let svc = SFSafariViewController(url: action.url as URL)
            self.present(svc, animated: true, completion: nil)
        }
        else if let action = action as? PDFActionGoTo {
            self.collectionView.displayPage(action.pageIndex, animated: true)
        }
    }
}


open class PDFBarButton:UIBarButtonItem {
    
    fileprivate var button:UIButton = UIButton(frame: CGRect(x: 0,y: 0,width: 32,height: 32))
    fileprivate var toggled:Bool = false
    fileprivate lazy var defaultTint:UIColor = UIColor.blue
    
    override open var tintColor: UIColor? {
        didSet {
            self.button.tintColor = tintColor
        }
    }
    
    convenience init(image: UIImage?, toggled: Bool, target: AnyObject?, action: Selector) {
        
        self.init()
        
        self.customView = button
        self.defaultTint = self.button.tintColor
        
        self.toggle(toggled)
        
        self.target = target
        self.action = action
        
        self.button.addTarget(self, action: #selector(PDFBarButton.tapped), for: .touchUpInside)
        self.button.setImage(image?.withRenderingMode(.alwaysTemplate), for: UIControlState())
    }
    
    open func toggle(_ state: Bool) {
        
        self.toggled = state
        if self.toggled {
            button.tintColor = UIColor.white
            button.layer.backgroundColor = (self.tintColor ?? self.defaultTint).cgColor
            button.layer.cornerRadius = 4.0
        }
        else {
            button.tintColor = self.tintColor
            button.layer.backgroundColor = UIColor.clear.cgColor
            button.layer.cornerRadius = 4.0
        }
    }
    
    func tapped() {
        let _ = self.target?.perform(self.action, with: self)
    }
}
