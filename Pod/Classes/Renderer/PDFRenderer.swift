//
//  PDFRenderer.swift
//  Pods
//
//  Created by Chris Anderson on 6/25/16.
//
//

import Foundation

public protocol PDFRenderer {
    func render(page: Int, context:CGContext, bounds: CGRect)
}

public class PDFRenderController {
    
    var document:PDFDocument
    var renderControllers:[PDFRenderer] = []
    
    init(document: PDFDocument, controllers:[PDFRenderer]) {
        self.document = document
        self.renderControllers = controllers
    }
    
    public func renderOntoPDF() -> NSURL {
        let documentRef = document.documentRef
        let pages = document.pageCount
        let title = document.fileUrl.lastPathComponent ?? "annotated.pdf"
        let tempPath = NSTemporaryDirectory().stringByAppendingString(title)
        
        UIGraphicsBeginPDFContextToFile(tempPath, CGRectZero, nil)
        for i in 1...pages {
            let page = CGPDFDocumentGetPage(documentRef, i)
            let bounds = self.document.boundsForPDFPage(i)
            
            if let context = UIGraphicsGetCurrentContext() {
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                CGContextTranslateCTM(context, 0, bounds.size.height)
                CGContextScaleCTM(context, 1.0, -1.0)
                CGContextDrawPDFPage (context, page)
                
                CGContextScaleCTM(context, 1.0, -1.0)
                CGContextTranslateCTM(context, 0, -bounds.size.height)
                
                for controller in renderControllers {
                    controller.render(i, context:context, bounds:bounds)
                }
            }
        }
        UIGraphicsEndPDFContext()
        
        return NSURL.fileURLWithPath(tempPath)
    }
    
    public func save(url: NSURL) -> Bool {
        
        let tempUrl = self.renderOntoPDF()
        let fileManger = NSFileManager.defaultManager()
        do {
            try fileManger.copyItemAtURL(tempUrl, toURL: url)
        }
        catch _ { return false }
        return true
    }
}
