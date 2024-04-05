//
//  CustomMap.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/03/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

// Custom Map for managing map interactions between SwiftUI and UIKit components
struct CustomMap: UIViewRepresentable {
    
    @Binding var region: MKCoordinateRegion
    @Binding var trackingMode: MapUserTrackingMode
    var items: [DisplayUnitWithCoordinate]
    @Binding var selectedQuest: DisplayUnit?
    @Binding var isPresented: Bool
    @StateObject var locationManagerDelegate = LocationManagerDelegate()
    
    var contextualInfo: ((String) -> Void)?
    
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
        var contextualInfo: ((String) -> Void)?
        
        init(_ parent: CustomMap) {
            self.parent = parent
            self.contextualInfo = parent.contextualInfo
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
                var contextualString = ""
                let distance = Int(parent.calculateDistance(selectedAnnotation: selectedQuest.coordinate))
               // let direction = parent.inferDirection(selectedAnnotation: selectedQuest.coordinate)
                
                let annotationLocation = CLLocation(latitude: selectedQuest.coordinate.latitude, longitude: selectedQuest.coordinate.longitude)
                parent.inferStreetName(location: annotationLocation) { streetName in
                    if let streetName = streetName {
                        if let sidewalk =  self.parent.selectedQuest?.parent as? SideWalkWidth {
                            contextualString = "The Sidewalk is along \(streetName == "" ? "the street" : streetName) at \(distance) meters"
                        } else {
                            contextualString = "The \(selectedQuest.title!) is on \(streetName == "" ? "the street" : streetName) at \(distance) meters"
                        }
                        self.contextualInfo?(contextualString)
                    } 
                }
            }
            // Deselect the annotation to prevent re-adding on selection
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        // Customizes the appearance of the annotation view
        private func customizeAnnotationView(_ annotationView: MKAnnotationView?, with displayUnitAnnotation: DisplayUnitAnnotation) {
            guard let annotationView = annotationView else { return }
            
            let pinImage = displayUnitAnnotation.displayUnit.parent?.icon
            let size = CGSize(width: 40, height: 40)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            // To draw circular border
            if let context = UIGraphicsGetCurrentContext() {
                let borderRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                let borderWidth: CGFloat = 2.0
                context.setStrokeColor(UIColor.white.cgColor)
                context.setLineWidth(borderWidth)
                context.strokeEllipse(in: borderRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
                
                // To draw the pinImage inside the circular border
                let imageRect = borderRect.insetBy(dx: borderWidth, dy: borderWidth)
                pinImage?.draw(in: imageRect)
            }
            
            // Getting the resized image with circular border
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
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
        /// Extracting coordinates of existing annotations
        let existingCoordinates = Set(mapView.annotations.compactMap { ($0 as? DisplayUnitAnnotation)?.coordinate })
        let newAnnotations = items.map { $0.annotation }
        let newCoordinates = Set(newAnnotations.map { $0.coordinate })
        /// Checking if the coordinates of existing annotations are different from the coordinates of new annotations
        if existingCoordinates != newCoordinates {
            /// to reset isRegionSet value whenever region changes.
                context.coordinator.isRegionSet = false
            /// Removing annotations that are not present in the new set
            let annotationsToRemove = mapView.annotations.filter {
                guard let displayUnitAnnotation = $0 as? DisplayUnitAnnotation else { return false }
                return !newCoordinates.contains(displayUnitAnnotation.coordinate)
            }
            mapView.removeAnnotations(annotationsToRemove)
            /// Adding annotations that are present in the new set but not in the existing set
            let annotationsToAdd = newAnnotations.filter { !existingCoordinates.contains($0.coordinate) }
            mapView.addAnnotations(annotationsToAdd)

            /// Updating the region if it hasn't been set yet
            if !context.coordinator.isRegionSet {
                mapView.setRegion(region, animated: true)
                context.coordinator.isRegionSet = true
            }
        }
    }
    
    // calculate distance between user current location and selected annotation
        func calculateDistance(selectedAnnotation: CLLocationCoordinate2D) -> CLLocationDistance {
            guard let userCurrentLocation = locationManagerDelegate.locationManager.location?.coordinate else { return CLLocationDistance(0) }
        
            let fromLocation = CLLocation(latitude: userCurrentLocation.latitude, longitude: userCurrentLocation.longitude)
            let toLocation = CLLocation(latitude: selectedAnnotation.latitude, longitude: selectedAnnotation.longitude)
            return CLLocationDistance(Int(fromLocation.distance(from: toLocation)))
        }
    
    // infer direction
    func inferDirection(selectedAnnotation: CLLocationCoordinate2D) -> String {
        guard let userCurrentLocation = locationManagerDelegate.locationManager.location?.coordinate else { return "undetermined" }
        let userLocationPoint = MKMapPoint(userCurrentLocation)
        let destinationPoint = MKMapPoint(selectedAnnotation)
        let angleRadians = atan2(destinationPoint.y - userLocationPoint.y, destinationPoint.x - userLocationPoint.x)
        var angleDegrees = angleRadians * 180 / .pi
        angleDegrees += 90
        
        if angleDegrees < 0 {
            angleDegrees += 360
        } else if angleDegrees >= 360 {
            angleDegrees -= 360
        }
        
        angleDegrees = (angleDegrees * 10).rounded() / 10
        
        var direction = ""
                
        // Convert angle into relative direction
           if angleDegrees >= 337.5 || angleDegrees < 22.5 {
               direction = "ahead"
           } else if angleDegrees >= 22.5 && angleDegrees < 112.5 {
               direction = "right"
           } else if angleDegrees >= 112.5 && angleDegrees < 202.5 {
               direction = "behind"
           } else if angleDegrees >= 202.5 && angleDegrees < 292.5 {
               direction = "left"
           } else {
               direction = "right"
           }
        
        return direction
    }
    
    // infer street name from user location coordinates
    func inferStreetName(location: CLLocation,completion: @escaping (String?) -> Void) {
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion("")
                return
            }
            var addressComponents: [String] = []
            if let streetNumber = placemark.subThoroughfare {
                addressComponents.append(streetNumber)
            }
            if let streetName = placemark.thoroughfare {
                addressComponents.append(streetName)
            }
            
            let address = addressComponents.joined(separator: ", ")
            completion(address)
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
