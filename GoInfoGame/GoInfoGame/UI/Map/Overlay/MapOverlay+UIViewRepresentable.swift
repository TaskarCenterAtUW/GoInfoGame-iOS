//
//  MapOverlay+UIViewRepresentable.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 24/11/23.
//

import Foundation
import MapKit
import SwiftUI

struct MapViewWithOverlays: UIViewRepresentable {
    @Binding var polylines: [MKPolyline]
    @Binding var polygons: [MKPolygon]
    @Binding var annotations: [IdentifiablePointAnnotation]
    @State private var selectedOverlay: MKOverlay?
    @Binding var selectedAnnotation: IdentifiablePointAnnotation?
    @Binding var showCallout: Bool
    
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region: MKCoordinateRegion?
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithOverlays
        
        init(parent: MapViewWithOverlays) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
                renderer.strokeColor = .red
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if let region = parent.region {
                mapView.setRegion(region, animated: true)
            } else {
                let userLocation = mapView.userLocation.coordinate
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let initialRegion = MKCoordinateRegion(center: userLocation, span: span)
                mapView.setRegion(initialRegion, animated: true)
            }
        }
        
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pointAnnotation = annotation as? IdentifiablePointAnnotation else {
                return nil
            }
            
            let identifier = "customAnnotation"
            var annotationView: MKAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView = dequeuedView
            } else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.canShowCallout = true
            }
            
            annotationView.image = UIImage(named: "mapicon")
            
            let calloutView = CustomCalloutView(annotation: pointAnnotation)
            annotationView.detailCalloutAccessoryView = UIHostingController(rootView: calloutView).view
            
            return annotationView
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(polylines)
        uiView.addOverlays(polygons)
        uiView.addAnnotations(annotations)
        if let userLocation = uiView.userLocation.location?.coordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation
            annotation.title = "Current Location"
            uiView.addAnnotation(annotation)
        }
    }
}
