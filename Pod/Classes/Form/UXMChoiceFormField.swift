//
//  UXMChoiceFormField.swift
//  UXMPDFKit
//
//  Created by Brian Mwakima on 24/05/2019.
//

import UIKit

class FormDropdownIndicator: UIView {

  override open func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    context.saveGState()

    let margin: CGFloat = rect.size.width/3
    context.setFillColor(UIColor.black.cgColor)
    context.move(to: CGPoint(x: margin, y: margin))
    context.addLine(to: CGPoint(x: rect.size.width-margin, y: rect.size.height/2))
    context.addLine(to: CGPoint(x: margin, y: rect.size.height-margin))
    context.addLine(to: CGPoint(x: margin, y: margin))
    context.fillPath()
  }
}

open class UXMChoiceFormField: UXMFormField {

  var _dropDownIndicator: FormDropdownIndicator = FormDropdownIndicator(frame: CGRect.zero)
  var _tableView: UITableView = UITableView(frame: CGRect.zero)
  var _options: Array<String> = []
  var _selectedIndex: Int = NSNotFound
  var _selection: UILabel = UILabel(frame: CGRect.zero)
  var _dropped: Bool = false
  var _baseFontHeight: CGFloat = 12

  init(frame: CGRect, options: Array<String>) {
    super.init(frame: frame)
    self._options = options
//    let rect = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    backgroundColor = UIColor.pdfBackgroundBlue().withAlphaComponent(0.7)
    self.layer.cornerRadius = self.frame.size.height/6;

    self._tableView = UITableView.init(frame: CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height * CGFloat(min(5,_options.count))), style: .plain)
    self._tableView.dataSource = self
    self._tableView.delegate = self
    self._tableView.isOpaque = false
    self._tableView.backgroundColor = UIColor.clear
    self._tableView.backgroundView = nil
    self._tableView.alpha = 0
    self._tableView.layer.cornerRadius = 4
    self._tableView.separatorStyle = .none
    self._tableView.separatorColor = .clear
    self.clipsToBounds = true
    self._baseFontHeight = 10.0
    self._selection = UILabel.init(frame: CGRect(x: 1, y: 0, width: (frame.size.width - frame.size.height), height: frame.size.height))
    self._selection.isOpaque = false
    self._selection.adjustsFontSizeToFitWidth = true
    self._selection.backgroundColor = .clear
    self._selection.textColor = .black

    self.addSubview(_selection)

    self._dropDownIndicator = FormDropdownIndicator.init(frame: CGRect(x: (frame.size.width-frame.size.height*1.5), y: (-frame.size.height*0.25), width: (frame.size.height*1.5), height: frame.size.height*1.5))

    self._dropDownIndicator.isOpaque = false
    self._dropDownIndicator.backgroundColor = .clear

    self.addSubview(_dropDownIndicator)

    let _middleButton: UIButton = UIButton.init(frame: self.bounds)
    _middleButton.isOpaque = false
    _middleButton.backgroundColor = .clear
    _middleButton.addTarget(self, action: #selector(dropdownPressed), for: UIControl.Event.touchUpInside)

    self.addSubview(_middleButton)

    self.addSubview(_tableView)
  }

  func setupUI(_ opts: Array<String>) {

  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setValue(value: String) {
    if value is NSNull {
      self.value = nil
      return
    }

    if(value != nil) {
      let ind: Int = self._options.index(of: value)!
      self._selectedIndex = ind
    } else {
      self._selectedIndex = NSNotFound
    }

    self._selection.text = value
  }

  override func didSetValue(_ value: AnyObject?) {

    if(value != nil) {
      let ind: Int = self._options.index(of: value as! String)!
      self._selectedIndex = ind
    } else {
      self._selectedIndex = NSNotFound
    }

    if let value = value as? String {
      self._selection.text = value
    }
  }

  func setOptions(opts: Array<String>) {
    if opts is NSNull {
      self.options = []
      return
    }

    if(_options != opts) {
      _options = opts
    }

    let sf: CGFloat = _selection.frame.size.height
    _tableView.frame = CGRect(x: 0, y: sf, width: self.frame.size.width, height: sf * CGFloat(min(5,_options.count)))
  }

  override open func refresh() {
    super.refresh()
    let sf: CGFloat = _selection.frame.size.height
    _tableView.frame = CGRect(x: 0, y: sf, width: self.frame.size.width, height: sf * CGFloat(min(5,_options.count)))
    _tableView.reloadData()
    _tableView.selectRow(at: IndexPath(row: self._selectedIndex, section: 0), animated: false, scrollPosition: .none)

  }

  override func resign() {
    if(self._dropped) {
      self.dropdownPressed(sender: self._dropDownIndicator)
    }
  }

  override func renderInContext(_ context: CGContext) {
      let text: String = _selection.text ?? ""
      let font: UIFont = _selection.font!

    let attributes: [NSAttributedString.Key:AnyObject] = [
      NSAttributedString.Key.font: font,
      NSAttributedString.Key.foregroundColor: UIColor.black
    ]
    text.draw(in: frame, withAttributes:attributes)
  }

  @objc func dropdownPressed(sender: Any) {
    self.superview?.bringSubviewToFront(self)
    if(!self._dropped) {
      self.delegate?.formFieldEntered(self)
    }
    self._dropped = !self._dropped
    self._dropDownIndicator.setNeedsDisplay()

    if(self._dropped) {
      self.parent?.activeWidgetAnnotationView = self
      self._tableView.reloadData()
      if(self._selectedIndex < self._options.count) {
        _tableView.selectRow(at: IndexPath(row: self._selectedIndex, section: 0), animated: false, scrollPosition: .none)
        _tableView.scrollToNearestSelectedRow(at: .middle, animated: false)

      }

      UIView.animate(withDuration: 0.3) {
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height*(CGFloat(min(5,self._options.count))+1))
        self._tableView.alpha = 1
        self._dropDownIndicator.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi/2)
      }
    } else {
      self.parent?.activeWidgetAnnotationView = nil
      UIView.animate(withDuration: 0.3) {
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height/(CGFloat(min(5,self._options.count))+1))
        self._tableView.alpha = 0
        self._dropDownIndicator.transform = CGAffineTransform.init(rotationAngle: 0)
      }
    }

    self.setNeedsDisplay()
  }

}

extension UXMChoiceFormField: UITableViewDelegate {

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return tableView.bounds.size.height / CGFloat(min(5,_options.count))
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.setValue(value: _options[indexPath.row])
    delegate?.formFieldValueChanged(self)
  }
}

extension UXMChoiceFormField: UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return _options.count
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
    cell.isOpaque = false
    cell.indentationWidth = 0
    cell.backgroundColor = .clear
    cell.textLabel?.backgroundColor = .clear
    cell.textLabel?.isOpaque = false
    cell.detailTextLabel?.backgroundColor = .clear
    cell.detailTextLabel?.isOpaque = false
//    cell.textLabel?.font = UIFont(descriptor: ., size: <#T##CGFloat#>)
    cell.textLabel?.adjustsFontSizeToFitWidth = true
    cell.textLabel?.text = _options[indexPath.row]
    cell.textLabel?.textColor = .black

    return cell
  }


}
