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
    @Published var isLoading: Bool = false

    init() {
        self.coordinateRegion = MKCoordinateRegion()
        locationManager.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.centerMapOnLocation(location)
            }
        }
       // fetchData()
    }

    func fetchData() {
        isLoading = true
        let boundingBox = boundingBoxAroundLocation(location: locationManager.currentLocation ?? CLLocation(latitude: coordinateRegion.center.latitude, longitude: coordinateRegion.center.longitude), distance: 1000)
        AppQuestManager.shared.fetchData(fromBBOx: boundingBox) { [weak self] in
            guard let self = self else { return }
            self.items = AppQuestManager.shared.fetchQuestsFromDB()
            isLoading = false
        }
    }
    
    func centerMapOnLocation(_ location: CLLocation) {
        // Update coordinate region only if necessary
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: coordinateRegion.span.latitudeDelta, longitudinalMeters: coordinateRegion.span.longitudeDelta)
        if !coordinateRegionIsEqual(region, coordinateRegion) {
            coordinateRegion = region
            fetchData() // Fetch data when the map region changes
        }
    }

    private func coordinateRegionIsEqual(_ region1: MKCoordinateRegion, _ region2: MKCoordinateRegion) -> Bool {
        return region1.center.latitude == region2.center.latitude &&
               region1.center.longitude == region2.center.longitude &&
               region1.span.latitudeDelta == region2.span.latitudeDelta &&
               region1.span.longitudeDelta == region2.span.longitudeDelta
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

