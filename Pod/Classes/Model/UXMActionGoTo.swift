//
//  PDFGoToAction.swift
//  Pods
//
//  Created by Chris Anderson on 11/15/16.
//
//

import Foundation

open class UXMActionGoTo: UXMAction {
    var pageIndex: Int
    
    public init(pageIndex: Int) {
        self.pageIndex = pageIndex
    }
}
