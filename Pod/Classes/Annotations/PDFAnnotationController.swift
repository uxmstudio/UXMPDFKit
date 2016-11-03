//
//  PDFAnnotationController.swift
//  Pods
//
//  Created by Chris Anderson on 6/22/16.
//
//

import Foundation

public enum PDFAnnotationType {
    case none
    case pen
    case text
    case highlighter
}

open class PDFAnnotationController: UIViewController {
    
    var document: PDFDocument!
    var annotations: PDFAnnotationStore = PDFAnnotationStore()
    var currentPage: PDFPageContentView?
    var pageView: PDFPageContent?
    var lastPoint: CGPoint?
    var annotationType: PDFAnnotationType = .none
    
    var currentAnnotation: PDFAnnotation?
    
    //MARK: - Bar button items
    lazy var penButton: PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("pen"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedPen(_:))
    )
    
    lazy var highlighterButton: PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("highlighter"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedHighlighter(_:))
    )
    
    lazy var textButton: PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("text-symbol"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedText(_:))
    )
    
    lazy var undoButton: PDFBarButton = PDFBarButton(
        image: UIImage.bundledImage("undo"),
        toggled: false,
        target: self,
        action: #selector(PDFAnnotationController.selectedUndo(_:))
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
        
        self.view.isUserInteractionEnabled = self.annotationType != .none
        self.view.isOpaque = false
        self.view.backgroundColor = UIColor.clear
    }
    
    
    //MARK: - Annotation handling
    open func showAnnotations(_ contentView: PDFPageContentView) {
        
        self.currentPage = contentView
        let page = contentView.page
        
        self.pageView = contentView.contentView
        
        let annotations = self.annotations.annotationsForPage(page)
        for annot in annotations {
            self.pageView?.addSubview(annot.mutableView())
        }
    }
    
    open func startAnnotation(_ type: PDFAnnotationType) {
        
        self.finishAnnotation()
        self.annotationType = type
        
        switch type {
        case .pen:
            self.currentAnnotation = PDFPathAnnotation()
        case .highlighter:
            self.currentAnnotation = PDFHighlighterAnnotation()
        case .text:
            self.currentAnnotation = PDFTextAnnotation()
        case .none:
            break
        }
        
        self.view.isUserInteractionEnabled = self.annotationType != .none
        
        if let annotation = self.currentAnnotation {
            self.pageView?.addSubview(annotation.mutableView())
        }
    }
    
    open func finishAnnotation() {
        
        guard let annotation = self.currentAnnotation else { return }
        guard let currentPage = self.currentPage else { return }
        
        self.annotations.add(annotation, page: currentPage.page)
        
        self.annotationType = .none
        self.currentAnnotation = nil
        self.view.isUserInteractionEnabled = false
    }
    
    
    
    //MARK: - Bar button actions
    
    func unselectAll() {
        for button in [penButton, highlighterButton, textButton] {
            button.toggle(false)
        }
    }
    
    func selectedType(_ button: PDFBarButton, type: PDFAnnotationType) {
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
    
    @IBAction func selectedPen(_ button: PDFBarButton) {
        self.selectedType(button, type: .pen)
    }
    
    @IBAction func selectedHighlighter(_ button: PDFBarButton) {
        self.selectedType(button, type: .highlighter)
    }
    
    @IBAction func selectedText(_ button: PDFBarButton) {
        self.selectedType(button, type: .text)
    }
    
    @IBAction func selectedUndo(_ button: PDFBarButton) {
        self.undo()
    }
    
    func hide() {
        
    }
    
    func undo() {
        
        self.clear()
        guard let currentPage = self.currentPage else { return }
        let _ = self.annotations.undo(currentPage.page)
        self.showAnnotations(currentPage)
    }
    
    func clear() {
        
        guard let pageView = self.pageView else { return }
        for subview in pageView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    
    
    //MARK: - Touches methods to pass to annotation
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let point = touch.location(in: self.pageView)
        
        if let annotation = self.currentAnnotation {
            annotation.touchStarted(touch, point: point)
        }
        
        self.lastPoint = point
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let point = touch.location(in: self.pageView)
        
        if let annotation = self.currentAnnotation {
            annotation.touchMoved(touch, point: point)
        }
        
        self.lastPoint = point
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let point = touch.location(in: self.pageView)
        
        if let annotation = self.currentAnnotation {
            annotation.touchEnded(touch, point: point)
        }
        
        self.lastPoint = point
    }
}

extension PDFAnnotationController: PDFRenderer {
    
    public func render(_ page: Int, context: CGContext, bounds: CGRect) {
        
        if let page = annotations.get(page) {
            page.renderInContext(context, size: bounds)
        }
    }
}
