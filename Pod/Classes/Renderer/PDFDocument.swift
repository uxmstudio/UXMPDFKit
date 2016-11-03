//
//  PDFDocument.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

open class PDFDocument: NSObject, NSCoding {
    
    lazy open var documentRef:CGPDFDocument? = {
        do {
            if let fileUrl = self.fileUrl {
                return try CGPDFDocument.create(fileUrl, password: self.password)
            }
            else if let fileData = self.fileData,
                let dataProvider = CGDataProvider(data: fileData) {
                return CGPDFDocument(dataProvider)
            }
            else {
                return nil
            }
        } catch {
            return nil
        }
    }()
    
    /// Document Properties
    open var password: String?
    open var lastOpen: Date?
    open var pageCount: Int = 0
    open var currentPage: Int = 1
    open var bookmarks: NSMutableIndexSet = NSMutableIndexSet()
    open var fileUrl: URL?
    open var fileData: NSData?
    open var fileSize: Int = 0
    open var guid: String
    
    /// File Properties
    open var title: String?
    open var author: String?
    open var subject: String?
    open var keywords: String?
    open var creator: String?
    open var producer: String?
    open var modificationDate: Date?
    open var creationDate: Date?
    open var version:Float = 0.0
    
    static func documentFromFile(_ filePath: String, password: String?) throws -> PDFDocument? {
        
        var document:PDFDocument? = PDFDocument.unarchiveDocumentForFile(filePath, password: password)
        
        if document == nil {
            document = try PDFDocument(filePath: filePath, password: password)
        }
        
        return document
    }
    
    static func unarchiveDocumentForFile(_ filePath: String, password: String?) -> PDFDocument? {
        
        return nil
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        self.guid = aDecoder.decodeObject(forKey: "fileGUID") as! String
        self.currentPage = aDecoder.decodeObject(forKey: "currentPage") as! Int
        self.bookmarks = aDecoder.decodeObject(forKey: "bookmarks") as! NSMutableIndexSet
        self.lastOpen = aDecoder.decodeObject(forKey: "lastOpen") as? Date
        self.fileUrl = URL(fileURLWithPath: aDecoder.decodeObject(forKey: "fileURL") as! String)
        
        super.init()
        
        try! self.loadDocumentInformation()
    }
    
    public convenience init(filePath: String) throws {
        
        try self.init(filePath: filePath, password: nil)
    }
    
    public init(filePath: String, password: String?) throws {
        
        self.guid = PDFDocument.GUID()
        self.password = password
        self.fileUrl = URL(fileURLWithPath: filePath, isDirectory: false)
        self.lastOpen = Date()
        
        super.init()
        
        try self.loadDocumentInformation()
        
        self.save()
    }
    
    public init(fileData: NSData, password: String?) throws {
        
        self.guid = PDFDocument.GUID()
        self.password = password
        self.fileData = fileData
        self.lastOpen = NSDate() as Date
        
        super.init()
        
        try self.loadDocumentInformation()
        
        self.save()
    }
    
    func loadDocumentInformation() throws {
        guard let pdfDocRef = documentRef else {
            return
        }
        
        let infoDic: CGPDFDictionaryRef = pdfDocRef.info!
        var string: CGPDFStringRef? = nil
        
        if CGPDFDictionaryGetString(infoDic, "Title", &string) {
            
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                self.title = ref as String
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "Author", &string) {
            
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                self.author = ref as String
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "Subject", &string) {
            
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                self.subject = ref as String
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "Keywords", &string) {
            
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                self.keywords = ref as String
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "Creator", &string) {
            
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                self.creator = ref as String
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "Producer", &string) {
            
            if let ref: CFString = CGPDFStringCopyTextString(string!) {
                self.producer = ref as String
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "CreationDate", &string) {
            
            if let ref: CFDate = CGPDFStringCopyDate(string!) {
                self.creationDate = ref as Date
            }
        }
        
        if CGPDFDictionaryGetString(infoDic, "ModDate", &string) {
            
            if let ref: CFDate = CGPDFStringCopyDate(string!) {
                self.modificationDate = ref as Date
            }
        }
        
        //            let majorVersion = UnsafeMutablePointer<Int32>()
        //            let minorVersion = UnsafeMutablePointer<Int32>()
        //            CGPDFDocumentGetVersion(pdfDocRef, majorVersion, minorVersion)
        //            self.version = Float("\(majorVersion).\(minorVersion)")!
        
        self.pageCount = pdfDocRef.numberOfPages
    }
    
    
    //MARK: - Helper methods
    
    static func GUID() -> String {
        
        return ProcessInfo.processInfo.globallyUniqueString
    }
    
    open static func documentsPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    open static func applicationPath() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return (paths.first! as NSString).deletingLastPathComponent
    }
    
    open static func applicationSupportPath() -> String {
        
        let fileManager = FileManager()
        let pathURL = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return pathURL.path
    }
    
    static func archiveFilePathForFileAtPath(_ path: String) -> String {
        
        let archivePath = PDFDocument.applicationSupportPath()
        let archiveName = "random-name-fix-later.plist"
        return (archivePath as NSString).appendingPathComponent(archiveName)
    }
    
    func archiveWithFileAtPath(_ filePath: String) -> Bool {
        
        let archiveFilePath = PDFDocument.archiveFilePathForFileAtPath(filePath)
        return NSKeyedArchiver.archiveRootObject(self, toFile: archiveFilePath)
    }
    
    open func save() {
        
        if let filePath = fileUrl?.path {
            let _ = self.archiveWithFileAtPath(filePath)
        }
    }
    
    open func reloadProperties() {
        try! self.loadDocumentInformation()
    }
    
    open func boundsForPDFPage(_ page: Int) -> CGRect {
        let pageRef = documentRef?.page(at: page)
        
        let cropBoxRect: CGRect = pageRef!.getBoxRect(.cropBox)
        let mediaBoxRect: CGRect = pageRef!.getBoxRect(.mediaBox)
        let effectiveRect: CGRect = cropBoxRect.intersection(mediaBoxRect)
        
        let pageAngle: Int = Int(pageRef?.rotationAngle ?? 0)
        
        switch (pageAngle) {
        case 0, 180: // 0 and 180 degrees
            return effectiveRect
        case 90, 270: // 90 and 270 degrees
            return CGRect(
                x: effectiveRect.origin.y,
                y: effectiveRect.origin.x,
                width: effectiveRect.size.height,
                height: effectiveRect.size.width
            )
        default:
            return effectiveRect
        }
    }
    
    //    func setCurrentPage(currentPage: Int) {
    //
    //        if currentPage < 1 {
    //            self.currentPage = 1
    //        }
    //        else if currentPage > self.pageCount {
    //            self.currentPage = self.pageCount
    //        }
    //    }
    
    open func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.guid, forKey: "fileGUID")
        aCoder.encode(self.currentPage, forKey: "currentPage")
        aCoder.encode(self.bookmarks, forKey: "bookmarks")
        aCoder.encode(self.lastOpen, forKey: "lastOpen")
        aCoder.encode(self.fileUrl?.path, forKey: "fileURL")
    }
}
