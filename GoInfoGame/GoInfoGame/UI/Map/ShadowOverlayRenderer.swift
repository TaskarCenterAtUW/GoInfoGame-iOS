//
//  ShadowOverlayRenderer.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 19/04/25.
//

import MapKit
import UIKit


class ShadowOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let shadowOverlay = overlay as? ShadowOverlay else { return }

        let fullRect = self.rect(for: shadowOverlay.boundingMapRect)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        context.fill(fullRect)

        context.setBlendMode(.clear)
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)

        for mapRect in shadowOverlay.annotationRects {
            let cutout = self.rect(for: mapRect).integral
            context.fill(cutout)
        }

        context.setBlendMode(.normal)
    }
}

class ShadowOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    let boundingMapRect: MKMapRect = MKMapRect.world
    let annotationRects: [MKMapRect]

    init(annotations: [MKAnnotation]) {
        self.annotationRects = annotations.map { annotation in
            let center = MKMapPoint(annotation.coordinate)
            let width = MKMapPointsPerMeterAtLatitude(annotation.coordinate.latitude) * 500 // 500m box
            return MKMapRect(
                origin: MKMapPoint(x: center.x - width / 2, y: center.y - width / 2),
                size: MKMapSize(width: width, height: width)
            )
        }
    }
}



extension MKCoordinateRegion {
    func corners() -> [CLLocationCoordinate2D] {
        let latMin = center.latitude - span.latitudeDelta / 2
        let latMax = center.latitude + span.latitudeDelta / 2
        let lonMin = center.longitude - span.longitudeDelta / 2
        let lonMax = center.longitude + span.longitudeDelta / 2
        return [
            CLLocationCoordinate2D(latitude: latMin, longitude: lonMin),
            CLLocationCoordinate2D(latitude: latMin, longitude: lonMax),
            CLLocationCoordinate2D(latitude: latMax, longitude: lonMax),
            CLLocationCoordinate2D(latitude: latMax, longitude: lonMin)
        ]
    }
}

