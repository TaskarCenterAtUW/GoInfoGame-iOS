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

    let locationManagerDelegate = LocationManagerDelegate()
    @Published var isLoading: Bool = false
    var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312), span: MKCoordinateSpan(latitudeDelta: 0.0004 , longitudeDelta: 0.0004 ))
    let viewSpanDelta = 0.008 // Delta lat/lng to show to the user

    
    @Published var items: [DisplayUnitWithCoordinate] = []
    @Published var selectedQuest: DisplayUnit?
    let dataSpanDistance: CLLocationDistance = 1000 // Distance from user location to get the data
    
    init() {
        locationManagerDelegate.locationManager.delegate = locationManagerDelegate
        locationManagerDelegate.locationManager.requestWhenInUseAuthorization()
        locationManagerDelegate.locationManager.startUpdatingLocation()
        
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            fetchOSMDataFor(currentLocation: location)
        }
        
    }
    
    @objc private func locationDidChange() {
        guard let userLocation = locationManagerDelegate.location else { return }
        fetchOSMDataFor(currentLocation: userLocation)
    }

    func fetchOSMDataFor(currentLocation: CLLocation) {
        isLoading = true
        let bBox = boundingBoxAroundLocation(location: currentLocation, distance: dataSpanDistance)
        self.region = MKCoordinateRegion(center: currentLocation.coordinate, span: MKCoordinateSpan(
            latitudeDelta: viewSpanDelta,
            longitudeDelta: viewSpanDelta
        ))
        AppQuestManager.shared.fetchData(fromBBOx: bBox) { [weak self] in
            guard let self = self else { return }
            self.items = AppQuestManager.shared.fetchQuestsFromDB()
            self.isLoading = false
        }
    }
        
    private func boundingBoxAroundLocation(location: CLLocation, distance: CLLocationDistance) -> BBox {
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: distance, longitudinalMeters: distance)
        let center = region.center
        let span = region.span
        let minLat = center.latitude - span.latitudeDelta / 2
        let maxLat = center.latitude + span.latitudeDelta / 2
        let minLon = center.longitude - span.longitudeDelta / 2
        let maxLon = center.longitude + span.longitudeDelta / 2
        
       
        return BBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
}

