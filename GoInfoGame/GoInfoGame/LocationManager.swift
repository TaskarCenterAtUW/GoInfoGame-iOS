//
//  LocationManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/11/23.
//

import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    
    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?
    
    private var isOverpassRequestInProgress = false


    private var minLatitude: Double = 0.0
    private var maxLatitude: Double = 0.0
    private var minLongitude: Double = 0.0
    private var maxLongitude: Double = 0.0

    private var completionHandler: (([String: Double]) -> Void)?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    private func configureLocationServices() {
        locationManager.delegate = self
        let status = CLLocationManager()
        switch status.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            beginLocationUpdates(locationManager: locationManager)
        default: break
        }
    }

    private func beginLocationUpdates(locationManager: CLLocationManager) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    
    private func updateMinMaxValues(location: CLLocation) {
        let currentLatitude = location.coordinate.latitude
        let currentLongitude = location.coordinate.longitude

        let regionSpan = 0.1
        minLatitude = currentLatitude - regionSpan
        maxLatitude = currentLatitude + regionSpan
        minLongitude = currentLongitude - regionSpan
        maxLongitude = currentLongitude + regionSpan
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
          guard let currentLocation = locations.last else { return }

          updateMinMaxValues(location: currentLocation)

          if currentCoordinate == nil {
              locationUpdateHandler?(currentLocation.coordinate)
          }

          currentCoordinate = currentLocation.coordinate

          if !isOverpassRequestInProgress {
              isOverpassRequestInProgress = true
              self.locationManager.stopUpdatingLocation()

              let result = ["minLatitude": minLatitude,
                            "maxLatitude": maxLatitude,
                            "minLongitude": minLongitude,
                            "maxLongitude": maxLongitude]

              completionHandler?(result)
          }
      }

    func getCurrentLocation(completion: @escaping ([String: Double]) -> Void) {
        self.completionHandler = completion
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
    
    func setOverpassRequestInProgress(_ inProgress: Bool) {
            isOverpassRequestInProgress = inProgress
        }
}
