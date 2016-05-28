//
//  PDFFormViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import Foundation

public class PDFFormViewController:NSObject {
    
    var formViews:[PDFFormView] = []
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
        guard let fields = attributes.arrayForKey("Fields") else {
            return
        }
        
        for field in fields {
            if let dictField:PDFDictionary = field as? PDFDictionary {
                self.enumerate(dictField)
            }
        }
    }
    
    func enumerate(fieldDict:PDFDictionary, page:Int? = nil) {
        
        guard let array = fieldDict.arrayForKey("Kids") else {
            return
        }
        
        var i = array.count()
        
        for dict in array {
            if let innerFieldDict:PDFDictionary = dict as? PDFDictionary {
                
                if innerFieldDict["Annot"] != nil {
                    self.createAnnotationForm(innerFieldDict, page: (page ?? i))
                }
                else {
                    self.enumerate(innerFieldDict, page: (page ?? i))
                }
                i = i-1
            }
        }
    }
    
    
    func createAnnotationForm(dict: PDFDictionary, page: Int) {
        
        print("Page \(page)")
        print(dict.allKeys())
        print(dict["T"])
        print(dict["Tx"])
        //
        //        PDFFormField(frame: dict)
    }
    
    
    func showForm(contentView:PDFPageContentView) {
        
        var page = contentView.page
    }
    
    func formViewForPage(page: Int) -> PDFFormView? {
        
        if page > self.formViews.count {
            return nil
        }
        return self.formViews[page]
    }
}