//
//  Extension.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 27/11/23.
//

import Foundation
import MapKit

// Extension to check if a polyline intersects with a coordinate
extension MKPolyline {
    func intersects(with coordinate: CLLocationCoordinate2D, mapView: MKMapView) -> Bool {
        let polylineRenderer = MKPolylineRenderer(polyline: self)
        let tapPoint = mapView.convert(coordinate, toPointTo: mapView)
        let newCoordinate = mapView.convert(tapPoint, toCoordinateFrom:mapView)
        let polylinePoint = polylineRenderer.point(for: MKMapPoint(newCoordinate))
        let polylineBounds = polylineRenderer.path.boundingBox
        return polylineBounds.contains(polylinePoint)
    }
}
