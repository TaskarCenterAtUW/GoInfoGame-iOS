//
//  WMTSServer.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/06/25.
//

import MapKit

class WMTSSeever: MKTileOverlay {
    let satelliteServer: SatelliteServer
    
    init(satelliteServer: SatelliteServer) {
        self.satelliteServer = satelliteServer
        super.init(urlTemplate: nil)
        self.maximumZ = satelliteServer.extent.maxZoom
        self.minimumZ = 1
        self.tileSize = CGSize(width: 256, height: 256)
        self.canReplaceMapContent = true
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let urlString = satelliteServer.url
                    .replacingOccurrences(of: "{z}", with: "\(path.z)")
                    .replacingOccurrences(of: "{x}", with: "\(path.x)")
                    .replacingOccurrences(of: "{y}", with: "\(path.y)")
                return URL(string: urlString)!
    }
}

extension Extent {
    private func createPolygon(from extent: Extent) -> [CLLocationCoordinate2D] {
        let flatPoints = extent.polygon.first ?? []
        let coordinates = flatPoints.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        return coordinates
    }
    
    func isCoordinate(_ point: CLLocationCoordinate2D) -> Bool {
        let polygon = createPolygon(from: self)
        guard polygon.count > 2 else { return false }
        var inside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            let intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
                (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi + 0.0000001) + xi)

            if intersect {
                inside.toggle()
            }

            j = i
        }

        return inside
    }
}

