//
//  AccessibilityModeViewModel.swift
//  GoInfoGame
//
//  Created by Prashamsa on 26/11/25.
//

import Foundation
import CoreLocation

class AccessibilityModeViewModel: ObservableObject {
    private(set) var locationManager: LocationManagerDelegate
    private(set) var mapViewModel: MapViewModel
    @Published private(set) var nearestQuest: [AccessibilityQuest] = []
    let distanceThreshold: Double = 250 // 250 meters
    var lastKnownLocation: CLLocationCoordinate2D?
    init(mapViewModel: MapViewModel, locationManager: LocationManagerDelegate = LocationManagerDelegate()) {
        self.locationManager = locationManager
        self.mapViewModel = mapViewModel
    }
    
    func startMonitoring() {
        locationManager.locationUpdateHandler = { [weak self] location in
            self?.lastKnownLocation = location
            self?.filterQuestsNerestToUser(location: location, distanceThreshold: self?.distanceThreshold ?? 250)
        }
        locationManager.startUpdatingLocation(distanceFilter: kCLDistanceFilterNone)
    }
    
    func stopMonitoring() {
        locationManager.locationUpdateHandler = nil
        locationManager.stopUpdatingLocation()
    }
    
    func filterQuestsNerestToUser(location: CLLocationCoordinate2D, distanceThreshold: Double = 250) {
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let nearestQuests: [AccessibilityQuest] = self.mapViewModel.items.compactMap({ quest in
            guard quest.isHidden == false else {
                return nil
            }
            
            let distanceToQuest = userLocation.distance(from: quest.location)
            if distanceToQuest <= distanceThreshold {
                let degrees = userLocation.bearing(to: quest.location)
                let direction = Utilities.degreesToCardinalDirection(bearing: degrees)
                return AccessibilityQuest(distance: distanceToQuest, questType: quest.displayUnit.parent?.elementType ?? "Unknown", direction: direction, quest: quest)
            } else {
                return nil
            }
        })
        self.nearestQuest = nearestQuests
    }
    
    struct AccessibilityQuest: Hashable {
        let distance: Double
        let questType: String
        let direction: String
        let quest: DisplayUnitWithCoordinate
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(quest.id)
        }
    }
}
