//
//  HomeMapViewModel.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 23/11/23.
//

import Foundation
import MapKit
import SwiftOverpassAPI

class HomeMapViewModel: ObservableObject {
    private let locationManager = LocationManager()
    private let overpassManager = OverpassRequestManager()
    @Published var isLoading: Bool = false
    @Published var annotations: [IdentifiablePointAnnotation] = []
    @Published var polylines: [MKPolyline] = []
    @Published var polygons: [MKPolygon] = []
    func configureLocationServices() {
        
        locationManager.locationUpdateHandler = { [weak self] coordinate in
            self?.locationManager.getCurrentLocation { [weak self] result in
                guard let self = self else { return }
                
                let minLatitude = result["minLatitude"]!
                let minLongitude = result["minLongitude"]!
                let maxLatitude = result["maxLatitude"]!
                let maxLongitude = result["maxLongitude"]!
                self.isLoading = true
                self.overpassManager.makeOverpassRequest(forBoundingBox: minLatitude, minLongitude, maxLatitude, maxLongitude) { [weak self] elements in
                    
                    let elementsArray = Array(elements.values)
                    let opWayArray = elementsArray.compactMap { $0 as? OPWay }
                    
                    DatabaseConnector.shared.deleteAllElements()
                    DatabaseConnector.shared.saveElements(opWayArray)
                    
                    //Load From DB
                    self?.addDatabaseVisualizations();
                    
                    //Test with Visulaization
                   // self?.testWithVisulization(elements: elements)
                    
                    self?.isLoading = false
                    self?.locationManager.setOverpassRequestInProgress(false)
                }
            }
        }
    }
    

    
    private func addDatabaseVisualizations() {
        
        let visualization = DatabaseConnector.shared.getElements()
        
        var newAnnotations = [IdentifiablePointAnnotation]()
        var newPolylines = [MKPolyline]()
        let newPolygons = [MKPolygon]()
        
        for realmOPElement in visualization {
            guard let realmOPGeometry = realmOPElement.geometry.first else {
                return
            }
            
            switch realmOPGeometry.type {
            case Constants.kCenter:
                
                if let centerAnnotation = createCenterAnnotation(from: realmOPElement) {
                              newAnnotations.append(centerAnnotation)
                }
                
            case Constants.kPolyline:
//                let polylineCoordinates: [CLLocationCoordinate2D] = realmOPGeometry.polyline.compactMap { coordinateObject in
//                   
//                    return CLLocationCoordinate2D(latitude: coordinateObject.latitude, longitude: coordinateObject.longitude)
//                }
//                let polyline = MKPolyline(coordinates: polylineCoordinates, count: polylineCoordinates.count)
//
//                newPolylines.append(polyline)
//                newAnnotations.append(contentsOf: getAnnotations(from: polyline, id: realmOPElement.id))
                if let polyline = createPolyline(from: realmOPGeometry) {
                                newPolylines.append(polyline)
                                newAnnotations.append(contentsOf: getAnnotations(from: polyline, id: realmOPElement.id))
                            }
            case Constants.kMultiPolyline:
                let polylineCoordinates: [CLLocationCoordinate2D] = realmOPGeometry.polyline.compactMap { coordinateObject in
                   
                    return CLLocationCoordinate2D(latitude: coordinateObject.latitude, longitude: coordinateObject.longitude)
                }
                let polyline = MKPolyline(coordinates: polylineCoordinates, count: polylineCoordinates.count)

                newPolylines.append(polyline)
                newAnnotations.append(contentsOf: getAnnotations(from: polyline, id: realmOPElement.id))
            case  Constants.kPolygon:
                
                let polygonCoordinates: [CLLocationCoordinate2D] = realmOPGeometry.polygon.compactMap { coordinateObject in
                   
                    return CLLocationCoordinate2D(latitude: coordinateObject.latitude, longitude: coordinateObject.longitude)
                }
                let polygonline = MKPolyline(coordinates: polygonCoordinates, count: polygonCoordinates.count)

                newPolylines.append(polygonline)
                newAnnotations.append(contentsOf: getAnnotations(from: polygonline, id: realmOPElement.id))
            case Constants.kMultiPolygon:
                break
            default:
                break
            }
        }
        
      
        
        DispatchQueue.main.async {
            self.annotations = newAnnotations
            self.polylines = newPolylines
            self.polygons = newPolygons
        }
    }
    
