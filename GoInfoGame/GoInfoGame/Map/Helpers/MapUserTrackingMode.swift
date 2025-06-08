//
//  MapUserTrackingMode.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import MapKit
import SwiftUI

// Extension to convert MapUserTrackingMode to MKUserTrackingMode
extension MapUserTrackingMode {
    var mkUserTrackingMode: MKUserTrackingMode {
        switch self {
        case .none:
            return .none
        case .follow:
            return .follow
        case .followWithHeading:
            return .followWithHeading
        @unknown default:
            fatalError()
        }
    }
}
