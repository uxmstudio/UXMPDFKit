//
//  PDFSnapshotCache.swift
//  Pods
//
//  Created by Chris Anderson on 5/6/16.
//
//

import UIKit

enum SnapshotState {
    case new, started, finished, failed
}

open class PDFSnapshot {
    
    var state = SnapshotState.new
    var image:UIImage?
    var path:URL
    var page:Int
    var guid:String
    var size:CGSize
    
    init(path:URL, page: Int, guid: String, size: CGSize) {
        self.page = page
        self.path = path
        self.guid = guid
        self.size = size
    }
}

open class PDFQueue {
    
    lazy var rendersInProgress = [String:Operation]()
    lazy var renderQueue:OperationQueue = {
        
        var queue = OperationQueue()
        queue.name = "PDFQueue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    var progressBlock:((PDFSnapshot) -> Void)?
    
    static let sharedQueue = PDFQueue()
    
    func fetchPage(_ document: PDFDocument, page: Int, size: CGSize, completion:((PDFSnapshot) -> Void)?) {
        
        let guid = "\(document.guid)_\(page)"
        let thumbnail = PDFSnapshot(path: document.fileUrl as URL, page: page, guid: guid, size: size)
        
        if let image = PDFSnapshotCache.sharedCache.objectForKey(guid) {
            thumbnail.image = image
            DispatchQueue.main.async{
                completion?(thumbnail)
            }
        }

        let thumbRender = PDFSnapshotRenderer(snapshot: thumbnail)
        thumbRender.completionBlock = {
            self.rendersInProgress.removeValue(forKey: guid)
            DispatchQueue.main.async{
                self.progressBlock?(thumbRender.snapshot)
                completion?(thumbRender.snapshot)
            }
        }
        self.rendersInProgress[guid] = thumbRender
        self.renderQueue.addOperation(thumbRender)
    }
    
    open static func fetchPage(_ document: PDFDocument, page: Int, size: CGSize, completion:((PDFSnapshot) -> Void)?) {
        self.sharedQueue.fetchPage(document, page: page, size: size, completion:completion)
    }
}


class PDFSnapshotRenderer: Operation {
    
    let snapshot:PDFSnapshot
    
    init(snapshot: PDFSnapshot) {
        
        self.snapshot = snapshot
    }
    
    override func main() {
        
        self.snapshot.state = .started
        
        if self.isCancelled {
            return
        }
        
        guard let image = renderPDF(snapshot.size) else {
            PDFSnapshotCache.sharedCache.removeObjectForKey(self.snapshot.guid)
            self.snapshot.state = .failed
            return
        }
        
        self.snapshot.state = .finished
        
        if self.isCancelled {
            return
        }
        
        self.snapshot.image = image
        PDFSnapshotCache.sharedCache.setObject(image, key: self.snapshot.guid)
    }
    
    func renderPDF(_ size: CGSize) -> UIImage? {
        
        guard let documentRef = CGPDFDocument((self.snapshot.path as CFURL)),
            let page = documentRef.page(at: self.snapshot.page) else { return nil }
        
        var pageRect = page.getBoxRect(.mediaBox)
        let scale = min(size.width / pageRect.size.width, size.height / pageRect.size.height)
        pageRect.size = CGSize(width: pageRect.size.width * scale, height: pageRect.size.height * scale)
        

        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(pageRect)
        
        context.saveGState()

        context.translateBy(x: 0.0, y: pageRect.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        context.scaleBy(x: scale, y: scale)
        context.drawPDFPage(page)
        context.restoreGState()
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img
    }
}

class PDFSnapshotCache {
    
    lazy var cache:NSCache<NSString, UIImage> = {
        let cache:NSCache<NSString, UIImage> = NSCache<NSString, UIImage>()
        cache.name = "PDFSnapshotCache"
        cache.countLimit = 150
        cache.totalCostLimit = 10*1024*1024
        return cache
    }()
    
    static let sharedCache = PDFSnapshotCache()
    
    func objectForKey(_ key: String) -> UIImage? {
        return self.cache.object(forKey: (key as NSString))
    }
    
    func setObject(_ image: UIImage, key: String) {
        let bytes:Int = Int(image.size.width * image.size.height * 4.0)
        self.cache.setObject(image, forKey: (key as NSString), cost: bytes)
    }
    
    func removeObjectForKey(_ key: String) {
        self.cache.removeObject(forKey: (key as NSString))
    }
    
    func removeAllObjects() {
        self.cache.removeAllObjects()
    }
}
