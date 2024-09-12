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
import osmapi


class MapViewModel: ObservableObject {

    let locationManagerDelegate = LocationManagerDelegate()
    @Published var isLoading: Bool = false
    var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312), span: MKCoordinateSpan(latitudeDelta: 0.0009 , longitudeDelta: 0.0009))
    let viewSpanDelta = 0.001 // Delta lat/lng to show to the user
    var userlocation =  CLLocationCoordinate2D(latitude: 17.4700, longitude: 78.3534)
    @Published var refreshMap = UUID()
    @Published var items: [DisplayUnitWithCoordinate] = []
    @Published var selectedQuest: DisplayUnit?
    let dataSpanDistance: CLLocationDistance = 1000 // Distance from user location to get the data
    
   private let dbInstance = DatabaseConnector.shared
    
    init() {
        locationManagerDelegate.locationManager.delegate = locationManagerDelegate
        locationManagerDelegate.locationManager.requestWhenInUseAuthorization()
        locationManagerDelegate.locationManager.startUpdatingLocation()
        
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            self.userlocation = location
            fetchOSMDataFor(currentLocation: location)
        }
    }
    
    @objc private func locationDidChange() {
        guard let userLocation = locationManagerDelegate.location else { return }
        fetchOSMDataFor(currentLocation: userLocation.coordinate)
    }
    
    func fetchOSMDataFor(currentLocation: CLLocationCoordinate2D) {
        isLoading = true
        let bBox = boundingBoxAroundLocation(location: currentLocation, distance: dataSpanDistance)
        self.region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(
            latitudeDelta: viewSpanDelta,
            longitudeDelta: viewSpanDelta
        ))
        
        if let workspaceID = KeychainManager.load(key: "workspaceID") {
            
            ApiManager.shared.performRequest(to: .fetchOSMElements(bBox.minLon, bBox.minLat, bBox.maxLon, bBox.maxLat, workspaceID), setupType: .osm, modelType: OSMMapDataResponse.self) { result in
                switch result {
                case .success(let success):
                   let osmElements = success.getOSMElements()
                    print("OSM ELEMENTS ??? \(osmElements)")
                    
                    let response = Array(osmElements.values)
                    let allValues = response
                    
                    DispatchQueue.main.async {
                        self.dbInstance.saveOSMElements(allValues) // Save all where there are tags
                        self.items = AppQuestManager.shared.fetchQuestsFromDB()
                        self.isLoading = false
                        if self.items.count == 0 {self.refreshMap = UUID()}
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }
    
    func refreshQuests() {
        self.items = AppQuestManager.shared.fetchQuestsFromDB()
    }
    
    func refreshMapAfterSubmission(elementId: String) {
            
//        if let newItem = AppQuestManager.shared.getUpdatedQuest(elementId: elementId) {
//            let toReplace = self.items.first(where: {$0.id == Int(elementId)!})
//            let index = self.items.firstIndex(where: {$0.id == Int(elementId)!})
//            
//            self.items.remove(at: index!)
//            self.items.insert(newItem, at: index!)
//        }
//        else{
            if let toReplace = self.items.first(where: {$0.id == Int(elementId)!}) {
                let index = self.items.firstIndex(where: {$0.id == Int(elementId)!})
                self.items.remove(at: index!)
            }
      //  }
    }
        
    private func boundingBoxAroundLocation(location: CLLocationCoordinate2D, distance: CLLocationDistance) -> BBox {
        let region = MKCoordinateRegion(center: location, latitudinalMeters: distance, longitudinalMeters: distance)
        let center = region.center
        let span = region.span
        let minLat = center.latitude - span.latitudeDelta / 2
        let maxLat = center.latitude + span.latitudeDelta / 2
        let minLon = center.longitude - span.longitudeDelta / 2
        let maxLon = center.longitude + span.longitudeDelta / 2
        
       
        return BBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
    
//    func fetchOSMDataForx(currentLocation: CLLocationCoordinate2D) {
//        isLoading = true
//        let bBox = boundingBoxAroundLocation(location: currentLocation, distance: dataSpanDistance)
//        self.region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(
//            latitudeDelta: viewSpanDelta,
//            longitudeDelta: viewSpanDelta
//        ))
//        AppQuestManager.shared.fetchData(fromBBOx: bBox) { [weak self] in
//            guard let self = self else { return }
//            self.items = AppQuestManager.shared.fetchQuestsFromDB()
//            self.isLoading = false
//            if self.items.count == 0 {self.refreshMap = UUID()}
//            
//        }
//    }
}
