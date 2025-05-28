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
}
