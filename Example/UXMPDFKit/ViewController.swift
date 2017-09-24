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
    
    @IBOutlet var collectionView:UXMSinglePageViewer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.path(forResource: "sample", ofType: "pdf")!
        let document = try! UXMPDFDocument(filePath: url, password: "")
        
        self.collectionView.document = document
    }
}