    private func createPolyline(from realmOPGeometry: RealmOPGeometry) -> MKPolyline? {
        let coordinates: [CLLocationCoordinate2D] = realmOPGeometry.polyline.compactMap { coordinateObject in
            return CLLocationCoordinate2D(latitude: coordinateObject.latitude, longitude: coordinateObject.longitude)
        }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    private func testWithVisulization(elements: [Int: OPElement]) {
        
        let visualizations = self.overpassManager.visualise(elements: elements)
        self.addVisualizations(visualizations)
    }
    
    private func addVisualizations(_ visualizations: [Int: OPMapKitVisualization]) {
        var newAnnotations = [IdentifiablePointAnnotation]()
        var newPolylines = [MKPolyline]()
        var newPolygons = [MKPolygon]()
        
        for visualization in visualizations.values {
            switch visualization {
            case .annotation(let annotation):
                let newAnnotation = IdentifiablePointAnnotation(
                    id: 0,
                    coordinate: annotation.coordinate,
                    title: annotation.title ?? "",
                    subtitle: annotation.subtitle ?? ""
                )
                newAnnotations.append(newAnnotation)
            case .polyline(let polyline):
                newPolylines.append(polyline)
                newAnnotations.append(contentsOf: getAnnotations(from: polyline, id: 0))
            case .polylines(let polylines):
                newPolylines.append(contentsOf: polylines)
                newAnnotations.append(contentsOf: polylines.flatMap { getAnnotations(from: $0, id: 0) })
            case .polygon(let polygon):
                newPolygons.append(polygon)
                newAnnotations.append(contentsOf: getAnnotations(from: polygon, id: 0))
            case .polygons(_): break
            }
        }
        
        DispatchQueue.main.async {
            self.annotations = newAnnotations
            self.polylines = newPolylines
            self.polygons = newPolygons
            print("Annotations count")
        }
    }
    
    private func getAnnotations(from polyline: MKPolyline, id: Int) -> [IdentifiablePointAnnotation] {
        let points = UnsafeBufferPointer(start: polyline.points(), count: Int(polyline.pointCount))
        return points.map { IdentifiablePointAnnotation(id: id, coordinate: $0.coordinate, title: "", subtitle: "") }
    }
    
    private func getAnnotations(from polygon: MKPolygon,  id: Int) -> [IdentifiablePointAnnotation] {
        let points = UnsafeBufferPointer(start: polygon.points(), count: Int(polygon.pointCount))
        return points.map { IdentifiablePointAnnotation(id: id, coordinate: $0.coordinate, title: "", subtitle: "") }
    }
    
    private func createCenterAnnotation(from realmOPElement: RealmOPElement) -> IdentifiablePointAnnotation? {
        return IdentifiablePointAnnotation(
            id: realmOPElement.id,
            coordinate: CLLocationCoordinate2D(
                latitude: realmOPElement.geometry[0].centerLatitude,
                longitude: realmOPElement.geometry[0].centerLongitude
            )
        )
    }
    
  
    
    private func createPolygon(from realmOPGeometry: RealmOPGeometry) -> MKPolygon? {
        let coordinates: [CLLocationCoordinate2D]  = realmOPGeometry.polygon.compactMap { coordinateObject in
            return CLLocationCoordinate2D(latitude: coordinateObject.latitude, longitude: coordinateObject.longitude)
        }
        return MKPolygon(coordinates: coordinates, count: coordinates.count)
    }
}
