//
//  CustomMap.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/03/24.
//

import Foundation
import SwiftUI
import MapKit
import osmparser

// Custom Map for managing map interactions between SwiftUI and UIKit components
struct CustomMap: UIViewRepresentable {
    
    var region: MKCoordinateRegion
    var userLocation = CLLocationCoordinate2D(latitude: 17.4700, longitude: 78.3534)
    @Binding var trackingMode: MapUserTrackingMode
    var items: [DisplayUnitWithCoordinate]
    @Binding var selectedQuest: DisplayUnit?
    @Binding var shouldShowPolyline: Bool
    @Binding var isPresented: Bool
    @StateObject var locationManagerDelegate = LocationManagerDelegate()
    
    
    @State var lineCoordinates: [CLLocationCoordinate2D] = []
    
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
        //  mapView.setCenter(userLocation, animated: true)
        context.coordinator.updateUserRegion(mapView)
        context.coordinator.updateVisibleAnnotations(in: mapView)
        manageAnnotations(mapView, context: context)
        
        if shouldShowPolyline {
            if !lineCoordinates.isEmpty {
                let polyline = MKPolyline(coordinates: lineCoordinates, count: lineCoordinates.count)
                mapView.addOverlay(polyline)
            }
        } else {
            mapView.overlays.forEach { overlay in
                if overlay is MKPolyline {
                    mapView.removeOverlay(overlay)
                }
            }
        }
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
        
        // Helper method to update the region
        func updateUserRegion(_ mapView: MKMapView) {
            // Update the region only if it hasn't been set yet
            if self.parent.isPresented  {
                return
            } else if !isRegionSet {
                mapView.setRegion(parent.region, animated: true)
                isRegionSet = true
            }
        }
        // To keep the selected annotation visible at the top
              func centerAnnotationAtTop(mapView: MKMapView, annotation: MKAnnotation) {
                  let coordinate = annotation.coordinate
                  var newRegion = mapView.region
                  let offsetLatitude = newRegion.span.latitudeDelta * 0.45
                  let newCenter = CLLocationCoordinate2D(latitude: coordinate.latitude - offsetLatitude,
                                                         longitude: coordinate.longitude)
                  newRegion.center = newCenter
                  
                  mapView.setRegion(newRegion, animated: true)
              }
        
        //renders polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let routePolyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = UIColor.orange
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            
            let clusterAnnotations = MKClusterAnnotation(memberAnnotations: memberAnnotations)
            return clusterAnnotations
        }
        
        // Customizes the view for each annotation
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            if let clusterAnnotation = annotation as? MKClusterAnnotation {
                let identifier = "cluster"
                var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if clusterView == nil {
                    clusterView = MKMarkerAnnotationView(annotation: clusterAnnotation, reuseIdentifier: identifier)
                } else {
                    clusterView?.annotation = annotation
                }
                
                clusterView?.markerTintColor = UIColor(red: 135/255, green: 62/255, blue: 242/255, alpha: 1.0)
                clusterView?.glyphText = "\(clusterAnnotation.memberAnnotations.count)"
                
                return clusterView
            }
              
                    
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
            annotationView?.clusteringIdentifier = "cluster"
            
            // Customize annotation view
            customizeAnnotationView(annotationView, with: displayUnitAnnotation)
            return annotationView
        }
        
        // Handles selection of annotations
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            print("did select ")
            if let annotation = annotation as? MKClusterAnnotation {
                let displayAnnotation = annotation.memberAnnotations.first as! DisplayUnitAnnotation
                selectedAnAnnotation(selectedQuest: displayAnnotation)
            } else if let annotation = annotation as? DisplayUnitAnnotation {
                selectedAnAnnotation(selectedQuest: annotation)
            }
            centerAnnotationAtTop(mapView: mapView, annotation: annotation)
            // Deselect the annotation to prevent re-adding on selection
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        private func selectedAnAnnotation(selectedQuest: DisplayUnitAnnotation) {
            parent.selectedQuest = selectedQuest.displayUnit
            parent.isPresented = true
            var contextualString = ""
            let distance = Int(parent.calculateDistance(selectedAnnotation: selectedQuest.coordinate))
            // let direction = parent.inferDirection(selectedAnnotation: selectedQuest.coordinate)
            
            let annotationLocation = CLLocation(latitude: selectedQuest.coordinate.latitude, longitude: selectedQuest.coordinate.longitude)
            
            var polylineCoords: [CLLocationCoordinate2D] = []
            if let wayElement = selectedQuest.displayUnit.parent?.relationData as? Way {
                for eachWay in wayElement.polyline {
                    let eachCoord = CLLocationCoordinate2D(latitude: eachWay.latitude, longitude: eachWay.longitude)
                    polylineCoords.append(eachCoord)
                }
            }
            self.parent.lineCoordinates = polylineCoords
            
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
        
        func updateVisibleAnnotations(in mapView: MKMapView) {
            let visibleRect = mapView.visibleMapRect
            for annotation in mapView.annotations {
                if let annotationView = mapView.view(for: annotation) {
                    let annotationPoint = MKMapPoint(annotation.coordinate)
                    if visibleRect.contains(annotationPoint) {
                        // Annotation is visible
                        annotationView.isAccessibilityElement = true
                    } else {
                        // Annotation is not visible
                        annotationView.isAccessibilityElement = false
                    }
                }
            }
            // Notify the accessibility system of the updated annotations
            UIAccessibility.post(notification: .layoutChanged, argument: mapView)
        }
    }
    
    // Helper method to manage annotations
    private func manageAnnotations(_ mapView: MKMapView, context: Context) {
        
        let existingCoordinates = mapView.annotations.compactMap { ($0 as? DisplayUnitAnnotation)?.coordinate }
        
        /// resetting region only when app is launched/re-launched
        if existingCoordinates.count == 0 {
            mapView.setCenter(userLocation, animated: true)
        }
        context.coordinator.isRegionSet = true
        
        
        let annotations = items.map({$0.annotation})
        
        if (existingCoordinates.isEmpty) {
            print("Adding annotations completely")
            
            for (index, annotation) in annotations.enumerated() {
                annotation.coordinate = adjustCoordinateForOverlap(annotation.coordinate, with: index)
            }
            mapView.addAnnotations(annotations)
        }
        
        let currentAnnotations = Set(mapView.annotations.compactMap { $0 as? DisplayUnitAnnotation })
        let newAnnotations = Set(items.map({$0.annotation}))
        
        let annotationsToRemove = currentAnnotations.subtracting(newAnnotations)
        let annotationsToAdd = newAnnotations.subtracting(currentAnnotations)
        
        mapView.removeAnnotations(Array(annotationsToRemove))
        mapView.addAnnotations(Array(annotationsToAdd))
    }
    
    func adjustCoordinateForOverlap(_ coordinate: CLLocationCoordinate2D, with index: Int) -> CLLocationCoordinate2D {
             let offset = 0.00002 * Double(index)
             return CLLocationCoordinate2D(latitude: coordinate.latitude + offset, longitude: coordinate.longitude + offset)
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
