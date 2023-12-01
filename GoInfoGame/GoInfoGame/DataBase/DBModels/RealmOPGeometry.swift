//
//  RealmOPGeometry.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 29/11/23.
//

import Foundation
import RealmSwift
import SwiftOverpassAPI
import Realm

class RealmOPGeometry: Object {
    @objc dynamic var centerLatitude: Double = 0.0
    @objc dynamic var centerLongitude: Double = 0.0
    let polyline = List<RealmCLLocationCoordinate2D>()
    let polygon = List<RealmCLLocationCoordinate2D>()
    let multiPolygon = List<RealmNestedPolygonCoordinates>()
    let multiPolyline = List<RealmNestedPolyCoordinate>()
    @objc dynamic var type: String = ""

    convenience init(geometry: OPGeometry?) {
        self.init()

        guard let geometry = geometry else {
            self.type = Constants.kNone
            return
        }

        switch geometry {
        case .center(let coordinate):
            self.centerLatitude = coordinate.latitude
            self.centerLongitude = coordinate.longitude
            self.type = Constants.kCenter
        case .polyline(let coordinates):
            self.polyline.append(objectsIn: coordinates.map(RealmCLLocationCoordinate2D.init))
            self.type = Constants.kPolyline
        case .polygon(let coordinates):
            self.polygon.append(objectsIn: coordinates.map(RealmCLLocationCoordinate2D.init))
            self.type = Constants.kPolygon
        case .multiPolygon(let nestedCoordinates):
            self.multiPolygon.append(objectsIn: nestedCoordinates.map(RealmNestedPolygonCoordinates.init))
            self.type = Constants.kMultiPolygon
        case .multiPolyline(let nestedCoordinates):
            let realmNestedPolyline = RealmNestedPolyCoordinate()
            realmNestedPolyline.coordinates.append(objectsIn: nestedCoordinates.map(RealmCLLocationCoordinate2D.init))
                       self.multiPolyline.append(realmNestedPolyline)
            self.type = Constants.kMultiPolyline
        case .none:
            self.type = Constants.kNone
        }
    }
}

class RealmNestedPolyCoordinate: Object {
    let coordinates = List<RealmCLLocationCoordinate2D>()
}

class RealmNestedPolygonCoordinates: Object {
    let outerRing = List<RealmCLLocationCoordinate2D>()
    let innerRings = List<RealmNestedPolyCoordinate>()
}
