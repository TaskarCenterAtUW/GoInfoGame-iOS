//
//  ContextualInfo.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 09/06/25.
//

import CoreLocation
import MapKit

final class LocationHelper {
    private let locationManagerDelegate: LocationManagerDelegate

    init(locationManagerDelegate: LocationManagerDelegate) {
        self.locationManagerDelegate = locationManagerDelegate
    }

    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let userLocation = locationManagerDelegate.locationManager.location?.coordinate else { return 0 }
        let from = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }

    func inferDirection(to coordinate: CLLocationCoordinate2D) -> String {
        guard let userLocation = locationManagerDelegate.locationManager.location?.coordinate else { return "undetermined" }
        let from = MKMapPoint(userLocation)
        let to = MKMapPoint(coordinate)
        var angle = atan2(to.y - from.y, to.x - from.x) * 180 / .pi + 90
        angle = angle < 0 ? angle + 360 : angle.truncatingRemainder(dividingBy: 360)

        switch angle {
        case 337.5..<360, 0..<22.5: return "ahead"
        case 22.5..<112.5: return "right"
        case 112.5..<202.5: return "behind"
        case 202.5..<292.5: return "left"
        default: return "right"
        }
    }

    func inferStreetName(from location: CLLocation, completion: @escaping (String?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let address = [
                placemarks?.first?.subThoroughfare,
                placemarks?.first?.thoroughfare
            ].compactMap { $0 }.joined(separator: ", ")
            completion(address.isEmpty ? nil : address)
        }
    }
}
