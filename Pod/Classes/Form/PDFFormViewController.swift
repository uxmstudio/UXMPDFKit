//
//  PDFFormViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import Foundation

open class PDFFormViewController: NSObject {
    var formPages: [Int: PDFFormPage] = [:]
    
    let document: PDFDocument
    let parser: PDFObjectParser
    var lastPage: PDFPageContentView?
    
    public init(document: PDFDocument) {
        self.document = document
        
        parser = PDFObjectParser(document: document)
        
        super.init()
        
        setupUI()
    }
    
    func setupUI() {
        DispatchQueue.global().async {
            guard let attributes = self.parser.attributes else {
                return
            }
            guard let pages = attributes["Pages"] as? PDFDictionary else {
                return
            }
            guard let kids = pages.arrayForKey("Kids") else {
                return
            }
            
            var page = kids.count
            
            for kid in kids {
                if let dict = kid as? PDFDictionary,
                    let annots = dict.arrayForKey("Annots") {
                    
                    for annot in annots {
                        
                        guard let annot = annot as? PDFDictionary else { continue }
                        
                        self.enumerate(annot, page: page)
                    }
                }
                page -= 1
            }

            if let lastPage = self.lastPage {
                DispatchQueue.main.async {
                    self.showForm(lastPage)
                }
            }
        }
    }
    
    func enumerate(_ fieldDict: PDFDictionary, page: Int = 0) {
        
        
        if fieldDict["Subtype"] != nil {
            createFormField(fieldDict, page: page)
            return
        }
        
        guard let array = fieldDict.arrayForKey("Kids") else {
            return
        }
        
        for dict in array {
            guard let innerFieldDict = dict as? PDFDictionary else { continue }
            if let type = innerFieldDict["Type"] as? String , type == "Annot" {
                createFormField(innerFieldDict, page: page)
            }
            else {
                enumerate(innerFieldDict, page: page)
            }
        }
    }
    
    func createFormField(_ dict: PDFDictionary, page: Int = 0) {
        DispatchQueue.main.async {
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
    
    func showForm(_ contentView: PDFPageContentView) {
        lastPage = contentView
        let page = contentView.page
        if let formPage = self.formPage(page) {
            formPage.showForm(contentView)
        }
    }
    
    func formPage(_ page: Int) -> PDFFormPage? {
        if page > (formPages.count + 1) {
            return nil
        }
        return formPages[page]
    }
}

extension PDFFormViewController: PDFRenderer {
    public func render(_ page: Int, context: CGContext, bounds: CGRect) {
        if let form = formPage(page) {
            form.renderInContext(context, size: bounds)
        }
    }
}
