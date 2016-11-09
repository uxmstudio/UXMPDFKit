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
    var annotations = PDFAnnotationStore()
    var currentPage: PDFPageContentView?
    
    var pageView: PDFPageContent? {
        return currentPage?.contentView
    }
    
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
        
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        view.isUserInteractionEnabled = annotationType != .none
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
    }
    
    //MARK: - Annotation handling
    open func showAnnotations(_ contentView: PDFPageContentView) {
        currentPage = contentView
        
        for annot in annotations.annotationsForPage(contentView.page) {
            pageView?.addSubview(annot.mutableView())
        }
    }
    
    open func startAnnotation(_ type: PDFAnnotationType) {
        finishAnnotation()
        annotationType = type
        
        switch type {
        case .pen:
            currentAnnotation = PDFPathAnnotation()
        case .highlighter:
            currentAnnotation = PDFHighlighterAnnotation()
        case .text:
            currentAnnotation = PDFTextAnnotation()
        case .none:
            break
        }
        
        view.isUserInteractionEnabled = annotationType != .none
        
        if let annotation = currentAnnotation {
            pageView?.addSubview(annotation.mutableView())
        }
    }
    
    open func finishAnnotation() {
        guard let annotation = currentAnnotation else { return }
        guard let currentPage = currentPage else { return }
        
        annotations.add(annotation, page: currentPage.page)
        
        annotationType = .none
        currentAnnotation = nil
        view.isUserInteractionEnabled = false
    }
    
    //MARK: - Bar button actions
    
    func unselectAll() {
        for button in [penButton, highlighterButton, textButton] {
            button.toggle(false)
        }
    }
    
    func selectedType(_ button: PDFBarButton, type: PDFAnnotationType) {
        unselectAll()
        if annotationType == type {
            finishAnnotation()
            button.toggle(false)
        } else {
            startAnnotation(type)
            button.toggle(true)
        }
    }
    
    @IBAction func selectedPen(_ button: PDFBarButton) {
        selectedType(button, type: .pen)
    }
    
    @IBAction func selectedHighlighter(_ button: PDFBarButton) {
        selectedType(button, type: .highlighter)
    }
    
    @IBAction func selectedText(_ button: PDFBarButton) {
        selectedType(button, type: .text)
    }
    
    @IBAction func selectedUndo(_ button: PDFBarButton) {
        undo()
    }
    
    func hide() {
        
    }
    
    func undo() {
        clear()
        guard let currentPage = currentPage else { return }
        let _ = annotations.undo(currentPage.page)
        showAnnotations(currentPage)
    }
    
    func clear() {
        guard let pageView = pageView else { return }
        for subview in pageView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    //MARK: - Touches methods to pass to annotation
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: pageView)
        
        currentAnnotation?.touchStarted(touch, point: point)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: pageView)
        
        currentAnnotation?.touchMoved(touch, point: point)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: pageView)
        
        currentAnnotation?.touchEnded(touch, point: point)
    }
}

extension PDFAnnotationController: PDFRenderer {
    public func render(_ page: Int, context: CGContext, bounds: CGRect) {
        annotations.get(page)?.renderInContext(context, size: bounds)
    }
}
