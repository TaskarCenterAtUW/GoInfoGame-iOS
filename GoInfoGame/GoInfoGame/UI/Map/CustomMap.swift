//
//  CustomMap.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/03/24.
//

import Foundation
import SwiftUI
import MapKit

// Custom Map for managing map interactions between SwiftUI and UIKit components
struct CustomMap: UIViewRepresentable {
    
    @Binding var region: MKCoordinateRegion
    @Binding var trackingMode: MapUserTrackingMode
    var items: [DisplayUnitWithCoordinate]
    @Binding var selectedQuest: DisplayUnit?
    @Binding var isPresented: Bool
    var isLoading: Bool
    
    // Creates and configures the UIView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        // Set user tracking mode
        mapView.userTrackingMode = trackingMode.mkUserTrackingMode
        // Hide points of interest except street names
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }
    
    // Updates the UIView with new data
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Manage annotations
        manageAnnotations(mapView, context: context)
        // Update the region if necessary
        context.coordinator.updateRegion(mapView)
    }
    
    // Creates the coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class for managing delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMap
        var isRegionSet = false // boolean flag to track if region has been set
        init(_ parent: CustomMap) {
            self.parent = parent
        }
        
        // Customizes the view for each annotation
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Ensure annotation is of the correct type
            guard let displayUnitAnnotation = annotation as? DisplayUnitAnnotation else {
                return nil
            }
            
            let identifier = "customAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize annotation view
            customizeAnnotationView(annotationView, with: displayUnitAnnotation)
            
            return annotationView
        }
        
        // Handles selection of annotations
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let selectedQuest = annotation as? DisplayUnitAnnotation {
                parent.selectedQuest = selectedQuest.displayUnit
                parent.isPresented = true
            }
        }
        
        // Customizes the appearance of the annotation view
        private func customizeAnnotationView(_ annotationView: MKAnnotationView?, with displayUnitAnnotation: DisplayUnitAnnotation) {
            guard let annotationView = annotationView else { return }
            
            let pinImage = displayUnitAnnotation.displayUnit.parent?.icon
            let size = CGSize(width: 40, height: 40)
            
            UIGraphicsBeginImageContext(size)
            
            // Draw circular border
            if let context = UIGraphicsGetCurrentContext() {
                let borderRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                let borderWidth: CGFloat = 2.0
                context.setStrokeColor(UIColor.white.cgColor)
                context.setLineWidth(borderWidth)
                context.strokeEllipse(in: borderRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
                
                // Draw the pinImage inside the circular border
                let imageRect = borderRect.insetBy(dx: borderWidth, dy: borderWidth)
                pinImage?.draw(in: imageRect)
            }
            
            // Get the resized image with circular border
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Set the image with circular border to the annotation view
            annotationView.image = resizedImage
        }
        // Helper method to update the region
        func updateRegion(_ mapView: MKMapView) {
            // Update the region only if it hasn't been set yet
            if self.parent.isPresented  {
                return
            } else if !isRegionSet {
                mapView.setRegion(parent.region, animated: true)
            }
        }
        
    }
    
    // Helper method to manage annotations
    private func manageAnnotations(_ mapView: MKMapView, context: Context) {
        // Check if the existing annotations are same as the new ones
        let existingAnnotations = Set(mapView.annotations.compactMap { $0 as? DisplayUnitAnnotation })
        let newAnnotations = Set(items.map { $0.annotation })
        
        if existingAnnotations != newAnnotations {
            // Remove annotations that are not present in the new set
            let annotationsToRemove = existingAnnotations.subtracting(newAnnotations)
            mapView.removeAnnotations(Array(annotationsToRemove))
            
            // Add annotations that are present in the new set but not in the existing set
            let annotationsToAdd = newAnnotations.subtracting(existingAnnotations)
            mapView.addAnnotations(Array(annotationsToAdd))
            // Update the region if it hasn't been set yet
            if !context.coordinator.isRegionSet {
                mapView.setRegion(region, animated: true)
            }
            context.coordinator.isRegionSet = true
        }
    }
    
}

// Extension to convert MapUserTrackingMode to MKUserTrackingMode
extension MapUserTrackingMode {
    var mkUserTrackingMode: MKUserTrackingMode {
        switch self {
        case .none:
            return .none
        case .follow:
            return .follow
        case .followWithHeading:
            return .followWithHeading
        @unknown default:
            fatalError()
        }
    }
}
