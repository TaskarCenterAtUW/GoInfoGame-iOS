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
    let viewSpanDelta = 0.0004 // Delta lat/lng to show to the user

    
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
            fetchDataAndUpdateItems()
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
    // Function to calculate distance
    func calculateDistance(from location: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let userCurrentLocation = locationManagerDelegate.locationManager.location?.coordinate else { return CLLocationDistance(0) }
        
        let fromLocation = CLLocation(latitude: userCurrentLocation.latitude, longitude: userCurrentLocation.longitude)
        let toLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return CLLocationDistance(Int(fromLocation.distance(from: toLocation)))
    }
    
    // Function to infer direction
    func inferDirection(to selectedAnnotation: CLLocationCoordinate2D) -> String {
        guard let userCurrentLocation = locationManagerDelegate.locationManager.location?.coordinate else { return "undetermined" }
        let userLocationPoint = MKMapPoint(userCurrentLocation)
        let destinationPoint = MKMapPoint(selectedAnnotation)
        let angleRadians = atan2(destinationPoint.y - userLocationPoint.y, destinationPoint.x - userLocationPoint.x)
        var angleDegrees = angleRadians * 180 / .pi
        angleDegrees += 90
        
        if angleDegrees < 0 {
            angleDegrees += 360
        } else if angleDegrees >= 360 {
            angleDegrees -= 360
        }
        
        angleDegrees = (angleDegrees * 10).rounded() / 10
        
        var direction = ""
        
        // Convert angle into relative direction
        if angleDegrees >= 337.5 || angleDegrees < 22.5 {
            direction = "ahead"
        } else if angleDegrees >= 22.5 && angleDegrees < 112.5 {
            direction = "right"
        } else if angleDegrees >= 112.5 && angleDegrees < 202.5 {
            direction = "behind"
        } else if angleDegrees >= 202.5 && angleDegrees < 292.5 {
            direction = "left"
        } else {
            direction = "right"
        }
        
        return direction
    }
    
    // Function to infer street name
    func inferStreetName(from location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion("")
                return
            }
            var addressComponents: [String] = []
            if let streetNumber = placemark.subThoroughfare {
                addressComponents.append(streetNumber)
            }
            if let streetName = placemark.thoroughfare {
                addressComponents.append(streetName)
            }
            
            let address = addressComponents.joined(separator: ", ")
            completion(address)
        }
    }
    func getSubheading(displayUnit: DisplayUnitWithCoordinate, completion: @escaping (String) -> Void) {
        var contextualString = ""
        let distance = Int(calculateDistance(from: displayUnit.coordinateInfo))
        let direction = inferDirection(to: displayUnit.coordinateInfo)

        let annotationLocation = CLLocation(latitude: displayUnit.coordinateInfo.latitude, longitude: displayUnit.coordinateInfo.longitude)
        
        inferStreetName(from: annotationLocation) { streetName in
            if let streetName = streetName {
                if displayUnit.displayUnit.parent is SideWalkWidth {
                    contextualString = "The Sidewalk is along \(streetName == "" ? "the street" : streetName) at \(distance) meters \(direction) of you"
                } else {
                    contextualString = "The \(displayUnit.displayUnit.title) is on \(streetName == "" ? "the street" : streetName) at \(distance) meters \(direction) of you"
                }
            } else {
                contextualString = "Failed to infer street name"
            }
            
            completion(contextualString)
        }
    }
    // Function to fetch data and update subheadings of items
    func fetchDataAndUpdateItems() {
        for var item in items {
            getSubheading(displayUnit: item) { subheading in
                item.subheading = subheading
                DispatchQueue.main.async {
                    if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                        self.items[index] = item
                    }
                }
            }
        }
    }
}

