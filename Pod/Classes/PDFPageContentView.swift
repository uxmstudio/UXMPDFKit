//
//  PDFPageContentView.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

protocol PDFPageContentViewDelegate {
    
    func contentView(contentView: PDFPageContentView, touchesBegan touches:NSSet)
}

public class PDFPageContentView: UIScrollView, UIScrollViewDelegate {

    var contentView:PDFPageContent
    var containerView:UIView
    
    weak var delegate: PDFPageContentViewDelegate?
    
    init(document: PDFDocument) {
        
    }
    
    
    public func processSingleTap(recognizer: UITapGestureRecognizer) {
        
    }
    
    
    //MARK: - Zoom methods
    public func zoomIncrement() {
        
    }
    
    public func zoomDecrement() {
        
    }
    
    public func zoomReset() {
        
    }
    
    
    //MARK: - UIResponder methods
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
    }
    
    override public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    
    
    
    static func zoomScaleThatFits(target: CGSize, source:CGSize) -> CGFloat {
        
        let widthScale:CGFloat = target.width / source.width
        let heightScale:CGFloat = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }
    
}
