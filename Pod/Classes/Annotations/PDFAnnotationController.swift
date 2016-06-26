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
    
    //MARK: - Bar button items
    lazy var penButton:PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("pen"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedPen(_:))
    )
    
    lazy var highlighterButton:PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("highlighter"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedHighlighter(_:))
    )
    
    lazy var textButton:PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("text-symbol"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedText(_:))
    )
    
    //MARK: - Init
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
    
    
    //MARK: - Annotation handling
    func showAnnotations(contentView:PDFPageContentView) {
        
        self.currentPage = contentView
        let page = contentView.page
        
        self.pageView = contentView.contentView
        
        let annotations = self.annotations.annotationsForPage(page)
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
    
    
    
    //MARK: - Bar button actions 
    
    func unselectAll() {
        for button in [penButton, highlighterButton, textButton] {
            button.toggle(false)
        }
    }
    
    func selectedType(button:PDFBarButton, type: PDFAnnotationType) {
        self.unselectAll()
        if self.annotationType == type {
            self.finishAnnotation()
            button.toggle(false)
        }
        else {
            self.startAnnotation(type)
            button.toggle(true)
        }
    }
    
    @IBAction func selectedPen(button: PDFBarButton) {
        self.selectedType(button, type: .Pen)
    }
    
    @IBAction func selectedHighlighter(button: PDFBarButton) {
        self.selectedType(button, type: .Highlighter)
    }
    
    @IBAction func selectedText(button: PDFBarButton) {
        self.selectedType(button, type: .Text)
    }
    
    func hide() {
        
    }
    
    func undo() {
        
    }
    
    func clear() {
        
    }
    
    
    
    //MARK: - Touches methods to pass to annotation
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

extension PDFAnnotationController: PDFRenderer {
    
    public func render(page: Int, context:CGContext, bounds: CGRect) {
        
        if let page = annotations.get(page) {
            page.renderInContext(context, size: bounds)
        }
    }
}