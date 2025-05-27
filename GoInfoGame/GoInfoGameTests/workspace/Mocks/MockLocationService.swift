//
//  MockLocationService.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

import CoreLocation
@testable import GoInfoGame

class MockLocationService: LocationServiceProtocol {
    var location: CLLocation?
    var isLocationDenied: Bool = false
    var isLocationServicesOff: Bool = false
    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)?

    var didRequestAuthorization = false
    var didStartUpdatingLocation = false
    var didStopUpdatingLocation = false

    func requestLocationAuthorization() {
        didRequestAuthorization = true
    }

    func startUpdatingLocation() {
        didStartUpdatingLocation = true
    }

    func stopUpdatingLocation() {
        didStopUpdatingLocation = true
    }
}
