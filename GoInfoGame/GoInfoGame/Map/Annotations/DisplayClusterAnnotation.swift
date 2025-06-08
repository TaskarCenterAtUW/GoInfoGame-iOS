//
//  DisplayClusterAnnotation.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import MapKit
import Foundation
import CoreLocation

final class DisplayClusterAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let memberAnnotations: [DisplayUnitAnnotation]

    init(coordinate: CLLocationCoordinate2D, members: [DisplayUnitAnnotation]) {
        self.coordinate = coordinate
        self.count = members.count
        self.memberAnnotations = members
    }

    var title: String? { nil }
}
