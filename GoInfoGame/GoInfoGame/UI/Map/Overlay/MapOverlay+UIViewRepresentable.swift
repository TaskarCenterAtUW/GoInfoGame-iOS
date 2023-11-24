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
    }
}