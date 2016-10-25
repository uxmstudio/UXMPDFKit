![UXM Token Field](https://uxmstudio.com/public/images/uxmpdfkit.png)

[![Version](https://img.shields.io/cocoapods/v/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)
![Swift](https://img.shields.io/badge/%20in-swift%203.0-orange.svg)
[![License](https://img.shields.io/cocoapods/l/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)
[![Platform](https://img.shields.io/cocoapods/p/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)

## Requirements
- iOS 9 or above
- Xcode 8 or above
- Swift 3.0

## Note

This project is still in early stages. Right now the PDF reader works both programmatically and through interface builder. This PDF reader supports interactive forms and provides methods for overlaying text, signature and checkbox elements onto the page, as well as rendering a PDF with the elements burned back onto the PDF. See the example project for how to implement.

## Installation

UXMPDFKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "UXMPDFKit"
```

If you wish to use the Swift 2.3 version, use the following instead:
```ruby
pod "UXMPDFKit", "~> 0.3.0"
```

## Usage
### Simple Usage
UXMPDFKit comes with a single page PDF reader with many features implemented right out of the box. Simply create a new PDFViewController, pass it a document and display it like any other view controller. It includes support for forms, a page scrubber and page scrolling.
```swift
let url = NSBundle.mainBundle().pathForResource("sample", ofType: "pdf")!
let document = try! PDFDocument(filePath: url, password: "password_if_needed")
let pdf = PDFViewController(document: document)

self.navigationController?.pushViewController(pdf, animated: true)
```


### Single Page Collection View
This collection view renders a PDF in its entirety one page at a time in photo-slideshow style. 
```swift
let collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
collectionView.singlePageDelegate = self
```

Its delegate methods are implemented as follows:

```swift
func singlePageViewer(collectionView: PDFSinglePageViewer, didDisplayPage page:Int)
func singlePageViewer(collectionView: PDFSinglePageViewer, loadedContent content:PDFPageContentView)
func singlePageViewer(collectionView: PDFSinglePageViewer, selectedAction action:PDFAction)
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
protocol PDFAnnotation {

    func mutableView() -> UIView
    func touchStarted(touch: UITouch, point:CGPoint)
    func touchMoved(touch:UITouch, point:CGPoint)
    func touchEnded(touch:UITouch, point:CGPoint)
    func drawInContext(context: CGContextRef)
}
```

An annotation should be an object that contains its position and value, not a view. Because annotations are written onto temporary objects, they should be created, not passed by reference each time ```mutableView()``` is called. 

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

Tapped actions are passed to your view controller by the PDFSinglePageViewer in its ```contentDelegate```

### Renderer 
In order to perform write operations back onto a PDF in an efficient format, a renderer is used. Each type of form, annotation, etc that needs to be rendered back onto the PDF should extend the following protocol:

```swift
protocol PDFRenderer {
    func render(page: Int, context:CGContext, bounds: CGRect)
}
```

Controllers or objects that extend this protocol can then be passed to the PDFRenderer to be written onto a temporary document or saved permanently onto the document.

```swift
let renderer = PDFRenderController(document: self.document, controllers: [
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

