//
//  MapKitViewController.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 16/11/23.
//

import UIKit
import MapKit
import SwiftOverpassAPI


class MapKitViewController: UIViewController {
    
    private let locationManager = LocationManager()
    
    private let overpassManager = OverpassRequestManager()
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        configureLocationServices()
    }
    
    private func configureLocationServices() {        locationManager.locationUpdateHandler = { [weak self] coordinate in
        self?.zoomToLatestLocation(with: coordinate)
        
        self?.locationManager.getCurrentLocation { [weak self] result in
            guard let self = self else { return }
            
            let minLatitude = result["minLatitude"]!
            let minLongitude = result["minLongitude"]!
            let maxLatitude = result["maxLatitude"]!
            let maxLongitude = result["maxLongitude"]!
            
            self.overpassManager.makeOverpassRequest( forBoundingBox: minLatitude, minLongitude, maxLatitude, maxLongitude) { [weak self] elements in
                print(elements)
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
        
        var annotations = [MKAnnotation]()
        var polylines = [MKPolyline]()
        var polygons = [MKPolygon]()
        
        for visualization in visualizations.values {
            switch visualization {
            case .annotation(let annotation):
                annotations.append(annotation)
            case .polyline(let polyline):
                polylines.append(polyline)
            case .polylines(let newPolylines):
                polylines.append(contentsOf: newPolylines)
            case .polygon(let polygon):
                polygons.append(polygon)
            case .polygons(let newPolygons):
                polygons.append(contentsOf: newPolygons)
            }
        }
        
        if #available(iOS 13, *) {
            let multiPolyline = MKMultiPolyline(polylines)
            let multiPolygon = MKMultiPolygon(polygons)
            mapView.addOverlay(multiPolygon)
            mapView.addOverlay(multiPolyline)
        } else {
            mapView.addOverlays(polygons)
            mapView.addOverlays(polylines)
        }
        
        mapView.addAnnotations(annotations)
    }
    
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(zoomRegion, animated: true)
    }
    
}

extension MapKitViewController: MKMapViewDelegate {
    func mapView(
        _ mapView: MKMapView,
        rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let strokeWidth: CGFloat = 2
        let strokeColor = UIColor.blue
        let fillColor = UIColor.blue.withAlphaComponent(0.5)
        
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(
                polyline: polyline)
            renderer.strokeColor = strokeColor
            renderer.lineWidth = strokeWidth
            return renderer
        } else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(
                polygon: polygon)
            renderer.fillColor = fillColor
            renderer.strokeColor = strokeColor
            renderer.lineWidth = strokeWidth
            return renderer
        }    else if let multiPolyline = overlay as? MKMultiPolyline {
            let renderer = MKMultiPolylineRenderer(
                multiPolyline: multiPolyline)
            renderer.strokeColor = strokeColor
            renderer.lineWidth = strokeWidth
            return renderer
        } else if let multiPolygon = overlay as? MKMultiPolygon {
            let renderer = MKMultiPolygonRenderer(
                multiPolygon: multiPolygon)
            renderer.fillColor = fillColor
            renderer.strokeColor = strokeColor
            renderer.lineWidth = strokeWidth
            return renderer
        } else {
            return MKOverlayRenderer()
        }
    }
    

    func mapView( _ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard
            let pointAnnotation = annotation as? MKPointAnnotation
        else {
            return nil
        }
        
        let view = MKMarkerAnnotationView(
            annotation: pointAnnotation,
            reuseIdentifier: "Annotation")
        view.markerTintColor = UIColor.red
        return view
    }
}
