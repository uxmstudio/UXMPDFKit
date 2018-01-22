//
//  PDFFormViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import Foundation

open class UXMFormViewController: NSObject {
    var formPages: [Int: UXMFormPage] = [:]
    
    let document: UXMPDFDocument
    let parser: UXMObjectParser
    var lastPage: UXMPageContentView?
    
    public init(document: UXMPDFDocument) {
        self.document = document
        
        parser = UXMObjectParser(document: document)
        
        super.init()
        
        setupUI()
    }
    
    func setupUI() {
        DispatchQueue.global().async {
            guard let attributes = self.parser.attributes else {
                return
            }
            guard let pages = attributes["Pages"] as? UXMDictionary else {
                return
            }
            guard let kids = pages.arrayForKey("Kids") else {
                return
            }
            
            var page = kids.count
            
            for kid in kids {
                if let dict = kid as? UXMDictionary,
                    let annots = dict.arrayForKey("Annots") {
                    
                    for annot in annots {
                        
                        guard let annot = annot as? UXMDictionary else { continue }
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
    
    func enumerate(_ fieldDict: UXMDictionary, page: Int = 0) {
        
        
        if fieldDict["Subtype"] != nil {
            createFormField(fieldDict, page: page)
            return
        }
        
        guard let array = fieldDict.arrayForKey("Kids") else {
            return
        }
        
        for dict in array {
            guard let innerFieldDict = dict as? UXMDictionary else { continue }
            if let type = innerFieldDict["Type"] as? String , type == "Annot" {
                createFormField(innerFieldDict, page: page)
            }
            else {
                enumerate(innerFieldDict, page: page)
            }
        }
    }
    
    func createFormField(_ dict: UXMDictionary, page: Int = 0) {
        DispatchQueue.main.async {
            if let formView = self.form(page: page) {
                formView.createFormField(dict)
            }
            else {
                let formView = UXMFormPage(page: page)
                formView.createFormField(dict)
                self.formPages[page] = formView
            }
        }
    }
    
    func showForm(_ contentView: UXMPageContentView) {
        lastPage = contentView
        let page = contentView.page
        if let formPage = self.form(page: page) {
            formPage.showForm(contentView)
        }
    }
    
    func form(page: Int) -> UXMFormPage? {
        return formPages[page]
    }
}

extension UXMFormViewController: UXMRenderer {
    public func render(_ page: Int, context: CGContext, bounds: CGRect) {
        if let form = form(page: page) {
            form.renderInContext(context, size: bounds)
        }
    }
}
