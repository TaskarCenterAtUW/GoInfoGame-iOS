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
                    let visualizations = self?.overpassManager.visualise(elements: elements)
                    if let visualizations = visualizations {
                        self?.addVisualizations(visualizations)
                    }
                    self?.isLoading = false
                    self?.locationManager.setOverpassRequestInProgress(false)
                }
            }
        }
    }
    
    private func addVisualizations(_ visualizations: [Int: OPMapKitVisualization]) {
        var newAnnotations = [IdentifiablePointAnnotation]()
        var newPolylines = [MKPolyline]()
        var newPolygons = [MKPolygon]()
        
        for visualization in visualizations.values {
            switch visualization {
            case .annotation(let annotation):
                let newAnnotation = IdentifiablePointAnnotation(
                    coordinate: annotation.coordinate,
                    title: annotation.title ?? "",
                    subtitle: annotation.subtitle ?? ""
                )
                newAnnotations.append(newAnnotation)
            case .polyline(let polyline):
                newPolylines.append(polyline)
                newAnnotations.append(contentsOf: getAnnotations(from: polyline))
            case .polylines(let polylines):
                newPolylines.append(contentsOf: polylines)
                newAnnotations.append(contentsOf: polylines.flatMap { getAnnotations(from: $0) })
            case .polygon(let polygon):
                newPolygons.append(polygon)
                newAnnotations.append(contentsOf: getAnnotations(from: polygon))
            case .polygons(_): break
            }
        }
        
        DispatchQueue.main.async {
            self.annotations = newAnnotations
            self.polylines = newPolylines
            self.polygons = newPolygons
        }
    }
    
    private func getAnnotations(from polyline: MKPolyline) -> [IdentifiablePointAnnotation] {
        let points = UnsafeBufferPointer(start: polyline.points(), count: Int(polyline.pointCount))
        return points.map { IdentifiablePointAnnotation(coordinate: $0.coordinate, title: "", subtitle: "") }
    }
    
    private func getAnnotations(from polygon: MKPolygon) -> [IdentifiablePointAnnotation] {
        let points = UnsafeBufferPointer(start: polygon.points(), count: Int(polygon.pointCount))
        return points.map { IdentifiablePointAnnotation(coordinate: $0.coordinate, title: "", subtitle: "") }
    }
    
}
