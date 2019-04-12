//
//  UXMPageContent.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

public class UXMPageContent: UIView {
    
    private let pdfDocRef: CGPDFDocument
    private let pdfPageRef: CGPDFPage?
    private let pageAngle: Int /// 0, 90, 180, 270
    private var links: [UXMDocumentLink] = []
    private var pageWidth: CGFloat = 0.0
    private var pageHeight: CGFloat = 0.0
    private var pageOffsetX: CGFloat = 0.0
    private var pageOffsetY: CGFloat = 0.0
    private var page: Int = 0
    private var cachedViewBounds: CGRect = CGRect.zero
    
    var cropBoxRect: CGRect
    var viewRect: CGRect = CGRect.zero
    
    override public class var layerClass : AnyClass {
        return UXMPageTileLayer.self
    }
    
    //MARK: - Init
    init(pdfDocument: UXMPDFDocument, page: Int, password: String?) {
        pdfDocRef = pdfDocument.documentRef!
        /// Limit the page
        let pages = pdfDocRef.numberOfPages
        var page = page
        if page < 1 {
            page = 1
        }
        if page > pages {
            page = pages
        }
        
        guard let pdfPageRef = pdfDocument.page(at: page) else { fatalError() }
        self.pdfPageRef = pdfPageRef
        
        cropBoxRect = pdfPageRef.getBoxRect(.cropBox)
        let mediaBoxRect = pdfPageRef.getBoxRect(.mediaBox)
        let effectiveRect = cropBoxRect.intersection(mediaBoxRect)
        
        /// Determine the page angle
        pageAngle = Int(pdfPageRef.rotationAngle)
        
        switch pageAngle {
        case 90, 270:
            self.pageWidth = effectiveRect.size.height
            self.pageHeight = effectiveRect.size.width
            pageOffsetX = effectiveRect.origin.y
            pageOffsetY = effectiveRect.origin.x
        case 0, 180:
            self.pageWidth = effectiveRect.size.width
            self.pageHeight = effectiveRect.size.height
            pageOffsetX = effectiveRect.origin.x
            pageOffsetY = effectiveRect.origin.y
        default:
            break
        }
        
        /// Round the size if needed
        var pageWidth = Int(self.pageWidth)
        var pageHeight = Int(self.pageHeight)
        
        if pageWidth % 2 != 0 {
            pageWidth -= 1
        }
        
        if pageHeight % 2 != 0 {
            pageHeight -= 1
        }
        
        viewRect.size = CGSize(width: CGFloat(pageWidth), height: CGFloat(pageHeight))
        
        /// Finish the init with sizes
        super.init(frame: viewRect)
        
        autoresizesSubviews = false
        isUserInteractionEnabled = true
        contentMode = .redraw
        autoresizingMask = UIView.AutoresizingMask()
        backgroundColor = UIColor.clear
        
        buildAnnotationLinksList()
    }
    
