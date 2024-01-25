//
//  LocationManagerCoordinator.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 23/01/24.
//

import Foundation
import CoreLocation

class LocationManagerCoordinator: NSObject, CLLocationManagerDelegate {
    var parent: MapView?
    init(parent: MapView) {
        self.parent = parent
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        print("Location received")
        parent?.centerMapOnLocation(location: location)
        // Try to load the quests
       
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error requesting location: \(error.localizedDescription)")
       
    }
}
