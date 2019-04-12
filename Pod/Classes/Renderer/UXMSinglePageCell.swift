//
//  UXMSinglePageCell.swift
//  Pods
//
//  Created by Ricardo Nunez on 11/11/16.
//
//

import UIKit

open class UXMSinglePageCell: UICollectionViewCell {
    private var _pageContentView: UXMPageContentView?
    
    open var pageContentView: UXMPageContentView? {
        get {
            return _pageContentView
        }
        set {
            if let pageContentView = _pageContentView {
                removeConstraints(constraints)
                pageContentView.removeFromSuperview()
            }
            if let pageContentView = newValue {
                _pageContentView = pageContentView
                contentView.addSubview(pageContentView)
            }
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override open func prepareForReuse() {
        pageContentView = nil
    }
}
