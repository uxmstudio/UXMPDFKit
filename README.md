![UXM Token Field](https://uxmstudio.com/public/images/uxmpdfkit.png)

[![Version](https://img.shields.io/cocoapods/v/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)
[![License](https://img.shields.io/cocoapods/l/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)
[![Platform](https://img.shields.io/cocoapods/p/UXMPDFKit.svg?style=flat)](http://cocoapods.org/pods/UXMPDFKit)

## Requirements
- iOS 8 or above
- Xcode 7 or above
- Swift 2.1

## Note

This project is still in early stages. Right now the PDF reader works both programmatically and through interface builder. This PDF reader supports interactive forms on and provides methods for overlaying form elements as well as rendering a PDF with the elements burned back onto the PDF. See the example project for how to implement.

## Installation

UXMPDFKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "UXMPDFKit"
```
## Usage
```Swift
let url = NSBundle.mainBundle().pathForResource("sample", ofType: "pdf")!
let document = PDFDocument(filePath: url, password: "password_if_needed")
let pdf = PDFViewController(document: document)

self.navigationController?.pushViewController(pdf, animated: true)
```

# Author
Chris Anderson:
- chris@uxmstudio.com
- [Home Page](http://uxmstudio.com)

# License

UXMPDFKit is available under the MIT license. See the LICENSE file for more info.
