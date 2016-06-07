//
//  PDFFormViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import Foundation

public class PDFFormViewController:NSObject {
    
    var formPages:[Int:PDFFormPage] = [:]
    
    var document:PDFDocument
    var parser:PDFObjectParser
    var lastPage:PDFPageContentView?
    
    public init(document: PDFDocument) {
        
        self.document = document
        
        self.parser = PDFObjectParser(document: document)
        
        super.init()
        
        self.setupUI()
    }
    
    func setupUI() {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            guard let attributes = self.parser.attributes else {
                return
            }
            
            guard let forms = attributes["AcroForm"] as? PDFDictionary else {
                return
            }
            
            guard let fields = forms.arrayForKey("Fields") else {
                return
            }

            for field in fields {
                if let dictField:PDFDictionary = field as? PDFDictionary {
                    self.enumerate(dictField)
                }
            }

            if let lastPage = self.lastPage {
                dispatch_async(dispatch_get_main_queue()) {
                    self.showForm(lastPage)
                }
            }
        }
    }
    
    func enumerate(fieldDict:PDFDictionary) {
        
        if fieldDict["Subtype"] != nil {
            self.createFormField(fieldDict)
            return
        }
        
        guard let array = fieldDict.arrayForKey("Kids") else {
            return
        }
        
        for dict in array {
            if let innerFieldDict:PDFDictionary = dict as? PDFDictionary {
                
                if let type = innerFieldDict["Type"] as? String where type == "Annot" {
                    self.createFormField(innerFieldDict)
                }
                else {
                    self.enumerate(innerFieldDict)
                }
            }
        }
    }
    
    func getPageNumber(field:PDFDictionary) -> Int? {
        
        guard let attributes = self.parser.attributes else {
            return nil
        }
        guard let pages = attributes["Pages"] as? PDFDictionary else {
            return nil
        }
        guard let kids = pages.arrayForKey("Kids") else {
            return nil
        }
        
        var page = kids.count()
        
        for kid in kids {
            if let dict = kid as? PDFDictionary,
                let annots = dict.arrayForKey("Annots") {
                for subField in annots {
                    if field.isEqual(subField) {
                        return page
                    }
                }
            }
            page -= 1
        }
        
        return page
    }
    
    func createFormField(dict: PDFDictionary) {
        
        if let page = self.getPageNumber(dict) {

            dispatch_async(dispatch_get_main_queue()) {

                if let formView = self.formPage(page) {
                    formView.createFormField(dict)
                }
                else {
                    
                    let formView = PDFFormPage(page: page)
                    formView.createFormField(dict)
                    self.formPages[page] = formView
                }
            }
        }
    }
    
    func showForm(contentView:PDFPageContentView) {
        
        self.lastPage = contentView
        let page = contentView.page
        if let formPage = self.formPage(page) {
            formPage.showForm(contentView)
        }
    }
    
    func formPage(page: Int) -> PDFFormPage? {
        
        if page > self.formPages.count {
            return nil
        }
        return self.formPages[page]
    }
    
    
    public func renderFormOntoPDF() -> NSURL {
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
                
                if let form = formPage(i) {
                    form.renderInContext(context, size: bounds)
                }
            }
        }
        UIGraphicsEndPDFContext()
        
        return NSURL.fileURLWithPath(tempPath)
    }
    
    public func save(url: NSURL) -> Bool {
        
        let tempUrl = renderFormOntoPDF()
        let fileManger = NSFileManager.defaultManager()
        do {
            try fileManger.copyItemAtURL(tempUrl, toURL: url)
        }
        catch _ { return false }
        return true
    }
}