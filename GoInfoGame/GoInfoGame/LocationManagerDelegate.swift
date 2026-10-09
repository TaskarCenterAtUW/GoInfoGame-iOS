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
    
    func startUpdatingLocation(distanceFilter: CLLocationDistance = 150) {
        #if DEBUG
        // Real CLLocationManager simulation on a simulator depends on `xcrun simctl
        // location set` having been applied to that specific device - confirmed directly
        // to be unreliable: it was set once, worked, and then silently stopped taking
        // effect partway through a later, unrelated test run with no clear trigger
        // (startUpdatingLocation kept firing but didUpdateLocations never did again).
        // Anything that only proceeds after a first location fix - e.g. InitialViewModel
        // .fetchWorkspacesList(), gated on locationUpdateHandler - is then stuck forever.
        // Delivering one fixed coordinate directly removes the dependency on that
        // simulator state entirely, for every consumer of this class (InitialViewModel,
        // MapViewModel, KartaviewViewModel, AccessibilityModeViewModel, CustomMap).
        // Async, matching CLLocationManager's own asynchronous delivery, so callers that
        // set locationUpdateHandler immediately before calling this (the normal pattern)
        // are not depending on synchronous delivery order.
        //
        // Uniform for now - it does not distinguish scenarios, so there is currently no
        // way to test "location permission denied" behavior under UI tests. Revisit if
        // that ever needs coverage (e.g. gate this on a dedicated UITestScenario check
        // instead of UITestRuntime.isActive alone).
        if UITestRuntime.isActive {
            DispatchQueue.main.async { [weak self] in
                // Kondapur, Hyderabad (17.4385, 78.3610) - not an arbitrary choice: it is
                // the real-world area MapOSMElements.json's captured OSM data covers
                // (bounds ~17.43-17.45N, 78.35-78.37E, matching workspace 222's actual
                // name, "Copy from Stage Kondapur Dataset"). MapViewModel centers the
                // map's camera on whatever coordinate this delivers and there is no
                // auto-fit-to-loaded-data logic anywhere in CustomMap/MapView - the
                // camera stays exactly where location puts it regardless of where the
                // fetched elements actually are. A location outside this fixture's
                // geographic bounds would leave every element off-screen even though the
                // (path-matched, bbox-agnostic) stub still returns all of them. Other
                // scenarios that touch location (Workspaces/Login/Profile) do not depend
                // on the specific coordinate, only that a fix arrives at all, so this is
                // safe to share across all of them.
                let fixedLocation = CLLocation(latitude: 17.4385, longitude: 78.3610)
                self?.location = fixedLocation
                self?.locationUpdateHandler?(fixedLocation.coordinate)
            }
            return
        }
        #endif

        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.distanceFilter = distanceFilter
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
