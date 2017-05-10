//
//  PDFPageContent.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

internal class PDFPageContent: UIView {
    
    private let pdfDocRef: CGPDFDocument
    private let pdfPageRef: CGPDFPage?
    private let pageAngle: Int /// 0, 90, 180, 270
    private var links: [PDFDocumentLink] = []
    private var pageWidth: CGFloat = 0.0
    private var pageHeight: CGFloat = 0.0
    private var pageOffsetX: CGFloat = 0.0
    private var pageOffsetY: CGFloat = 0.0
    private var page: Int = 0
    
    var cropBoxRect: CGRect
    var viewRect: CGRect = CGRect.zero
    
    override class var layerClass : AnyClass {
        return PDFPageTileLayer.self
    }
    
    //MARK: - Init
    init(pdfDocument: PDFDocument, page: Int, password: String?) {
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
        autoresizingMask = UIViewAutoresizing()
        backgroundColor = UIColor.clear
        
        buildAnnotationLinksList()
    }
    
    convenience init(document: PDFDocument, page: Int) {
        self.init(pdfDocument: document, page: page, password: document.password)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func removeFromSuperview() {
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
            highlight.autoresizingMask = UIViewAutoresizing()
            highlight.backgroundColor = color
            
            addSubview(highlight)
        }
    }
    
    private func linkFromAnnotation(_ annotation: CGPDFDictionaryRef) -> PDFDocumentLink? {
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
        
        return PDFDocumentLink(rect: rect, dictionary:annotation)
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
            return PDFAction.fromPDFDictionary(link.dictionary, documentReference: pdfDocRef)
        }
        
        print("should process")
        for annotation in subviews where annotation.frame.contains(point) {
            return annotation
        }
        
        return nil
    }
    
    func objectInside(touch: UITouch) -> AnyObject? {
        let point = touch.location(in: self)
        
        for link in links where link.rect.contains(point) {
            return PDFAction.fromPDFDictionary(link.dictionary, documentReference: pdfDocRef)
        }
        
        for annotation in subviews where annotation.frame.contains(point) {
            return annotation
        }
        
        return nil
    }
    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        print("touches began")
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesMoved(touches, with: event)
//        print("touches moved")
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        print("touches ended")
//        
//        guard let touch = touches.first else { return }
//        
//        print("obj inside")
//        if let obj = self.objectInside(touch: touch) as? PDFPathView {
//            obj.backgroundColor = UIColor.blue
//        }
//    }
    
    //MARK: - CATiledLayer Delegate Methods
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let pdfPageRef = pdfPageRef else { return }
        ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        ctx.fill(ctx.boundingBoxOfClipPath)
        
        /// Translate for page
        ctx.translateBy(x: 0.0, y: bounds.size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.concatenate((pdfPageRef.getDrawingTransform(.cropBox, rect: bounds, rotate: 0, preserveAspectRatio: true)))
        
        /// Render the PDF page into the context
        ctx.drawPDFPage(pdfPageRef)
    }
    
    deinit {
        layer.contents = nil
        layer.delegate = nil
        layer.removeFromSuperlayer()
    }
}
