//
//  PDFThumbnailView.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

class PDFThumbnailView: UIView {
    
    var imageView: UIImageView
    
    override init(frame: CGRect) {
        
        imageView = UIImageView()
        imageView.autoresizesSubviews = false
        imageView.isUserInteractionEnabled = false
        imageView.autoresizingMask = UIViewAutoresizing()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        super.init(frame: frame)

        imageView.frame = frame
        self.addSubview(imageView)
        
        self.autoresizesSubviews = false
        self.isUserInteractionEnabled = false
        self.contentMode = .redraw
        self.autoresizingMask = UIViewAutoresizing()
        self.backgroundColor = UIColor.clear
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[image]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": self, "image": imageView ])
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[image]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": self, "image": imageView ]))
        
        self.addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, document: PDFDocument, page: Int) {
        
        self.init(frame: frame)
        self.showImage(document, page: page)
    }

    func showImage(_ document: PDFDocument, page: Int) {
        self.imageView.image = nil
        PDFQueue.sharedQueue.fetchPage(document, page: page, size: self.frame.size) { (thumbnail) in
            self.imageView.image = thumbnail.image
        }
    }
}
