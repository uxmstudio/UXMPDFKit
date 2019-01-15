//
//  PDFRenderer.swift
//  Pods
//
//  Created by Chris Anderson on 6/25/16.
//
//

import Foundation

public protocol PDFRenderer {
    func render(_ page: Int, context:CGContext, bounds: CGRect)
}

open class PDFRenderController {
    let document: PDFDocument
    let renderControllers: [PDFRenderer]
    
    public init(document: PDFDocument, controllers: [PDFRenderer]) {
        self.document = document
        self.renderControllers = controllers
    }
    
    open func renderOntoPDF() -> URL {
        let documentRef = document.documentRef
        let pages = document.pageCount
        let title = document.fileUrl?.lastPathComponent ?? "annotated.pdf"
        let documentInfo = {() -> Dictionary<CFString, String>? in
            guard let password = document.password else { return nil }
            return [kCGPDFContextUserPassword: password, kCGPDFContextOwnerPassword: password]
        }()
        let tempPath = NSTemporaryDirectory() + title
        
        UIGraphicsBeginPDFContextToFile(tempPath, CGRect.zero, documentInfo)
        for i in 1...pages {
            let page = documentRef?.page(at: i)
            let bounds = document.boundsForPDFPage(i)
            
            guard let context = UIGraphicsGetCurrentContext() else { continue }
            UIGraphicsBeginPDFPageWithInfo(bounds, nil)
            context.translateBy(x: 0, y: bounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.drawPDFPage (page!)
            
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -bounds.size.height)
            
            for controller in renderControllers {
                controller.render(i, context:context, bounds:bounds)
            }
        }
        UIGraphicsEndPDFContext()
        
        return URL(fileURLWithPath: tempPath)
    }
    
    open func save(_ url: URL) -> Bool {
        let tempUrl = self.renderOntoPDF()
        let fileManger = FileManager.default
        do {
            try fileManger.copyItem(at: tempUrl, to: url)
        }
        catch _ { return false }
        return true
    }
}
