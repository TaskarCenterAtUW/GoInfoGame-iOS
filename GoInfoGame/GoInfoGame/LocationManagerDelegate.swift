//
//  LocationManagerDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/02/24.
//

import CoreLocation
import Foundation

final class LocationManagerDelegate: NSObject, ObservableObject, CLLocationManagerDelegate, LocationTrackerProtocol {

    var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isLocationDenied: Bool = false
    @Published var isLocationServicesOff: Bool = false

    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?
    
    var headingUpdateHandler: ((Double) -> Void)?

    var coordinate: CLLocationCoordinate2D? {
        location?.coordinate
    }

    override init() {
        super.init()
        locationManager.delegate = self
        checkInitialLocationStatus()
    }

    func startTracking() {
        DispatchQueue.global(qos: .background).async {
            let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                if !locationServicesEnabled {
                    self.isLocationServicesOff = true
                    return
                }

                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.distanceFilter = 150
                self.locationManager.startUpdatingLocation()
                self.isLocationServicesOff = false
            }
        }
    }

    func stopTracking() {
        DispatchQueue.main.async {
            self.locationManager.stopUpdatingLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.global(qos: .background).async {
            let isEnabled = CLLocationManager.locationServicesEnabled()
            let authStatus = manager.authorizationStatus

            DispatchQueue.main.async {
                switch authStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    self.isLocationDenied = false
                    self.isLocationServicesOff = !isEnabled
                    self.startTracking()
                case .denied, .restricted:
                    self.isLocationDenied = true
                    self.isLocationServicesOff = false
                    self.stopTracking()
                default:
                    self.isLocationDenied = false
                    self.isLocationServicesOff = !isEnabled
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.location = latest
            self.locationUpdateHandler?(latest.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.headingUpdateHandler?(newHeading.trueHeading)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }

    private func checkInitialLocationStatus() {
        DispatchQueue.global(qos: .background).async {
            let enabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                self.isLocationServicesOff = !enabled
            }
        }
    }
}

