![UXM Token Field](https://avatars3.githubusercontent.com/u/13734873?s=400&v=4)

[![CI Status](http://img.shields.io/travis/uxmstudio/UXMPDFKit.svg?style=flat)](https://travis-ci.org/diegostamigni/UXMPDFKit)
[![Version](https://img.shields.io/cocoapods/v/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)
![Swift](https://img.shields.io/badge/%20in-swift%203.0-orange.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)
[![Platform](https://img.shields.io/cocoapods/p/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)

## Requirements
- iOS 9 or above
- Xcode 9 or above
- Swift 4.0

## Note

This project is still in early stages. Right now the PDF reader works both programmatically and through interface builder. This PDF reader supports interactive forms and provides methods for overlaying text, signature and checkbox elements onto the page, as well as rendering a PDF with the elements burned back onto the PDF. See the example project for how to implement.

## Installation

### CocoaPods

UXMPDFKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "UXMPDFKit"
```

If you wish to use the Swift 2.3 version, use the following instead:
```ruby
pod "UXMPDFKit", "~> 0.3.0"
```

### Carthage

UXMPDFKit is also available through [Carthage](https://github.com/Carthage/Carthage).
To install just write into your Cartfile:

```ogdl
github "uxmstudio/UXMPDFKit"
```

Run `carthage update` to build the framework and drag the built `UXMPDFKit.framework` into your Xcode project.

## Usage
### Simple Usage
UXMPDFKit comes with a single page PDF reader with many features implemented right out of the box. Simply create a new PDFViewController, pass it a document and display it like any other view controller. It includes support for forms, a page scrubber and page scrolling.
#### Swift
```swift
let path = Bundle.main.path(forResource: "sample", ofType: "pdf")!
let document = try! PDFDocument(filePath: path, password: "password_if_needed")
let pdf = PDFViewController(document: document)

self.navigationController?.pushViewController(pdf, animated: true)
```

#### Objective-C
Although written in Swift, the core reader can be used in Objective-C.
```objective-c
NSError *error;
NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"pdf"];
PDFDocument *document = [[PDFDocument alloc] initWithFilePath:path password:@"password_if_needed" error:&error];
PDFViewController *pdfVC = [[PDFViewController alloc] initWithDocument:document];

[self.navigationController pushViewController:pdfVC animated:true];
```

### Single Page Collection View
This collection view renders a PDF in its entirety one page at a time in photo-slideshow style. 
```swift
let collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
collectionView.singlePageDelegate = self
```

Its delegate methods are implemented as follows:

```swift
func singlePageViewer(collectionView: PDFSinglePageViewer, didDisplayPage page: Int)
func singlePageViewer(collectionView: PDFSinglePageViewer, loadedContent content: PDFPageContentView)
func singlePageViewer(collectionView: PDFSinglePageViewer, selectedAction action: PDFAction)
```


### Forms
User-interactable forms are supported by UXMPDFKit, but only partially. Currently only PDF's versions 1.6 & 1.7 render correctly.

Form features implemented:
- [x] Signatures
- [x] Text Fields
- [x] Checkboxes
- [ ] Radio Buttons
- [ ] Choice Boxes

Form parsing and handling is taken care of by the PDFFormViewController. It takes a document, and then is passed a PDFPageContentView to render form elements onto.
```swift
let formController = PDFFormViewController(document: self.document)
formController.showForm(contentView)
```

PDF rewriting is not currently supported, but flattening inputed data onto the PDF is. To render the form information onto the document, call:
```swift
func renderFormOntoPDF() -> NSURL // Returns a temporary url
func save(url: NSURL) -> Bool // Writes 
```


### Annotations
User annotations are supported at a basic level, however instead of being written onto the PDF, are burned on at the time of saving. 

Current annotation types available: 
* Pen
* Highlighter
* Textbox

All annotations are stored in memory until being rendered back onto the PDF by the PDFRenderer.

To create a new annotation type, you must extend the following protocol:

```swift
public protocol PDFAnnotation {

    /// The page number the annotation is located on
    var page: Int? { get set }

    /// Unique identifier to be able to select annotation by
    var uuid: String { get }

    /// Boolean representing if the annotation has been saved
    var saved: Bool { get set }

    var delegate: PDFAnnotationEvent? { get set }

    /// Force implementations to have an init
    init()

    /// A function to return a view composed of the annotations properties
    func mutableView() -> UIView

    /// Set of handlers to pass touches to annotation
    func touchStarted(_ touch: UITouch, point: CGPoint)
    func touchMoved(_ touch: UITouch, point: CGPoint)
    func touchEnded(_ touch: UITouch, point: CGPoint)

    /// Method to save annotation locally
    func save()
    func drawInContext(_ context: CGContext)

    func didEnd()

    func encode(with aCoder: NSCoder)
}
```

An annotation should be an object that contains its position and value, not a view. Because annotations are written onto temporary objects, they should be created, not passed by reference each time ```mutableView()``` is called. 

Additionally, it is recommended that the view passed by ```mutableView()``` extend ```ResizableView``` as this allows the annotation to be moved, resized and deleted individually.

In order for annotations to be able to be listed inside of the toolbar, they must also extend ```UXMPDFAnnotationButtonable```.

```swift
public protocol UXMPDFAnnotationButtonable: UXMPDFAnnotation {

    /// Name for UIBarButtonItem representation of annotation
    static var name: String? { get }

    /// Image for UIBarButtonItem representation of annotation 
    static var buttonImage: UIImage? { get }
}
```

### Actions

Partial action support was added in version 0.3.0 and will be increased upon in future versions.

Currently supported actions:
- [x] External URL
- [x] Go To (internal jump to page index)
- [ ] Remote Go To
- [ ] Named
- [ ] Launch
- [ ] Javascript
- [ ] Rich Media

Tapped actions are passed to your view controller by the UXMPDFSinglePageViewer in its ```contentDelegate```

### Renderer 
In order to perform write operations back onto a PDF in an efficient format, a renderer is used. Each type of form, annotation, etc that needs to be rendered back onto the PDF should extend the following protocol:

```swift
protocol UXMRenderer {
    func render(page: Int, context:CGContext, bounds: CGRect)
}
```

Controllers or objects that extend this protocol can then be passed to the PDFRenderer to be written onto a temporary document or saved permanently onto the document.

```swift
let renderer = UXMPDFRenderController(document: self.document, controllers: [
    self.annotationController,
    self.formController
])
let pdf = renderer.renderOntoPDF()
```


# Author
Chris Anderson:
- chris@uxmstudio.com
- [Home Page](http://uxmstudio.com)

# License

UXMPDFKit is available under the MIT license. See the LICENSE file for more info.

