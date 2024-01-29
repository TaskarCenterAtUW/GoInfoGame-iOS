//
//  MapViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 29/01/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class MapViewModel: ObservableObject {
    @Published var coordinateRegion = MKCoordinateRegion()
    @Published var items: [DisplayUnitWithCoordinate] = []
    @Published var selectedQuest: DisplayUnit?

    private let locationManager = LocationManagerCoordinator()

    init() {
        self.coordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        locationManager.locationUpdateHandler = { [weak self] location in
                guard let self = self else { return }
            DispatchQueue.main.async {
                self.centerMapOnLocation(location)
            }
        }
        fetchData()
    }

    func fetchData() {
        let boundingBox = boundingBoxAroundLocation(location: locationManager.currentLocation ?? CLLocation(latitude: coordinateRegion.center.latitude, longitude: coordinateRegion.center.longitude), distance: 1000)
        AppQuestManager.shared.fetchData(fromBBOx: boundingBox)
        items = AppQuestManager.shared.fetchQuestsFromDB()
    }

    func centerMapOnLocation(_ location: CLLocation) {
        let userLocation = location.coordinate
        DispatchQueue.main.async {
            self.coordinateRegion.center = userLocation
            self.fetchData()
        }
    }

    private func boundingBoxAroundLocation(location: CLLocation, distance: CLLocationDistance) -> BBox {
        let latDelta = 0.008
        let lonDelta = 0.008
        let coordinate = location.coordinate
        let minLat = coordinate.latitude - latDelta
        let maxLat = coordinate.latitude + latDelta
        let minLon = coordinate.longitude - lonDelta
        let maxLon = coordinate.longitude + lonDelta
        return BBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
}
