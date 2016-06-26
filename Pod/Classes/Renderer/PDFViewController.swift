//
//  PDFViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/7/16.
//
//

import UIKit

public class PDFViewController: UIViewController {
    
    public var hidesBarsOnTap:Bool = false
    public var showsScrubber:Bool = true {
        didSet {
            self.pageScrubber.hidden = !self.showsScrubber
        }
    }
    public var allowsFormFilling:Bool = true
    public var allowsAnnotations:Bool = true
    
    
    var document:PDFDocument!
    
    lazy var collectionView:PDFSinglePageViewer = {
        var collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.singlePageDelegate = self
        return collectionView
    }()
    
    lazy var pageScrubber:PDFPageScrubber = {
        
        var pageScrubber = PDFPageScrubber(frame: CGRectMake(0, self.view.frame.size.height - self.bottomLayoutGuide.length, self.view.frame.size.width, 44.0), document: self.document)
        pageScrubber.scrubberDelegate = self
        pageScrubber.translatesAutoresizingMaskIntoConstraints = false
        pageScrubber.hidden = !self.showsScrubber
        return pageScrubber
    }()
    
    lazy var formController:PDFFormViewController = PDFFormViewController(document: self.document)
    lazy var annotationController:PDFAnnotationController = PDFAnnotationController(document: self.document)
    
    private var showingAnnotations:Bool = false
    private var showingFormFilling:Bool = true
    
    public init(document: PDFDocument) {
        super.init(nibName: nil, bundle: nil)
        self.document = document
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    func setupUI() {
        
        self.view.addSubview(collectionView)
        self.view.addSubview(pageScrubber)
        self.view.addSubview(annotationController.view)
        
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView])
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: .AlignAllLeft, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView]))
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrubber]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self.view, "scrubber": self.pageScrubber]))
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:[scrubber(44)]-0-[bottomLayout]", options: .AlignAllLeft, metrics: nil, views: [ "scrubber": self.pageScrubber, "bottomLayout": self.bottomLayoutGuide ]))
        
        self.view.addConstraints(constraints)
        
        self.pageScrubber.sizeToFit()
        
        
        self.reloadBarButtons()
        
        
        if self.hidesBarsOnTap {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PDFViewController.handleTap(_:)))
            gestureRecognizer.cancelsTouchesInView = false
            self.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func loadDocument(document: PDFDocument) {
        self.collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        self.view.layoutSubviews()
    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (context) in
            
            self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.pageScrubber.sizeToFit()
            
            }, completion: { (context) in
                self.collectionView.displayPage(self.document.currentPage, animated: false)
        })
    }
    
    //MARK: - Private helpers
    private func reloadBarButtons() {
        self.navigationItem.rightBarButtonItems = self.rightBarButtons()
        
        if self.isModal() {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done",
                                                                    style: .Plain,
                                                                    target: self,
                                                                    action: #selector(PDFViewController.dismissModal))
        }
    }
    
    private func rightBarButtons() -> [UIBarButtonItem] {
        
        var buttons:[UIBarButtonItem] = []
        
        buttons.append(UIBarButtonItem(
            barButtonSystemItem: .Action,
            target: self,
            action: #selector(PDFViewController.saveForm)
            )
        )
        
        if self.allowsFormFilling {
            
            buttons.append(UIBarButtonItem(
                image: UIImage.bundledImage("form"),
                style: .Plain,
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
    
    func toggleAnnotations(button: PDFBarButton) {
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
    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        
        if let nvc = self.navigationController where nvc.navigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.pageScrubber.hidden = false
        }
        else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.pageScrubber.hidden = true
        }
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func saveForm() {
        
        let renderer = PDFRenderController(document: self.document, controllers: [
            self.annotationController,
            self.formController
            ])
        let pdf = renderer.renderOntoPDF()
        
        let items = [pdf]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            activityVC.modalPresentationStyle = .Popover
            let popController = activityVC.popoverPresentationController
            popController?.sourceView = self.view
            popController?.sourceRect = CGRectMake(self.view.frame.width - 34, 64, 0, 0)
            popController?.permittedArrowDirections = .Up
        }
        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    func dismissModal() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func isModal() -> Bool {
        
        if self.presentingViewController != nil
        || self.presentingViewController?.presentedViewController == self
        || self.navigationController?.presentingViewController?.presentedViewController == self.navigationController
        || self.tabBarController?.presentingViewController is UITabBarController {
            return true
        }
        
        return false
    }
}


extension PDFViewController: PDFPageScrubberDelegate {
    
    public func scrubber(scrubber: PDFPageScrubber, selectedPage: Int) {
        
        self.document.currentPage = selectedPage
        self.collectionView.displayPage(selectedPage, animated: false)
    }
}

extension PDFViewController: PDFSinglePageViewerDelegate {
    
    public func singlePageViewer(collectionView: PDFSinglePageViewer, didDisplayPage page: Int) {
        
        self.document.currentPage = page
        self.pageScrubber.updateScrubber()
    }
    
    public func singlePageViewer(collectionView: PDFSinglePageViewer, loadedContent content: PDFPageContentView) {
        
        self.formController.showForm(content)
        self.annotationController.showAnnotations(content)
    }
}


public class PDFBarButton:UIBarButtonItem {
    
    private var button:UIButton = UIButton(frame: CGRectMake(0,0,32,32))
    private var toggled:Bool = false
    private lazy var defaultTint:UIColor = UIColor.blueColor()
    
    override public var tintColor: UIColor? {
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
        
        self.button.addTarget(self, action: #selector(PDFBarButton.tapped), forControlEvents: .TouchUpInside)
        self.button.setImage(image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
    
    public func toggle(state: Bool) {
        
        self.toggled = state
        if self.toggled {
            button.tintColor = UIColor.whiteColor()
            button.layer.backgroundColor = (self.tintColor ?? self.defaultTint).CGColor
            button.layer.cornerRadius = 4.0
        }
        else {
            button.tintColor = self.tintColor
            button.layer.backgroundColor = UIColor.clearColor().CGColor
            button.layer.cornerRadius = 4.0
        }
    }
    
    func tapped() {
        self.target?.performSelector(self.action, withObject: self)
    }
}
