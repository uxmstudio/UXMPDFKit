//
//  PDFViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/7/16.
//
//

import UIKit

public class PDFViewController: UIViewController {
    
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
        return pageScrubber
    }()
    
    lazy var formController:PDFFormViewController = {
        var formController = PDFFormViewController(document: self.document)
        return formController
    }()
    
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
        
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView])
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: .AlignAllLeft, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView]))
        
        
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrubber]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self.view, "scrubber": self.pageScrubber]))
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:[scrubber(44)]-0-[bottomLayout]", options: .AlignAllLeft, metrics: nil, views: [ "scrubber": self.pageScrubber, "bottomLayout": self.bottomLayoutGuide ]))
        
        self.view.addConstraints(constraints)
        
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save Form", style: .Plain, target: self, action: #selector(PDFViewController.saveForm))
        
        self.pageScrubber.sizeToFit()
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
    
    func saveForm() {
        print("saved")
        self.formController.renderFormOntoPDF()
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
    }
}
