//
//  WMTSServer.swift
//  GoInfoGame
//
//  WMTS tile URL template is now consumed directly by MLNRasterTileSource in CustomMap.swift.
//  This file retains only the Extent geometry utility used elsewhere.
//

import Foundation
import CoreLocation

extension Extent {
    private func createPolygon(from extent: Extent) -> [CLLocationCoordinate2D] {
        let flatPoints = extent.polygon.first ?? []
        return flatPoints.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
    }

    func isPointInsideBoundary(_ point: CLLocationCoordinate2D) -> Bool {
        let polygon = createPolygon(from: self)
        guard polygon.count > 2 else { return false }
        var inside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = polygon[i].longitude, yi = polygon[i].latitude
            let xj = polygon[j].longitude, yj = polygon[j].latitude
            let intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
                (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi + 0.0000001) + xi)
            if intersect { inside.toggle() }
            j = i
        }
        return inside
    }
}
