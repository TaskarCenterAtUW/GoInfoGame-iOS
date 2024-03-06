//
//  MapViewCoordinator.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/03/24.
//

import Foundation
import SwiftUI
import MapKit

struct MapViewCoordinator: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var trackingMode: MapUserTrackingMode
    var items: [DisplayUnitWithCoordinate]
    @Binding var selectedQuest: DisplayUnit?
    @Binding var isPresented: Bool
    var isLoading: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        let mkTrackingMode: MKUserTrackingMode
                switch trackingMode {
                case .none:
                    mkTrackingMode = .none
                case .follow:
                    mkTrackingMode = .follow
                case .followWithHeading:
                    mkTrackingMode = .followWithHeading
                @unknown default:
                    fatalError()
                }
        mapView.userTrackingMode = mkTrackingMode

        // To hide points of interest
        mapView.pointOfInterestFilter = .excludingAll
        
        // To add annotations
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(items.map { $0.annotation })
    }
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard let displayUnitAnnotation = annotation as? DisplayUnitWithCoordinate else {
//                        return nil
//                    }
//              let identifier = "customAnnotation"
//              var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//
//              if annotationView == nil {
//                  annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                  annotationView?.canShowCallout = true
//                  annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//              } else {
//                  annotationView?.annotation = annotation
//              }
//
//        annotationView?.image = displayUnitAnnotation.displayUnit.parent?.icon
//              return annotationView
//          }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewCoordinator

        init(_ parent: MapViewCoordinator) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let selectedQuest = parent.items.first(where: { $0.annotation === view.annotation }) else { return }
            parent.selectedQuest = selectedQuest.displayUnit
            parent.isPresented = true
        }
    }
}
