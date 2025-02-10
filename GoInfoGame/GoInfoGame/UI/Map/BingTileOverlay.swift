//
//  BingTileOverlay.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 06/02/25.
//

import Foundation
import MapKit

class BingTileOverlay: MKTileOverlay {
    private let apiKey = "AmsZqEUH1H00cfsKzQz44YOJ_hPQT1wkF-Po2TdhXVeTt23E_v5Sl64YMhlZnOsA"
    
     init() {
        super.init(urlTemplate: nil)
        self.tileSize = CGSize(width: 256, height: 256)
        self.canReplaceMapContent = true
         self.maximumZ = 24
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let quadKey = quadKey(forTilePath: path)
        let urlString = "https://ecn.t\(path.x % 4).tiles.virtualearth.net/tiles/a\(quadKey).jpeg?g=1&key=\(apiKey)"
        
        print("BING URL IS =====>>> \(urlString)")
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL string: \(urlString)")
        }
        return url
    }
    
    private func quadKey(forTilePath path: MKTileOverlayPath) -> String {
        var quadKey = ""
        print("Z Level \(path.z)")
        for i in (0..<path.z).reversed() {
            var digit = 0
            let mask = 1 << i
            if (path.x & mask) != 0 { digit += 1 }
            if (path.y & mask) != 0 { digit += 2 }
            quadKey.append("\(digit)")
        }
        return quadKey
    }
}
