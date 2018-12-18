//
//  UXMThumbnailView.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

internal class UXMThumbnailView: UIView {
    let imageView: UIImageView
    
    override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        
        super.init(frame: frame)

        imageView.frame = self.bounds
        addSubview(imageView)
        
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, document: UXMPDFDocument, page: Int) {
        self.init(frame: frame)
        showImage(document, page: page)
    }

    func showImage(_ document: UXMPDFDocument, page: Int) {
        imageView.image = nil
        UXMQueue.sharedQueue.fetchPage(document, page: page, size: frame.size) { (thumbnail) in
            self.imageView.image = thumbnail.image
        }
    }
}
