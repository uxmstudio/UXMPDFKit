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

public protocol PDFAnnotationControllerProtocol {
    func annotationWillStart(touch: UITouch) -> Int?
}

open class PDFAnnotationController: UIViewController {
    var document: PDFDocument!
    
    var annotations = PDFAnnotationStore()
    
    var allPages = [PDFPageContentView]()
    
    var annotationType: PDFAnnotationType = .none
    
    var annotationDelegate: PDFAnnotationControllerProtocol?
    
    var currentAnnotation: PDFAnnotation?
    
    var currentAnnotationPage: Int? {
        return currentAnnotation?.page
    }
    
    var currentPage: PDFPageContentView? {
        return allPages.filter({ $0.page == currentAnnotationPage }).first
    }
    
    var pageView: PDFPageContent? {
        return currentPage?.contentView
    }
    
    func pageViewFor(page: Int) -> PDFPageContent? {
        return self.pageContentViewFor(page: page)?.contentView
    }
    
    func pageContentViewFor(page: Int) -> PDFPageContentView? {
        return allPages.filter({ $0.page == page }).first
    }
    
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
    public init(document: PDFDocument, delegate: PDFAnnotationControllerProtocol) {
        self.document = document
        self.annotations = document.annotations
        self.annotationDelegate = delegate
        
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
        let page = contentView.page
        if let pageIndex = allPages.index(where: { $0.page == page }) {
            clear(pageView: allPages[pageIndex].contentView)
            allPages.remove(at: pageIndex)
        }
        allPages.append(contentView)
        
        let annotationsForPage = annotations.annotations(page: page)
        
        for annotation in annotationsForPage {
            contentView.contentView.addSubview(annotation.mutableView())
        }
    }
    
    open func startAnnotation(_ type: PDFAnnotationType) {
        finishAnnotation()
        annotationType = type
        
        view.isUserInteractionEnabled = annotationType != .none
    }
    
    open func finishAnnotation() {
        // makes sure any textviews resign their first responder status
        for annotation in annotations.annotations {
            guard let annotation = annotation as? PDFTextAnnotation else { continue }
            annotation.textView.resignFirstResponder()
        }
        
        annotationType = .none
        addCurrentAnnotationToStore()
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
        
        if let annotation = annotations.undo() {
            if let annotationPage = annotation.page,
                let pageContentView = self.pageContentViewFor(page: annotationPage) {
                clear(pageView: pageContentView.contentView)
                showAnnotations(pageContentView)
                return
            }
        }
    }
    
    func clear(pageView: PDFPageContent) {
        for subview in pageView.subviews {
            if subview is PDFAnnotationView {
                subview.removeFromSuperview()
            }
        }
    }
    
    //MARK: - Touches methods to pass to annotation
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let page = annotationDelegate?.annotationWillStart(touch: touch)
        
        // Do not add an annotation unless it is a new one
        // IMPORTANT
        if currentAnnotation == nil {
            createNewAnnotation()
            currentAnnotation?.page = page
            if let currentAnnotation = currentAnnotation {
                
                pageView?.addSubview(currentAnnotation.mutableView())
            }
        }
        
        
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
    
    private func createNewAnnotation() {
        switch annotationType {
        case .pen:
            currentAnnotation = PDFPathAnnotation()
        case .highlighter:
            currentAnnotation = PDFHighlighterAnnotation()
        case .text:
            currentAnnotation = PDFTextAnnotation()
        case .none:
            break
        }
    }
    
    private func addCurrentAnnotationToStore() {
        if let currentAnnotation = currentAnnotation {
            annotations.add(annotation: currentAnnotation)
        }
        currentAnnotation = nil
    }
}

extension PDFAnnotationController: PDFRenderer {
    public func render(_ page: Int, context: CGContext, bounds: CGRect) {
        annotations.renderInContext(context, size: bounds, page: page)
    }
}
