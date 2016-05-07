//
//  PDFSnapshotCache.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

enum SnapshotState {
    case New, Started, Finished, Failed
}

public class PDFSnapshot {
    
    var state = SnapshotState.New
    var image:UIImage?
    var path:NSURL
    var page:Int
    var guid:String
    var size:CGSize
    
    init(path:NSURL, page: Int, guid: String, size: CGSize) {
        self.page = page
        self.path = path
        self.guid = guid
        self.size = size
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
    
    var progressBlock:((PDFSnapshot) -> Void)?
    
    static let sharedQueue = PDFQueue()
    
    func fetchPage(document: PDFDocument, page: Int, size: CGSize, completion:((PDFSnapshot) -> Void)?) {
        
        let guid = "\(document.guid)_\(page)"
        let thumbnail = PDFSnapshot(path: document.fileUrl, page: page, guid: guid, size: size)
        
        if let image = PDFSnapshotCache.sharedCache.objectForKey(guid) {
            thumbnail.image = image
            dispatch_async(dispatch_get_main_queue()){
                completion?(thumbnail)
            }
        }

        let thumbRender = PDFSnapshotRenderer(snapshot: thumbnail)
        thumbRender.completionBlock = {
            self.rendersInProgress.removeValueForKey(guid)
            dispatch_async(dispatch_get_main_queue()){
                self.progressBlock?(thumbRender.snapshot)
                completion?(thumbRender.snapshot)
            }
        }
        self.rendersInProgress[guid] = thumbRender
        self.renderQueue.addOperation(thumbRender)
    }
    
    public static func fetchPage(document: PDFDocument, page: Int, size: CGSize, completion:((PDFSnapshot) -> Void)?) {
        self.sharedQueue.fetchPage(document, page: page, size: size, completion:completion)
    }
}


class PDFSnapshotRenderer: NSOperation {
    
    let snapshot:PDFSnapshot
    
    init(snapshot: PDFSnapshot) {
        
        self.snapshot = snapshot
    }
    
    override func main() {
        
        self.snapshot.state = .Started
        
        if self.cancelled {
            return
        }
        
        guard let image = renderPDF(snapshot.size) else {
            PDFSnapshotCache.sharedCache.removeObjectForKey(self.snapshot.guid)
            self.snapshot.state = .Failed
            return
        }
        
        self.snapshot.state = .Finished
        
        if self.cancelled {
            return
        }
        
        self.snapshot.image = image
        PDFSnapshotCache.sharedCache.setObject(image, key: self.snapshot.guid)
    }
    
    func renderPDF(size: CGSize) -> UIImage? {
        
        let documentRef = CGPDFDocumentCreateWithURL(self.snapshot.path)
        guard let page = CGPDFDocumentGetPage(documentRef, self.snapshot.page) else { return nil }
        
        var pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
        let scale = min(size.width / pageRect.size.width, size.height / pageRect.size.height)
        pageRect.size = CGSizeMake(pageRect.size.width * scale, pageRect.size.height * scale)
        

        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 0)
        let context = UIGraphicsGetCurrentContext()

        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(context, pageRect)
        
        CGContextSaveGState(context)

        CGContextTranslateCTM(context, 0.0, pageRect.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        CGContextScaleCTM(context, scale, scale)
        CGContextDrawPDFPage(context, page)
        CGContextRestoreGState(context)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img
    }
}

class PDFSnapshotCache {
    
    lazy var cache:NSCache = {
        let cache = NSCache()
        cache.name = "PDFSnapshotCache"
        cache.countLimit = 150
        cache.totalCostLimit = 10*1024*1024
        return cache
    }()
    
    static let sharedCache = PDFSnapshotCache()
    
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