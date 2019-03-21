//
//  UXMActionURL.swift
//  Pods
//
//  Created by Chris Anderson on 11/15/16.
//
//

import Foundation

open class UXMActionURL: UXMAction {
    var url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public init?(stringUrl: String) {
        guard let url = URL(string: stringUrl) else { return nil }
        self.url = url
    }
}
