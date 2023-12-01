//
//  RealOPElement.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 28/11/23.
//

import Foundation
import RealmSwift
import MapKit
import SwiftOverpassAPI

class RealmOPElement: Object {
    @objc dynamic var id: Int = 0
    let tags = List<RealmOPElementTag>()
    var nodes = List<Int>()
    let geometry = List<RealmOPGeometry>()
    @objc dynamic var isInteresting: Bool = false
    @objc dynamic var isSkippable: Bool = false
    var meta: RealmOPMeta?

    override static func primaryKey() -> String? {
        return "id"
    }
}

class RealmOPElementTag: Object {
    @objc dynamic var key: String = ""
    @objc dynamic var value: String = ""
}

class RealmCLLocationCoordinate2D: Object {
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var longitude: Double = 0.0

    convenience init(_ coordinate: CLLocationCoordinate2D) {
        self.init()
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}
