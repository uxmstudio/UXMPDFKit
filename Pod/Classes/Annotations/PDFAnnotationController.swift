//
//  PDFAnnotationController.swift
//  Pods
//
//  Created by Chris Anderson on 6/22/16.
//
//

import Foundation

enum PDFAnnotationType {
    case None
    case Pen
    case Text
    case Highlighter
}

public class PDFAnnotationController:UIViewController {
    
    var document:PDFDocument!
    var annotations:PDFAnnotationStore = PDFAnnotationStore()
    var currentPage:PDFPageContentView?
    var pageView:PDFPageContent?
    var lastPoint:CGPoint?
    var annotationType:PDFAnnotationType = .None
    
    var currentAnnotation:PDFAnnotation?
    
    public init(document: PDFDocument) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
        
        self.setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        self.view.userInteractionEnabled = self.annotationType != .None
        self.view.opaque = false
        self.view.backgroundColor = UIColor.clearColor()
    }
    
    func showAnnotations(contentView:PDFPageContentView) {
        
        self.currentPage = contentView
        let page = contentView.page
        
        self.pageView = contentView.contentView
        
        var annotations = self.annotations.annotationsForPage(page)
        for annot in annotations {
            self.pageView?.addSubview(annot.mutableView())
        }
    }
    
    func startAnnotation(type: PDFAnnotationType) {
        
        self.finishAnnotation()
        self.annotationType = type
        
        if type == .Pen { self.currentAnnotation = PDFPathAnnotation() }
        else if type == .Highlighter { self.currentAnnotation = PDFHighlighterAnnotation() }
        else if type == .Text { self.currentAnnotation = PDFTextAnnotation() }
        
        self.view.userInteractionEnabled = self.annotationType != .None
        
        if let annotation = self.currentAnnotation {
            self.pageView?.addSubview(annotation.mutableView())
        }
    }
    
    func finishAnnotation() {
        
        guard let annotation = self.currentAnnotation else { return }
        guard let currentPage = self.currentPage else { return }

        self.annotations.add(annotation, page: currentPage.page)
        
        self.annotationType == .None
        self.currentAnnotation = nil
        self.view.userInteractionEnabled = false
    }
    
    
    @IBAction func selectedPen() {
        if self.annotationType == .Pen {
            self.finishAnnotation()
        }
        else {
            self.startAnnotation(.Pen)
        }
    }
    
    @IBAction func selectedHighlighter() {
        if self.annotationType == .Highlighter {
            self.finishAnnotation()
        }
        else {
           self.startAnnotation(.Highlighter)
        }
    }
    
    @IBAction func selectedText() {
        if self.annotationType == .Text {
            self.finishAnnotation()
        }
        else {
            self.startAnnotation(.Text)
        }
    }
    
    func hide() {
        
    }
    
    func undo() {
        
    }
    
    func clear() {
        
    }
    
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

        guard let touch = touches.first else { return }
        let point = touch.locationInView(self.pageView)
        
        if let annotation = self.currentAnnotation {
            annotation.touchStarted(touch, point: point)
        }
        
        self.lastPoint = point
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let point = touch.locationInView(self.pageView)
        
        if let annotation = self.currentAnnotation {
            annotation.touchMoved(touch, point: point)
        }
        
        self.lastPoint = point
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let point = touch.locationInView(self.pageView)
        
        if let annotation = self.currentAnnotation {
            annotation.touchEnded(touch, point: point)
        }
        
        self.lastPoint = point
    }
}