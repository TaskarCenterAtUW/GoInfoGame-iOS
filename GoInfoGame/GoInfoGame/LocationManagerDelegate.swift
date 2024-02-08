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
    
    override init() {
        super.init()
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
                self.locationManager.startUpdatingLocation()
            }
        }
    }

    
    func stopUpdatingLocation() {
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
        NotificationCenter.default.post(name: Notification.Name("userLocationDidChange"), object: nil)
        stopUpdatingLocation()
    }
}