    convenience init(document: UXMPDFDocument, page: Int) {
        self.init(pdfDocument: document, page: page, password: document.password)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.cachedViewBounds = self.bounds
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func removeFromSuperview() {
        layer.delegate = nil
        super.removeFromSuperview()
    }
    
    //MARK: - Page Links Discovery
    
    private func highlightPageLinks() {
        guard links.count > 0 else { return }
        let color = tintColor.withAlphaComponent(0.01)
        
        for link in links {
            let highlight = UIView(frame: link.rect)
            highlight.autoresizesSubviews = false
            highlight.isUserInteractionEnabled = false
            highlight.contentMode = .redraw
            highlight.autoresizingMask = UIView.AutoresizingMask()
            highlight.backgroundColor = color
            
            addSubview(highlight)
        }
    }
    
    private func linkFromAnnotation(_ annotation: CGPDFDictionaryRef) -> UXMDocumentLink? {
        var annotationRectArray: CGPDFArrayRef? = nil
        
        guard CGPDFDictionaryGetArray(annotation, "Rect", &annotationRectArray) else { return nil }
        var lowerLeftX: CGPDFReal = 0.0
        var lowerLeftY: CGPDFReal = 0.0
        
        var upperRightX: CGPDFReal = 0.0
        var upperRightY: CGPDFReal = 0.0
        
        CGPDFArrayGetNumber(annotationRectArray!, 0, &lowerLeftX)
        CGPDFArrayGetNumber(annotationRectArray!, 1, &lowerLeftY)
        CGPDFArrayGetNumber(annotationRectArray!, 2, &upperRightX)
        CGPDFArrayGetNumber(annotationRectArray!, 3, &upperRightY)
        
        if lowerLeftX > upperRightX {
            let t = lowerLeftX
            lowerLeftX = upperRightX
            upperRightX = t
        }
        
        if lowerLeftY > upperRightY {
            let t = lowerLeftY
            lowerLeftY = upperRightY
            upperRightY = t
        }
        
        lowerLeftX -= pageOffsetX
        lowerLeftY -= pageOffsetY
        upperRightX -= pageOffsetX
        upperRightY -= pageOffsetY
        
        switch pageAngle {
        case 90:
            var swap = lowerLeftY
            lowerLeftY = lowerLeftX
            lowerLeftX = swap
            swap = upperRightY
            upperRightY = upperRightX
            upperRightX = swap
            break
        case 270:
            var swap = lowerLeftY
            lowerLeftY = lowerLeftX
            lowerLeftX = swap
            swap = upperRightY
            upperRightY = upperRightX
            upperRightX = swap
            
            lowerLeftX = 0.0 - lowerLeftX + pageWidth
            upperRightX = 0.0 - upperRightX + pageWidth
            break
        case 0:
            lowerLeftY = 0.0 - lowerLeftY + pageHeight
            upperRightY = 0.0 - upperRightY + pageHeight
            break
        default:
            break
        }
        
        let x = lowerLeftX
        let w = upperRightX - lowerLeftX
        let y = lowerLeftY
        let h = upperRightY - lowerLeftY
        
        let rect = CGRect(x: x, y: y, width: w, height: h)
        
        return UXMDocumentLink(rect: rect, dictionary:annotation)
    }
    
    private func buildAnnotationLinksList() {
        links = []
        var pageAnnotations: CGPDFArrayRef? = nil
        let pageDictionary: CGPDFDictionaryRef = pdfPageRef!.dictionary!
        
        if CGPDFDictionaryGetArray(pageDictionary, "Annots", &pageAnnotations) {
            for i in 0...CGPDFArrayGetCount(pageAnnotations!) {
                var annotationDictionary: CGPDFDictionaryRef? = nil
                guard CGPDFArrayGetDictionary(pageAnnotations!, i, &annotationDictionary) else { continue }
                    
                var annotationSubtype: UnsafePointer<Int8>? = nil
                guard CGPDFDictionaryGetName(annotationDictionary!, "Subtype", &annotationSubtype) else { continue }
                guard strcmp(annotationSubtype, "Link") == 0 else { continue }
                guard let documentLink = linkFromAnnotation(annotationDictionary!) else { continue }
                links.append(documentLink)
            }
        }
        self.highlightPageLinks()
    }
    
    //MARK: - Gesture Recognizer
    func processSingleTap(_ recognizer: UIGestureRecognizer) -> AnyObject? {
        guard recognizer.state == .recognized else { return nil }
        
        let point = recognizer.location(in: self)
        
        for link in links where link.rect.contains(point) {
            return UXMAction.fromPDFDictionary(link.dictionary, documentReference: pdfDocRef)
        }

        for annotation in subviews where annotation.frame.contains(point) {
            return annotation
        }
        
        return nil
    }
    
    //MARK: - CATiledLayer Delegate Methods
    override open func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let pdfPageRef = pdfPageRef else { return }
        
        ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        ctx.fill(ctx.boundingBoxOfClipPath)
        
        /// Translate for page
        ctx.translateBy(x: 0.0, y: self.cachedViewBounds.size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.concatenate((pdfPageRef.getDrawingTransform(.cropBox, rect: self.cachedViewBounds, rotate: 0, preserveAspectRatio: true)))
        
        /// Render the PDF page into the context
        ctx.drawPDFPage(pdfPageRef)
    }
    
    deinit {
        layer.contents = nil
        layer.delegate = nil
        layer.removeFromSuperlayer()
    }
}
