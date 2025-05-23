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

enum BBoxSource {
    case currentLocation(location: CLLocationCoordinate2D)
    case visibleRect(mapView: MKMapView)
}


class MapViewModel: ObservableObject {

    let locationManagerDelegate = LocationManagerDelegate()
    @Published var isLoading: Bool = false
//    var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312), span: MKCoordinateSpan(latitudeDelta: 0.0009 , longitudeDelta: 0.0009))
    @Published var region = MKCoordinateRegion()
    let viewSpanDelta = 0.005 // Delta lat/lng to show to the user
   // var userlocation =  CLLocationCoordinate2D(latitude: 17.4700, longitude: 78.3534)
    @Published var userlocation: CLLocationCoordinate2D? = nil
    @Published var refreshMap = UUID()
    @Published var items: [DisplayUnitWithCoordinate] = []
    @Published var selectedQuest: DisplayUnit?
    let dataSpanDistance: CLLocationDistance = 1000 // Distance from user location to get the data
    @Published var selectedAnnotaions: Set<DisplayUnitAnnotation> = []
    @Published var selectedAnnotationType: String?
    
    var isMultiSelectModeEnabled = false
    
   private let dbInstance = DatabaseConnector.shared
    
    private let api: POSMAPIProtocol
    
    init(api: POSMAPIProtocol = POSMAPIManager.shared) {
        self.api = api
        
           locationManagerDelegate.locationUpdateHandler = { [weak self] location in
               guard let self = self else { return }

               DispatchQueue.main.async {
                   self.userlocation = location
                   self.region = MKCoordinateRegion(
                       center: location,
                       span: MKCoordinateSpan(latitudeDelta: self.viewSpanDelta, longitudeDelta: self.viewSpanDelta)
                   )
                   self.fetchOSMDataFor(from: .currentLocation(location: location))
               }
           }

           locationManagerDelegate.requestLocationAuthorization()
           locationManagerDelegate.startUpdatingLocation()
       }
    
    func getSelectedQuest() -> DisplayUnit? {
        if isMultiSelectModeEnabled {
            let displayUnit = selectedAnnotaions.first?.displayUnit
            if let longElementQuest = displayUnit?.parent as? LongElementQuest {
                longElementQuest.questAnswersSelected = { [weak self] tags in
                    guard let self = self else {
                        return
                    }
                    
                    for quest in self.selectedAnnotaions {
                        print("Quest ID: \(quest.displayUnit.id) Tags: \(tags)")
                        if let longElementQuest = quest.displayUnit.parent as? LongElementQuest {
                            longElementQuest.onAnswer(answer: tags)
                        }
                    }
                    self.selectedAnnotaions.removeAll()
                    self.selectedAnnotationType = nil
                    DispatchQueue.main.async {
                        self.isMultiSelectModeEnabled = false
                        self.selectedAnnotaions = Set<DisplayUnitAnnotation>()
                    }
                }
            }
            return displayUnit
        } else {
            if let longElementQuest = selectedQuest?.parent as? LongElementQuest {
                longElementQuest.questAnswersSelected = { [weak self] tags in
                    guard let self = self else {
                        return
                    }
                    longElementQuest.onAnswer(answer: tags)
                }
            }
            return selectedQuest
        }
    }
    
    @objc private func locationDidChange() {
        guard let userLocation = locationManagerDelegate.location else { return }
       // fetchOSMDataFor(currentLocation: userLocation.coordinate)
        fetchOSMDataFor(from: .currentLocation(location: userLocation.coordinate))
    }
    
    func fetchOSMDataFor(from bboxSource: BBoxSource) {
        isLoading = true
        let bBox: BBox
           switch bboxSource {
           case .currentLocation(let center):
               self.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(
                   latitudeDelta: viewSpanDelta,
                   longitudeDelta: viewSpanDelta
               ))
               bBox = boundingBoxAroundLocation(location: center, distance: dataSpanDistance)
               
           case .visibleRect(let mapView):
               bBox = boundingBoxFromVisibleMapRect(mapView: mapView)
           }
        
            api.fetchOSMElements(left: bBox.minLon, bottom: bBox.minLat, right:  bBox.maxLon, top: bBox.maxLat) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let success):
                   let osmElements = success.getOSMElements()
                    
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
    
    // The item may have been already resolved or changed.
    // Try and add the item to items
    func refreshMapAfterUndoSumbit(storedChangesetId: String) {
        print("Refreshing map after undo submit")
        
        if let newItem = AppQuestManager.shared.fetchQuestForChangeset(storedChangesetId: storedChangesetId) {
            self.items.append(newItem)
        } else {
            print("No new item got")
        }
        
    }
    
    func hideQuest(elementId: String, elementName: String) {
        print(elementId)
        HiddenQuestManager.shared.hideQuest(elementId: elementId, elementName: elementName, items: &items)
    }
    
    private func getBBox(from source: BBoxSource) -> BBox {
        switch source {
        case .currentLocation(let center):
            return boundingBoxAroundLocation(location: center, distance: dataSpanDistance)
        case .visibleRect(let mapView):
            return boundingBoxFromVisibleMapRect(mapView: mapView)
        }
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
    
     func boundingBoxFromVisibleMapRect(mapView: MKMapView) -> BBox {
        let mapRect = mapView.visibleMapRect
        let topLeft = MKMapPoint(x: mapRect.origin.x, y: mapRect.origin.y)
        let bottomRight = MKMapPoint(x: mapRect.origin.x + mapRect.size.width,
                                     y: mapRect.origin.y + mapRect.size.height)

        let topLeftCoord = topLeft.coordinate
        let bottomRightCoord = bottomRight.coordinate

        let minLat = bottomRightCoord.latitude
        let maxLat = topLeftCoord.latitude
        let minLon = topLeftCoord.longitude
        let maxLon = bottomRightCoord.longitude

        return BBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
}
