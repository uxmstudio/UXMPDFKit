//
//  PDFPageContent.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

class PDFPageContent: UIView {
    
    private var links:[PDFDocumentLink] = []
    private var pdfDocRef:CGPDFDocumentRef
    private var pdfPageRef:CGPDFPageRef?
    private var pageAngle:Int /// 0, 90, 180, 270
    private var pageWidth:CGFloat = 0.0
    private var pageHeight:CGFloat = 0.0
    private var pageOffsetX:CGFloat = 0.0
    private var pageOffsetY:CGFloat = 0.0
    private var page:Int = 0
    
    
    
    
    override class func layerClass() -> AnyClass {
        return PDFPageTileLayer.self
    }
    
    //MARK: - Init
    init(url: NSURL, var page:Int, password:String?) {
        
        var viewRect:CGRect = CGRectZero
        
        self.pdfDocRef = try! CGPDFDocument.create(url, password: password)
        
        /// Limit the page
        let pages = CGPDFDocumentGetNumberOfPages(self.pdfDocRef)
        if page < 1 {
            page = 1
        }
        if page > pages {
            page = pages
        }
        
        self.pdfPageRef = CGPDFDocumentGetPage(self.pdfDocRef, page)!
        
        let cropBoxRect = CGPDFPageGetBoxRect(pdfPageRef, .CropBox)
        let mediaBoxRect = CGPDFPageGetBoxRect(pdfPageRef, .MediaBox)
        let effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect)
        
        /// Determine the page angle
        self.pageAngle = Int(CGPDFPageGetRotationAngle(pdfPageRef))
        
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
            pageWidth--
        }
        
        if pageHeight % 2 != 0 {
            pageHeight--
        }
        
        viewRect.size = CGSizeMake(CGFloat(pageWidth), CGFloat(pageHeight))
        
        /// Finish the init with sizes
        super.init(frame: viewRect)
        
        self.autoresizesSubviews = false
        self.userInteractionEnabled = false
        self.contentMode = .Redraw
        self.autoresizingMask = .None
        self.backgroundColor = UIColor.clearColor()
    }
    
    convenience init(document: PDFDocument, page:Int) {
        
        self.init(url: document.fileUrl, page:page, password:document.password)
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
            
            let color = self.tintColor
            
            for link in links {
                
                let highlight = UIView(frame: link.rect)
                highlight.autoresizesSubviews = false
                highlight.userInteractionEnabled = false
                highlight.contentMode = .Redraw
                highlight.autoresizingMask = .None
                highlight.backgroundColor = color
                
                self.addSubview(highlight)
            }
        }
    }
    
    func linkFromAnnotation(annotation: CGPDFDictionaryRef) {
        
        
    }
    
    
    //MARK: - Gesture Recognizer
    func processSingleTap(recognizer: UIGestureRecognizer) {
        
    }
    
    //MARK: - CATiledLayer Delegate Methods
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
        
        /// Translate for page
        CGContextTranslateCTM(ctx, 0.0, self.bounds.size.height); CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(self.pdfPageRef, .CropBox, self.bounds, 0, true));
        
        /// Render the PDF page into the context
        CGContextDrawPDFPage(ctx, self.pdfPageRef);
    }
    
    
}


class PDFDocumentLink: NSObject {
    
    var rect:CGRect
    var dictionary:CGPDFDictionaryRef
    
    static func new(rect:CGRect, dictionary:CGPDFDictionaryRef) -> PDFDocumentLink {
        
        return PDFDocumentLink(rect: rect, dictionary: dictionary)
    }
    
    
    init(rect:CGRect, dictionary:CGPDFDictionaryRef) {
        
        self.rect = rect
        self.dictionary = dictionary
        
        super.init()
        
    }
    
    
}