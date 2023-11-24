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

                self.overpassManager.makeOverpassRequest(forBoundingBox: minLatitude, minLongitude, maxLatitude, maxLongitude) { [weak self] elements in
                    let visualizations = self?.overpassManager.visualise(elements: elements)
                    if let visualizations = visualizations {
                        self?.addVisualizations(visualizations)
                    }

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
                newAnnotations.append( IdentifiablePointAnnotation(
                    coordinate: annotation.coordinate,
                    title: annotation.title ?? "",
                    subtitle: annotation.subtitle ?? "")
                )
                print(newAnnotations.count)
            case .polyline(let polyline):
                newPolylines.append(polyline)
                
            case .polygon(let polygon):
                newPolygons.append(polygon)
            case .polygons(_): break
                
            case .polylines(_):break
                
            }
            
            DispatchQueue.main.async {
                self.annotations = newAnnotations
                self.polylines = newPolylines
                self.polygons = newPolygons
            }
        }
    }

}
