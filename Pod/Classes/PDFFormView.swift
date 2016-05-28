//
//  PDFFormView.swift
//  Pods
//
//  Created by Chris Anderson on 5/26/16.
//
//

import UIKit

public class PDFFormView:UIView {
    
    var fields:[PDFFormField] = []
    var page:Int
    
    init(frame: CGRect, page:Int) {
        self.page = page
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
