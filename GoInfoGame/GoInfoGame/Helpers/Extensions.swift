//
//  Extension.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 27/11/23.
//

import Foundation
import MapKit
import RealmSwift
import ARKit


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

extension SCNVector3: Equatable {
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func distance(from vector: SCNVector3) -> Float {
        let distanceX = self.x - vector.x
        let distanceY = self.y - vector.y
        let distanceZ = self.z - vector.z
        
        return sqrtf( (distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ))
    }
    
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
}

extension ARSCNView {
    func realWorldVector(screenPos: CGPoint) -> SCNVector3? {
        let planeTestResults = self.hitTest(screenPos, types: [.featurePoint])
        if let result = planeTestResults.first {
            return SCNVector3.positionFromTransform(result.worldTransform)
        }
        
        return nil
    }
}

extension SCNGeometry {
    class func line(from points: [SCNVector3]) -> SCNGeometry {
        let sources = SCNGeometrySource(vertices: points)
        var indices: [Int32] = []
        for i in 0..<points.count {
            indices.append(Int32(i))
        }
        let data = Data(bytes: indices, count: MemoryLayout<Int32>.size * indices.count)
        let element = SCNGeometryElement(data: data, primitiveType: .line, primitiveCount: points.count - 1, bytesPerIndex: MemoryLayout<Int32>.size)
        return SCNGeometry(sources: [sources], elements: [element])
    }
}
