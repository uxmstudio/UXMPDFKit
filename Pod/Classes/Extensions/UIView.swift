//
//  UIView.swift
//  UXMPDFKit
//
//  Created by Diego Stamigni on 26/01/2018.
//

import UIKit

extension UIView {
    var hasNotch: Bool {
        get {
            // https://stackoverflow.com/a/46192822
            return UIDevice().userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height >= 2436
        }
    }
}
