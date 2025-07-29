//
//  LocationManagerDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/02/24.
//

import CoreLocation
import Foundation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private(set) var location: CLLocation?
    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?
    var headingUpdateHandler: ((Double) -> Void)?
    
    var coordinate: CLLocationCoordinate2D? {
        location?.coordinate
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.distanceFilter = 150
        self.locationManager.startUpdatingLocation()
    }
    
    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    
    func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Check the authorization status and location services in background
        let authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            self.startUpdatingLocation()
        case .denied, .restricted:
            self.stopUpdatingLocation()
        default:
            self.requestLocationAuthorization()
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations \(locations.count), \(String(describing: locations.last)), \(String(describing: locationUpdateHandler)) \(Thread.current)")
        guard let mostRecentLocation = locations.last else { return }
        self.location = mostRecentLocation
        self.locationUpdateHandler?(mostRecentLocation.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.headingUpdateHandler?(newHeading.trueHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error with location manager is ----\(error.localizedDescription)")
    }
}
