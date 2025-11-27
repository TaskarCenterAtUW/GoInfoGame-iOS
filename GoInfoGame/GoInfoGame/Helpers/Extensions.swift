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
import SwiftUI
import Combine


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

extension View {
    func hideKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
        )
    }
}

extension MKMapRect {
    init(_ region: MKCoordinateRegion) {
        let topLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + (region.span.latitudeDelta / 2),
            longitude: region.center.longitude - (region.span.longitudeDelta / 2)
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - (region.span.latitudeDelta / 2),
            longitude: region.center.longitude + (region.span.longitudeDelta / 2)
        )

        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)

        self = MKMapRect(
            origin: MKMapPoint(x: min(a.x, b.x), y: min(a.y, b.y)),
            size: MKMapSize(width: abs(a.x - b.x), height: abs(a.y - b.y))
        )
    }
}

extension MKMapView {
    func isZoomedIn(maxLatitudeDelta: CLLocationDegrees = 0.005) -> Bool {
        return self.region.span.latitudeDelta <= maxLatitudeDelta
    }
    
    func distanceForZoom(zoomLevel: Int) -> CLLocationDistance {
        // Earth's circumference in meters
        let earthCircumference: Double = 40075016.686
        // Standard tile size (pixels)
        let tileSize: Double = 256
        // Get the width of the map in points and scale by screen
        let scale = UIScreen.main.scale
        let mapWidthInPixels = Double(self.frame.size.width) * scale
        // Calculate meters per pixel at equator for the given zoom
        let metersPerPixel = earthCircumference / (tileSize * pow(2.0, Double(zoomLevel)))
        // The distance (in meters) visible in the current map width
        return metersPerPixel * mapWidthInPixels
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

extension UIApplication {
    static func window() -> UIWindow? {
        return UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
    }
    
    var safeAreaBottomInset: CGFloat {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: \.isKeyWindow) else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Double {
    func roundedTo7Digits() -> Double {
        (self * 1_000_0000).rounded() / 1_000_0000
    }
}

extension URLRequest {
    mutating func addAuthorizationHeader() {
        if let jwtAccessToken = KeychainManager.load(key: KeychainManager.Keys.accessToken.rawValue) {
            self.setValue("Bearer \(jwtAccessToken)", forHTTPHeaderField: "Authorization")
        }
    }
}

extension View {
    @ViewBuilder
    func applyPresentationSizingPage() -> some View {
        if #available(iOS 18.0, *) {
            self.presentationSizing(.page)
        } else {
            // No-op for older OS, letting the default sizing apply.
            // You can add a fallback here if needed, e.g., using detents.
            self
        }
    }
}

extension CLLocation {
    /**
     Calculates the initial bearing (in degrees) from this location to a target location.
     */
    func bearing(to location: CLLocation) -> Double {
        // Convert latitudes and longitudes from degrees to radians
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = location.coordinate.latitude.degreesToRadians
        let lon2 = location.coordinate.longitude.degreesToRadians
        
        // Calculate the difference in longitude
        let dLon = lon2 - lon1
        
        // Spherical trigonometry formula for bearing
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        // Calculate the bearing in radians, then convert to degrees
        let bearingRadians = atan2(y, x)
        var bearingDegrees = bearingRadians.radiansToDegrees
        
        // Normalize the bearing to be between 0 and 360 degrees
        if bearingDegrees < 0 {
            bearingDegrees += 360
        }
        
        return bearingDegrees
    }
}

// Helper extension for conversion
extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
