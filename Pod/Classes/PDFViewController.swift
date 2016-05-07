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
    
    lazy var collectionView:UICollectionView = {
        var collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    lazy var pageScrubber:PDFPageScrubber = {
        
        var pageScrubber = PDFPageScrubber(frame: CGRectMake(0, self.view.frame.size.height - self.bottomLayoutGuide.length, self.view.frame.size.width, 44.0), document: self.document)
        //pageScrubber.scrubberDelegate = self
        pageScrubber.delegate = self
        pageScrubber.translatesAutoresizingMaskIntoConstraints = false
        return pageScrubber
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
        
        self.pageScrubber.sizeToFit()
    }
    
    func loadDocument(document: PDFDocument) {
        self.collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PDFViewController: UIToolbarDelegate {
    
}
