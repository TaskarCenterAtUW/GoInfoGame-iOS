//
//  LocationManagerDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/02/24.
//

import CoreLocation
import MapKit

class LocationManagerDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {
        
    var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?
        
    override init() {
        super.init()
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        DispatchQueue.global(qos: .background).async {
            guard CLLocationManager.locationServicesEnabled() else {
                print("Location services are not enabled")
                return
            }
            
            DispatchQueue.main.async {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.distanceFilter = 150
                self.locationManager.startUpdatingLocation()
            }
        }
    }

    
    func stopUpdatingLocation() {
        print("App is pushed to background. So stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            print("Authorized")
            startUpdatingLocation()
        case .denied, .restricted:
            print("Not Authorized")
        default:
            print("Requesting authorization...")
            requestLocationAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else { return }
        location = mostRecentLocation
        locationUpdateHandler?(mostRecentLocation.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error with location manager is ----\(error.localizedDescription)")
    }
}
