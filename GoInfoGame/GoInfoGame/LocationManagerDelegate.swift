//
//  LocationManagerDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/02/24.
//

import CoreLocation
import Foundation

class LocationManagerDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isLocationDenied: Bool = false
    @Published var isLocationServicesOff: Bool = false
    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkInitialLocationStatus()
    }
    
    func requestLocationAuthorization() {
        DispatchQueue.main.async {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        // Perform location services check on a background thread
        DispatchQueue.global(qos: .background).async {
            let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                if !locationServicesEnabled {
                    self.isLocationServicesOff = true
                    return
                }
                
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.distanceFilter = 150
                self.locationManager.startUpdatingLocation()
                self.isLocationServicesOff = false
            }
        }
    }

    
    func stopUpdatingLocation() {
        DispatchQueue.main.async {
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Check the authorization status and location services in background
        DispatchQueue.global(qos: .background).async {
            let isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
            let authorizationStatus = manager.authorizationStatus
            
            DispatchQueue.main.async {
                switch authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    self.isLocationDenied = false
                    self.isLocationServicesOff = !isLocationServicesEnabled
                    self.startUpdatingLocation()
                case .denied, .restricted:
                    self.isLocationDenied = true
                    self.isLocationServicesOff = false
                    self.stopUpdatingLocation()
                default:
                    self.isLocationDenied = false
                    self.isLocationServicesOff = !isLocationServicesEnabled
                    self.requestLocationAuthorization()
                }
            }
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.location = mostRecentLocation
            self.locationUpdateHandler?(mostRecentLocation.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error with location manager is ----\(error.localizedDescription)")
    }
    
    private func checkInitialLocationStatus() {
        // Perform initial status check asynchronously
        DispatchQueue.global(qos: .background).async {
            let servicesEnabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                self.isLocationServicesOff = !servicesEnabled
            }
        }
    }
}
