//
//  PDFPageContent.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

class PDFPageContent: UIView {
    fileprivate var links: [PDFDocumentLink] = []
    fileprivate var pdfDocRef: CGPDFDocument
    fileprivate var pdfPageRef: CGPDFPage?
    fileprivate var pageAngle: Int /// 0, 90, 180, 270
    fileprivate var pageWidth: CGFloat = 0.0
    fileprivate var pageHeight: CGFloat = 0.0
    fileprivate var pageOffsetX: CGFloat = 0.0
    fileprivate var pageOffsetY: CGFloat = 0.0
    fileprivate var page: Int = 0
    
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
        
        pdfPageRef = pdfDocRef.page(at: page)!
        
        cropBoxRect = (pdfPageRef?.getBoxRect(.cropBox))!
        let mediaBoxRect = pdfPageRef?.getBoxRect(.mediaBox)
        let effectiveRect = cropBoxRect.intersection(mediaBoxRect!)
        
        /// Determine the page angle
        pageAngle = Int((pdfPageRef?.rotationAngle)!)
        
        switch self.pageAngle {
        case 90, 270:
            self.pageWidth = effectiveRect.size.height
            self.pageHeight = effectiveRect.size.width
            pageOffsetX = effectiveRect.origin.y
            pageOffsetY = effectiveRect.origin.x
            break
        case 0, 180:
            self.pageWidth = effectiveRect.size.width
            self.pageHeight = effectiveRect.size.height
            pageOffsetX = effectiveRect.origin.x
            pageOffsetY = effectiveRect.origin.y
            fallthrough
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
    
    func highlightPageLinks() {
        if links.count > 0 {
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
    }
    
    func linkFromAnnotation(_ annotation: CGPDFDictionaryRef) -> PDFDocumentLink? {
        var annotationRectArray: CGPDFArrayRef? = nil
        
        if CGPDFDictionaryGetArray(annotation, "Rect", &annotationRectArray) {
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
            
            return PDFDocumentLink.init(rect: rect, dictionary:annotation)
        }
        return nil
    }
    
    func buildAnnotationLinksList() {
        links = []
        var pageAnnotations: CGPDFArrayRef? = nil
        let pageDictionary: CGPDFDictionaryRef = pdfPageRef!.dictionary!
        
        if CGPDFDictionaryGetArray(pageDictionary, "Annots", &pageAnnotations) {
            
            for i in 0...CGPDFArrayGetCount(pageAnnotations!) {
                
                var annotationDictionary: CGPDFDictionaryRef? = nil
                if CGPDFArrayGetDictionary(pageAnnotations!, i, &annotationDictionary) {
                    
                    var annotationSubtype: UnsafePointer<Int8>? = nil
                    if CGPDFDictionaryGetName(annotationDictionary!, "Subtype", &annotationSubtype) {
                        
                        if strcmp(annotationSubtype, "Link") == 0 {
                            
                            if let documentLink = linkFromAnnotation(annotationDictionary!) {
                                links.append(documentLink)
                            }
                        }
                    }
                }
            }
        }
        self.highlightPageLinks()
    }
    
    //MARK: - Gesture Recognizer
    func processSingleTap(_ recognizer: UIGestureRecognizer) -> PDFAction? {
        if recognizer.state == UIGestureRecognizerState.recognized {
            
            if links.count > 0 {
                let point = recognizer.location(in: self)
                
                for link in links {
                    if link.rect.contains(point) {
                        return PDFAction.fromPDFDictionary(link.dictionary, documentReference: pdfDocRef)
                    }
                }
            }
        }
        return nil
    }
    
    //MARK: - CATiledLayer Delegate Methods
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        ctx.fill(ctx.boundingBoxOfClipPath)
        
        /// Translate for page
        ctx.translateBy(x: 0.0, y: bounds.size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.concatenate((pdfPageRef?.getDrawingTransform(.cropBox, rect: bounds, rotate: 0, preserveAspectRatio: true))!)
        
        /// Render the PDF page into the context
        ctx.drawPDFPage(pdfPageRef!)
    }
    
    deinit {
        layer.contents = nil
        layer.delegate = nil
        layer.removeFromSuperlayer()
    }
}


class PDFDocumentLink: NSObject {
    var rect: CGRect
    var dictionary: CGPDFDictionaryRef
    
    static func new(_ rect: CGRect, dictionary: CGPDFDictionaryRef) -> PDFDocumentLink {
        return PDFDocumentLink(rect: rect, dictionary: dictionary)
    }
    
    init(rect: CGRect, dictionary: CGPDFDictionaryRef) {
        self.rect = rect
        self.dictionary = dictionary
        
        super.init()
    }
}
