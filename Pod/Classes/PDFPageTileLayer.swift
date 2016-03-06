//
//  PDFPageTileLayer.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

class PDFPageTileLayer: CATiledLayer {

    
    override init() {
        
        super.init()
        
        self.levelsOfDetail = 10
        self.levelsOfDetailBias = self.levelsOfDetail - 1
        
        let mainScreen = UIScreen.mainScreen()
        let screenScale = mainScreen.scale
        let screenBounds = mainScreen.bounds
        
        let width = screenBounds.size.width * screenScale
        let height = screenBounds.size.height * screenScale
        
        let max = width < height ? height : width
        let sizeOfTiles:CGFloat = max < 512.0 ? 512.0 : 1024.0
        
        self.tileSize = CGSizeMake(sizeOfTiles, sizeOfTiles)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
