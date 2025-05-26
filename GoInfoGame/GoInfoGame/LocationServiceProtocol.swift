//
//  LocationServiceProtocol.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

import CoreLocation

protocol LocationServiceProtocol {
    var location: CLLocation? { get }
    var isLocationDenied: Bool { get }
    var isLocationServicesOff: Bool { get }

    func requestLocationAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    var locationUpdateHandler: ((CLLocationCoordinate2D) -> Void)? { get set }
}
