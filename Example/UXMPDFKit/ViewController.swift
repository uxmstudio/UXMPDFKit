//
//  ViewController.swift
//  UXMPDFKit
//
//  Created by Chris Anderson on 03/05/2016.
//  Copyright (c) 2016 Chris Anderson. All rights reserved.
//

import UIKit
import UXMPDFKit

class ViewController: UIViewController {
    
    @IBOutlet var collectionView:PDFSinglePageViewer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let url = NSBundle.mainBundle().pathForResource("sample", ofType: "pdf")!
        let document = PDFDocument(filePath: url, password: "")
        
        self.collectionView.document = document
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        
//        let url = NSBundle.mainBundle().pathForResource("sample", ofType: "pdf")!
//        print(url)
//        let document = PDFDocument(filePath: url)
//        
//        self.collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: document)
//        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(collectionView)
//        
//        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView])
//        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: .AlignAllLeft, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView]))
//
//        self.view.addConstraints(constraints)
    }
}

