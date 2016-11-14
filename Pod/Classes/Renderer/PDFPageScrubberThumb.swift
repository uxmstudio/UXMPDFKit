//
//  PDFPageScrubberThumb.swift
//  Pods
//
//  Created by Ricardo Nunez on 11/11/16.
//
//

import UIKit

internal class PDFPageScrubberThumb: PDFThumbnailView {
    let small: Bool
    let color: UIColor
    
    init(frame: CGRect, small: Bool, color: UIColor) {
        self.small = small
        self.color = color
        
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        small = false
        color = UIColor.white
        super.init(coder: aDecoder)
        setupUI()
    }
    
    func setupUI() {
        let alpha: CGFloat = small ? 0.6 : 0.7
        let background = color.withAlphaComponent(alpha)
        
        backgroundColor = background
        imageView.backgroundColor = background
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 0.5
    }
}
