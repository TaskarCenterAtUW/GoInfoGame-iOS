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

    init(coordinate: CLLocationCoordinate2D, count: Int) {
        self.coordinate = coordinate
        self.count = count
    }

    var title: String? {
        return "\(count)"
    }
}
