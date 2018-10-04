//
//  UXMPDFDocument.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

open class UXMPDFDocument: NSObject, NSCoding {
    
    open var documentRef: CGPDFDocument?
    
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
    open var version: Float = 0.0
    
    /// Document annotations
    open var annotations: UXMAnnotationStore = UXMAnnotationStore()
    
    public static func from(filePath: String, password: String? = nil) throws -> UXMPDFDocument? {
        if let document = try UXMPDFDocument.unarchiveDocument(filePath: filePath, password: password) {
            return document
        }
        else {
            return try UXMPDFDocument(filePath: filePath, password: password)
        }
    }
    
    static func unarchiveDocument(filePath: String, password: String?) throws -> UXMPDFDocument? {

        let archiveFilePath = UXMPDFDocument.archiveFilePathForFile(path: filePath)
        if let document = NSKeyedUnarchiver.unarchiveObject(withFile: archiveFilePath) as? UXMPDFDocument {
            document.fileUrl = URL(fileURLWithPath: filePath, isDirectory: false)
            document.password = password
            
            try document.loadDocument()
            return document
        }
        return nil
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.guid = aDecoder.decodeObject(forKey: "fileGUID") as! String
        self.currentPage = aDecoder.decodeInteger(forKey: "currentPage")
        self.bookmarks = aDecoder.decodeObject(forKey: "bookmarks") as! NSMutableIndexSet
        self.lastOpen = aDecoder.decodeObject(forKey: "lastOpen") as? Date
        if let annotations = aDecoder.decodeObject(forKey: "annotations") as? UXMAnnotationStore {
            self.annotations = annotations
        }
        else {
            self.annotations = UXMAnnotationStore()
        }
        
        super.init()
    }
    
    public init(filePath: String, password: String? = nil) throws {
        
        self.guid = UXMPDFDocument.GUID()
        self.password = password
        self.fileUrl = URL(fileURLWithPath: filePath, isDirectory: false)
        self.lastOpen = Date()
        
        super.init()
        
        try self.loadDocument()
        
        // self.save()
    }
    
    public init(fileData: NSData, password: String? = nil) throws {
        self.guid = UXMPDFDocument.GUID()
        self.password = password
        self.fileData = fileData
        self.lastOpen = NSDate() as Date
        
        super.init()
        
        try self.loadDocument()
        
        self.save()
    }
    
    func loadDocument() throws {
        
        if let fileUrl = self.fileUrl {
            self.documentRef =  try CGPDFDocument.create(url: fileUrl, password: self.password)
        }
        else if let fileData = self.fileData {
            self.documentRef =  try CGPDFDocument.create(data: fileData, password: self.password)
        }
        
        if documentRef == nil {
            throw CGPDFDocumentError.unableToOpen
        }
        
        self.loadDocumentInformation()
    }
    
    func loadDocumentInformation() {
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
        
        self.pageCount = pdfDocRef.numberOfPages
    }
    
    func page(at page: Int) -> CGPDFPage? {
        
        if let documentRef = self.documentRef,
            let pageRef = documentRef.page(at: page) {
            return pageRef
        }
        return nil
    }
    
    
    //MARK: - Helper methods
    
    static func GUID() -> String {
        return ProcessInfo.processInfo.globallyUniqueString
    }
    
    public static func documentsPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    public static func applicationPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return (paths.first! as NSString).deletingLastPathComponent
    }
    
    public static func applicationSupportPath() -> String {
        let fileManager = FileManager()
        let pathURL = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return pathURL.path
    }
    
    static func archiveFilePathForFile(path: String) -> String {
        let archivePath = UXMPDFDocument.applicationSupportPath()
        
        let archiveName = (path as NSString).lastPathComponent + ".plist"
        return (archivePath as NSString).appendingPathComponent(archiveName)
    }
    
    func archiveWithFileAtPath(_ filePath: String) -> Bool {
        let archiveFilePath = UXMPDFDocument.archiveFilePathForFile(path: filePath)
        return NSKeyedArchiver.archiveRootObject(self, toFile: archiveFilePath)
    }
    
    open func save() {
        guard let filePath = fileUrl?.path else { return }
        
        // TODO: Better solution to support NSData
        let _ = self.archiveWithFileAtPath(filePath)
    }
    
    open func clearEncodedAnnotations() {
        guard let filePath = fileUrl?.path else { return }
        
        let archiveFilePath = UXMPDFDocument.archiveFilePathForFile(path: filePath)
        
        if FileManager.default.fileExists(atPath: archiveFilePath) {
            try? FileManager.default.removeItem(atPath: archiveFilePath)
        }
    }
    
    open func reloadProperties() {
        self.loadDocumentInformation()
    }
    
    open func boundsForPDFPage(_ page: Int) -> CGRect {
        guard let documentRef = documentRef else { return .zero }
        guard let pageRef = documentRef.page(at: page) else { return .zero }
        
        let cropBoxRect = pageRef.getBoxRect(.cropBox)
        let mediaBoxRect = pageRef.getBoxRect(.mediaBox)
        let effectiveRect = cropBoxRect.intersection(mediaBoxRect)
        
        let pageAngle = Int(pageRef.rotationAngle)
        
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
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.guid, forKey: "fileGUID")
        aCoder.encode(self.currentPage, forKey: "currentPage")
        aCoder.encode(self.bookmarks, forKey: "bookmarks")
        aCoder.encode(self.lastOpen, forKey: "lastOpen")
        aCoder.encode(self.annotations, forKey: "annotations")
    }
}
