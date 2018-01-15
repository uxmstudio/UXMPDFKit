//
//  UXMAnnotationController.swift
//  Pods
//
//  Created by Chris Anderson on 6/22/16.
//
//

import Foundation

public protocol UXMAnnotationControllerProtocol {
    func annotationWillStart(touch: UITouch) -> Int?
}

open class UXMAnnotationController: UIViewController {
    
    /// Reference to document
    var document: UXMPDFDocument!
    
    /// Store containing all annotations for document
    var annotations = UXMAnnotationStore()
    
    /// References to pages within view
    var allPages = [UXMPageContentView]()
    
    /// Type of annotation being added
    var annotationType: UXMAnnotation.Type?
    
    open var annotationTypes: [UXMAnnotation.Type] = [
        UXMTextAnnotation.self,
        PDFPenAnnotation.self,
        PDFHighlighterAnnotation.self,
        ] {
        didSet {
            self.loadButtons(for: self.annotationTypes)
        }
    }
    
    /// The buttons for the created annotation types
    var buttons: [UXMBarButton] = []
    
    /// Delegate reference for annotation events
    var annotationDelegate: UXMAnnotationControllerProtocol?
    
    /// Current annotation
    open var currentAnnotation: UXMAnnotation?
    
    open var currentAnnotationPage: Int? {
        return currentAnnotation?.page
    }

    open var currentPage: UXMPageContentView? {
        return allPages.filter({ $0.page == currentAnnotationPage }).first
    }
    
    var pageView: UXMPageContent? {
        return currentPage?.contentView
    }
    
    func pageViewFor(page: Int) -> UXMPageContent? {
        return self.pageContentViewFor(page: page)?.contentView
    }
    
    func pageContentViewFor(page: Int) -> UXMPageContentView? {
        return allPages.filter({ $0.page == page }).first
    }
    
    //MARK: - Bar button items
    
    lazy var undoButton: UXMBarButton = UXMBarButton(
        image: UIImage.bundledImage("undo"),
        toggled: false,
        target: self,
        action: #selector(UXMAnnotationController.selectedUndo(_:))
    )
    
    /**
     Initializes a new annotation controller
     
     - Parameters:
     - document: The document to display
     - delegate: The delegate for the controller to relay information back on
     
     - Returns: An instance of the PDFAnnotationController
     */
    public init(document: UXMPDFDocument, delegate: UXMAnnotationControllerProtocol) {
        self.document = document
        self.annotations = document.annotations
        self.annotationDelegate = delegate
        
        super.init(nibName: nil, bundle: nil)
        
        setupUI()
    }
    
    /**
     Initializes a new annotation controller
     
     - Parameters:
     - document: The document to display
     - delegate: The delegate for the controller to relay information back on
     - annotationTypes: The type of annotations that should be shown
     
     - Returns: An instance of the PDFAnnotationController
     */
    public convenience init(document: UXMPDFDocument,
                            delegate: UXMAnnotationControllerProtocol,
                            annotationTypes: [UXMAnnotation.Type]) {
        self.init(document: document, delegate: delegate)
        self.annotationTypes = annotationTypes
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        view.isUserInteractionEnabled = annotationType != .none
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
        
        self.loadButtons(for: self.annotationTypes)
    }
    
    //MARK: - Annotation handling
    open func showAnnotations(_ contentView: UXMPageContentView) {
        let page = contentView.page
        if let pageIndex = allPages.index(where: { $0.page == page }) {
            clear(pageView: allPages[pageIndex].contentView)
            allPages.remove(at: pageIndex)
        }
        allPages.append(contentView)
        
        let annotationsForPage = annotations.annotations(page: page)
        
        for annotation in annotationsForPage {
            let view = annotation.mutableView()
            contentView.contentView.addSubview(view)
            contentView.contentView.bringSubview(toFront: view)
        }
    }
    
    open func startAnnotation(_ type: UXMAnnotation.Type?) {
        finishAnnotation()
        annotationType = type
        
        view.isUserInteractionEnabled = annotationType != nil
    }
    
    open func finishAnnotation() {
        
        annotationType = .none
        addCurrentAnnotationToStore()
        view.isUserInteractionEnabled = false
    }
    
    //MARK: - Bar button actions
    
    func unselectAll() {
        for button in self.buttons {
            button.toggle(false)
        }
    }
    
    func selected(button: PDFAnnotationBarButton) {
        unselectAll()
        
        if annotationType == button.annotationType {
            finishAnnotation()
            button.toggle(false)
        }
        else {
            startAnnotation(button.annotationType)
            button.toggle(true)
        }
    }
    
    @IBAction func selectedUndo(_ button: UXMBarButton) {
        
        finishAnnotation()
        undo()
    }
    
    func select(annotation: UXMAnnotation?) {
        self.currentAnnotation?.didEnd()
        self.currentAnnotation = annotation
        self.currentAnnotation?.delegate = self
    }
    
    func loadButtons(for annotations: [UXMAnnotation.Type]) {
        self.buttons = self.annotationTypes.flatMap {
            
            if let annotation = $0 as? PDFAnnotationButtonable.Type {
                return PDFAnnotationBarButton(
                    toggled: false,
                    type: annotation,
                    block: { (button) in
                        guard let button = button as? PDFAnnotationBarButton else { return }
                        self.selected(button: button)
                })
            }
            return nil
        }
    }
    
    public func undo() {
        
        if let annotation = annotations.undo() {
            if let annotationPage = annotation.page,
                let pageContentView = self.pageContentViewFor(page: annotationPage) {
                clear(pageView: pageContentView.contentView)
                showAnnotations(pageContentView)
                return
            }
        }
    }
    
    func deleteCurrent() {
        if let currentAnnotation = self.currentAnnotation {
            self.annotations.remove(annotation: currentAnnotation)
        }
    }
    
    func clear(pageView: UXMPageContent) {
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
    
    private func view(uuid: String) -> UIView? {
        guard let pageView = self.pageView else { return nil }
        for subview in pageView.subviews {
            if let annotView = subview as? PDFAnnotationView,
                let parent = annotView.parent,
                parent.uuid == uuid {
                return subview
            }
        }
        return nil
    }
    
    private func createNewAnnotation() {
        if let annotationType = self.annotationType {
            currentAnnotation = annotationType.init()
        }
    }
    
    private func addCurrentAnnotationToStore() {
        if let currentAnnotation = currentAnnotation {
            currentAnnotation.didEnd()
            annotations.add(annotation: currentAnnotation)
        }
        currentAnnotation = nil
    }
}

extension UXMAnnotationController: PDFAnnotationEvent {
    public func annotationUpdated(annotation: UXMAnnotation) {  }
    
    public func annotation(annotation: UXMAnnotation, selected action: String) {
        if action == "delete" {
            self.annotations.remove(annotation: annotation)
            
            /// VERY DIRTY FIX LATER
            if let annotationPage = annotation.page,
                let pageContentView = self.pageContentViewFor(page: annotationPage) {
                clear(pageView: pageContentView.contentView)
                showAnnotations(pageContentView)
                return
            }
        }
    }
}

extension UXMAnnotationController: UXMRenderer {
    public func render(_ page: Int, context: CGContext, bounds: CGRect) {
        annotations.renderInContext(context, size: bounds, page: page)
    }
}
