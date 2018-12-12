//
//  UXMThumbnailViewCell.swift
//  Pods
//
//  Created by Chris Anderson on 11/14/16.
//
//

import UIKit

class UXMThumbnailViewCell: UICollectionViewCell {
    
    var pageThumbnail: UXMThumbnailView?
    
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
    
    func configure(document: UXMPDFDocument, page: Int) {
        pageThumbnail?.removeFromSuperview()
        pageThumbnail = UXMThumbnailView(frame: CGRect(x: 1,
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
