//
//  Extension.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 27/11/23.
//

import Foundation
import MapKit
import RealmSwift


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

extension CLLocationCoordinate2D: CustomPersistable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
    }
    
    public typealias PersistedType = Location
    public init(persistedValue: PersistedType) {
        self.init(latitude: persistedValue.latitude, longitude: persistedValue.longitude)
    }
    public var persistableValue: PersistedType {
        Location(value: [self.latitude,self.longitude])
    }
}

public class Location: EmbeddedObject {
    @Persisted var latitude: Double
    @Persisted var longitude: Double
}
extension CLLocation {
    // Calculate bounding box points given a distance in meters
    func boundingCoordinates(distance: CLLocationDistance) -> (left: CLLocation, bottom: CLLocation, right: CLLocation, top: CLLocation) {
        // Earth radius in meters
        let earthRadius = 6_371_000.0
        
        // Convert distance to radians
        let latRadians = distance / earthRadius
        let lonRadians = distance / (earthRadius * cos(Double.pi * self.coordinate.latitude / 180.0))
        let latDegrees = latRadians * 180.0 / Double.pi
        let lonDegrees = lonRadians * 180.0 / Double.pi
        
        // Calculate bounding box coordinates
        let left = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude - lonDegrees)
        let bottom = CLLocation(latitude: self.coordinate.latitude - latDegrees, longitude: self.coordinate.longitude)
        let right = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude + lonDegrees)
        let top = CLLocation(latitude: self.coordinate.latitude + latDegrees, longitude: self.coordinate.longitude)
        
        return (left, bottom, right, top)
    }
}
// Extension of Array with a method to remove an element
extension Array where Element: Equatable {
    // Check if the element exists in the array
    mutating func removeObject(element: Element) {
        if let index = firstIndex(of: element) {
            // If the element is found, remove it from the array
            remove(at: index)
        }
        
    }
}
