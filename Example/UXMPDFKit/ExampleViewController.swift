//
//  ExampleViewController.swift
//  UXMPDFKit
//
//  Created by Chris Anderson on 5/7/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import UXMPDFKit

class ExampleViewController: UIViewController {
    
    @IBAction func loadPDF() {

        let url = Bundle.main.path(forResource: "sample2", ofType: "pdf")!
        let document = try! PDFDocument(filePath: url)
        
        let pdf = PDFViewController(document: document)
        
        self.navigationController?.pushViewController(pdf, animated: true)
    }
}
