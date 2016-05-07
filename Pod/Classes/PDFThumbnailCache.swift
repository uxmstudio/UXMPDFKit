//
//  PDFThumbnailCache.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

enum ThumbnailState {
    case New, Started, Finished, Failed
}

public class PDFThumbnail {
    
    var state = ThumbnailState.New
    var image:UIImage?
    var path:NSURL
    var page:Int
    var guid:String
    
    init(path:NSURL, page: Int, guid: String) {
        self.page = page
        self.path = path
        self.guid = guid
    }
}

public class PDFQueue {
    
    lazy var rendersInProgress = [String:NSOperation]()
    lazy var renderQueue:NSOperationQueue = {
        
        var queue = NSOperationQueue()
        queue.name = "PDFQueue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    var progressBlock:((PDFThumbnail) -> Void)?
    
    static let sharedQueue = PDFQueue()
    
    func fetchAll(document: PDFDocument) {
        
        for i in 1...document.pageCount {
            self.fetchPage(document, page: i, completion: nil)
        }
    }
    
    public static func fetchAll(document: PDFDocument) {
        self.sharedQueue.fetchAll(document)
    }
    
    func fetchPage(document: PDFDocument, page: Int, completion:((PDFThumbnail) -> Void)?) {
        
        let guid = "\(document.guid)_\(page)"
        let thumbnail = PDFThumbnail(path: document.fileUrl, page: page, guid: guid)
        
        if let image = PDFThumbnailCache.sharedCache.objectForKey(guid) {
            thumbnail.image = image
            completion?(thumbnail)
        }

        let thumbRender = PDFThumbRenderer(thumbnail: thumbnail)
        thumbRender.completionBlock = {
            self.rendersInProgress.removeValueForKey(guid)
            self.progressBlock?(thumbRender.thumbnail)
            completion?(thumbRender.thumbnail)
        }
        self.rendersInProgress[guid] = thumbRender
        self.renderQueue.addOperation(thumbRender)
    }
    
    public static func fetchPage(document: PDFDocument, page: Int, completion:((PDFThumbnail) -> Void)?) {
        self.sharedQueue.fetchPage(document, page: page, completion:completion)
    }
}


class PDFThumbRenderer: NSOperation {
    
    let thumbnail:PDFThumbnail
    
    init(thumbnail: PDFThumbnail) {
        
        self.thumbnail = thumbnail
    }
    
    override func main() {
        
        self.thumbnail.state = .Started
        
        if self.cancelled {
            return
        }
        
        guard let image = renderPDF() else {
            PDFThumbnailCache.sharedCache.removeObjectForKey(self.thumbnail.guid)
            self.thumbnail.state = .Failed
            return
        }
        
        self.thumbnail.state = .Finished
        
        if self.cancelled {
            return
        }
        
        self.thumbnail.image = image
        PDFThumbnailCache.sharedCache.setObject(image, key: self.thumbnail.guid)
    }
    
    func renderPDF() -> UIImage? {
        
        let documentRef = CGPDFDocumentCreateWithURL(self.thumbnail.path)
        guard let page = CGPDFDocumentGetPage(documentRef, self.thumbnail.page) else { return nil }
        
        let pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
        
        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextFillRect(context,pageRect)
        
        CGContextTranslateCTM(context, 0.0, pageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGContextDrawPDFPage(context, page);
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
}

class PDFThumbnailCache {
    
    lazy var cache:NSCache = {
        let cache = NSCache()
        cache.name = "PDFThumbnailCache"
        cache.countLimit = 150
        cache.totalCostLimit = 10*1024*1024
        return cache
    }()
    
    static let sharedCache = PDFThumbnailCache()
    
    func objectForKey(key: String) -> UIImage? {
        return self.cache.objectForKey(key) as? UIImage
    }
    
    func setObject(image: UIImage, key: String) {
        let bytes:Int = Int(image.size.width * image.size.height * 4.0)
        self.cache.setObject(image, forKey: key, cost: bytes)
    }
    
    func removeObjectForKey(key: String) {
        self.cache.removeObjectForKey(key)
    }
    
    func removeAllObjects() {
        self.cache.removeAllObjects()
    }
}