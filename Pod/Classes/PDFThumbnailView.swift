//
//  PDFThumbnailView.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

class PDFThumbnailView: UIView {
    
    var imageView:UIImageView
    
    override init(frame: CGRect) {
        
        imageView = UIImageView()
        imageView.autoresizesSubviews = false
        imageView.userInteractionEnabled = false
        imageView.autoresizingMask = .None
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .ScaleAspectFit
        
        super.init(frame: frame)
        
        imageView.frame = frame
        self.addSubview(imageView)
        
        self.autoresizesSubviews = false
        self.userInteractionEnabled = false
        self.contentMode = .Redraw
        self.autoresizingMask = .None
        self.backgroundColor = UIColor.clearColor()
        
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[image]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self, "image": imageView ])
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:[image]|", options: .AlignAllBaseline, metrics: nil, views: [ "superview": self, "image": imageView ]))
        
        self.addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, document: PDFDocument, page: Int) {
        
        self.init(frame: frame)
        self.showImage(document, page: page)
    }

    func showImage(document: PDFDocument, page: Int) {
        self.imageView.image = nil
        PDFQueue.sharedQueue.fetchPage(document, page: page, size: self.frame.size) { (thumbnail) in
            self.imageView.image = thumbnail.image
        }
    }
}