//
//  PDFThumbnailViewCell.swift
//  Pods
//
//  Created by Chris Anderson on 11/14/16.
//
//

import UIKit

class PDFThumbnailViewCell: UICollectionViewCell {
    
    var pageThumbnail: PDFThumbnailView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI() {
        self.backgroundColor = UIColor.lightGray
    }
    
    func configure(document: PDFDocument, page: Int) {
        pageThumbnail?.removeFromSuperview()
        pageThumbnail = PDFThumbnailView(frame: CGRect(x: 1,
                                                       y: 1,
                                                       width: self.frame.width - 2,
                                                       height: self.frame.height - 2),
                                         document: document,
                                         page: page)
        self.addSubview(pageThumbnail!)
    }
    
    override open func prepareForReuse() {
        pageThumbnail?.removeFromSuperview()
        pageThumbnail = nil
    }
}
