//
//  PDFFormViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import Foundation

public class PDFFormViewController:NSObject {
    
    var formViews:[Int:PDFFormView] = [:]
    var currentForm:PDFFormView?
    
    var document:PDFDocument
    var parser:PDFObjectParser
    
    public init(document: PDFDocument) {
        
        self.document = document
        self.parser = PDFObjectParser(document: document)
        
        super.init()
        
        self.setupUI()
    }
    
    func setupUI() {
        
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
            
            if let formView = self.formViewForPage(page) {
                formView.createFormField(dict)
            }
            else {
                
                let formView = PDFFormView(frame: CGRectZero, page: page)
                formView.createFormField(dict)
                self.formViews[page] = formView
            }
        }
    }

    func showForm(contentView:PDFPageContentView) {
        
        let page = contentView.page
        if let formView = self.formViewForPage(page) {
            
            formView.zoomScale = contentView.zoomScale
            formView.setSize(
                contentView.frame,
                boundingBox: contentView.containerView.frame,
                cropBox: contentView.contentView.cropBoxRect
            )
            contentView.contentView.addSubview(formView)
            contentView.viewDidZoom = { scale in

                formView.updateWithZoom(scale)
            }
        }
    }
    
    func formViewForPage(page: Int) -> PDFFormView? {
        
        if page > self.formViews.count {
            return nil
        }
        return self.formViews[page]
    }
    
    
    func renderFormOntoPDF() {
        let documentRef = document.documentRef
        let pages = document.pageCount
        let tempPath = NSTemporaryDirectory().stringByAppendingString("annotated.pdf")
        
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
                
                if let form = formViewForPage(i) {
                    form.renderInContext(context)
                }
            }
        }
        UIGraphicsEndPDFContext()
    }
    
    func saveToPDF() -> Bool {
        return false
    }
}