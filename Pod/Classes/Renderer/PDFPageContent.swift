//
//  PDFPageContent.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

class PDFPageContent: UIView {
    
    fileprivate var links:[PDFDocumentLink] = []
    fileprivate var pdfDocRef:CGPDFDocument
    fileprivate var pdfPageRef:CGPDFPage?
    fileprivate var pageAngle:Int /// 0, 90, 180, 270
    fileprivate var pageWidth:CGFloat = 0.0
    fileprivate var pageHeight:CGFloat = 0.0
    fileprivate var pageOffsetX:CGFloat = 0.0
    fileprivate var pageOffsetY:CGFloat = 0.0
    fileprivate var page:Int = 0
    
    var cropBoxRect:CGRect
    
    override class var layerClass : AnyClass {
        return PDFPageTileLayer.self
    }
    
    //MARK: - Init
    init(url: URL, page:Int, password:String?) {
        
        var viewRect:CGRect = CGRect.zero
        
        self.pdfDocRef = try! CGPDFDocument.create(url, password: password)
        
        /// Limit the page
        let pages = self.pdfDocRef.numberOfPages
        var page = page
        if page < 1 {
            page = 1
        }
        if page > pages {
            page = pages
        }
        
        self.pdfPageRef = self.pdfDocRef.page(at: page)!
        
        cropBoxRect = (pdfPageRef?.getBoxRect(.cropBox))!
        let mediaBoxRect = pdfPageRef?.getBoxRect(.mediaBox)
        let effectiveRect = cropBoxRect.intersection(mediaBoxRect!)
        
        /// Determine the page angle
        self.pageAngle = Int((pdfPageRef?.rotationAngle)!)
        
        switch self.pageAngle {
        case 90, 270:
            self.pageWidth = effectiveRect.size.height
            self.pageHeight = effectiveRect.size.width
            self.pageOffsetX = effectiveRect.origin.y
            self.pageOffsetY = effectiveRect.origin.x
            break
        case 0, 180:
            self.pageWidth = effectiveRect.size.width
            self.pageHeight = effectiveRect.size.height
            self.pageOffsetX = effectiveRect.origin.x
            self.pageOffsetY = effectiveRect.origin.y
            fallthrough
        default: break
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
        
        self.autoresizesSubviews = false
        self.isUserInteractionEnabled = true
        self.contentMode = .redraw
        self.autoresizingMask = UIViewAutoresizing()
        self.backgroundColor = UIColor.clear
        
        self.buildAnnotationLinksList()
    }
    
    convenience init(document: PDFDocument, page:Int) {
        
        self.init(url: document.fileUrl as URL, page:page, password:document.password)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func removeFromSuperview() {
        
        self.layer.delegate = nil
        super.removeFromSuperview()
    }
    
    
    //MARK: - Page Links Discovery
    
    func highlightPageLinks() {
        
        if links.count > 0 {
            
            let color = self.tintColor.withAlphaComponent(0.01)
            
            for link in links {
                
                let highlight = UIView(frame: link.rect)
                highlight.autoresizesSubviews = false
                highlight.isUserInteractionEnabled = false
                highlight.contentMode = .redraw
                highlight.autoresizingMask = UIViewAutoresizing()
                highlight.backgroundColor = color
                
                self.addSubview(highlight)
            }
        }
    }
    
    func linkFromAnnotation(_ annotation: CGPDFDictionaryRef) -> PDFDocumentLink? {
        
        var annotationRectArray:CGPDFArrayRef? = nil
        
        if CGPDFDictionaryGetArray(annotation, "Rect", &annotationRectArray) {
            
            var lowerLeftX:CGPDFReal = 0.0
            var lowerLeftY:CGPDFReal = 0.0
            
            var upperRightX:CGPDFReal = 0.0
            var upperRightY:CGPDFReal = 0.0
            
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
            
            lowerLeftX -= self.pageOffsetX
            lowerLeftY -= self.pageOffsetY
            upperRightX -= self.pageOffsetX
            upperRightY -= self.pageOffsetY
            
            switch self.pageAngle {
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
                
                lowerLeftX = 0.0 - lowerLeftX + self.pageWidth
                upperRightX = 0.0 - upperRightX + self.pageWidth
                break
            case 0:
                lowerLeftY = 0.0 - lowerLeftY + self.pageHeight
                upperRightY = 0.0 - upperRightY + self.pageHeight
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
        
        self.links = []
        var pageAnnotations:CGPDFArrayRef? = nil
        let pageDictionary:CGPDFDictionaryRef = self.pdfPageRef!.dictionary!
        
        if CGPDFDictionaryGetArray(pageDictionary, "Annots", &pageAnnotations) {
            
            for i in 0...CGPDFArrayGetCount(pageAnnotations!) {
                
                var annotationDictionary:CGPDFDictionaryRef? = nil
                if CGPDFArrayGetDictionary(pageAnnotations!, i, &annotationDictionary) {
                    
                    var annotationSubtype:UnsafePointer<Int8>? = nil
                    if CGPDFDictionaryGetName(annotationDictionary!, "Subtype", &annotationSubtype) {
                        
                        if strcmp(annotationSubtype, "Link") == 0 {
                            
                            if let documentLink = self.linkFromAnnotation(annotationDictionary!) {
                                self.links.append(documentLink)
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
            
            if self.links.count > 0 {
                
                let point = recognizer.location(in: self)

                for link:PDFDocumentLink in self.links {
                    if link.rect.contains(point) {
                        return PDFAction.fromPDFDictionary(link.dictionary, documentReference: self.pdfDocRef)
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
        ctx.translateBy(x: 0.0, y: self.bounds.size.height); ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.concatenate((self.pdfPageRef?.getDrawingTransform(.cropBox, rect: self.bounds, rotate: 0, preserveAspectRatio: true))!)
        
        /// Render the PDF page into the context
        ctx.drawPDFPage(self.pdfPageRef!)
    }
    
    deinit {
        layer.contents = nil
        layer.delegate = nil
        layer.removeFromSuperlayer()
    }
}


class PDFDocumentLink: NSObject {
    
    var rect:CGRect
    var dictionary:CGPDFDictionaryRef
    
    static func new(_ rect:CGRect, dictionary:CGPDFDictionaryRef) -> PDFDocumentLink {
        
        return PDFDocumentLink(rect: rect, dictionary: dictionary)
    }
    
    
    init(rect:CGRect, dictionary:CGPDFDictionaryRef) {
        
        self.rect = rect
        self.dictionary = dictionary
        
        super.init()
        
    }
    
    
}
