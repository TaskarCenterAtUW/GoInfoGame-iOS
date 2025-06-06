//
//  MockLocationService.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

import CoreLocation
@testable import GoInfoGame

final class MockLocationTracker: LocationTrackerProtocol {
    var location: CLLocation? = nil
    var isLocationDenied = false
    var isLocationServicesOff = false

    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?

    var didStartTracking = false
    var didStopTracking = false

    func startTracking() {
        didStartTracking = true
    }

    func stopTracking() {
        didStopTracking = true
    }

    func simulateLocation(_ coordinate: CLLocationCoordinate2D) {
        locationUpdateHandler?(coordinate)
    }
}
