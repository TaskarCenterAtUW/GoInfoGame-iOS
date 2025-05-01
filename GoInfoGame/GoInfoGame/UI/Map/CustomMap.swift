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
    @Binding var trackingMode: MapUserTrackingMode
   @Binding var items: [DisplayUnitWithCoordinate]
    @Binding var selectedQuest: DisplayUnit?
    @Binding var shouldShowPolyline: Bool
    @Binding var isPresented: Bool
    @Binding var isUserSettingsPresented: Bool
    @StateObject var locationManagerDelegate = LocationManagerDelegate()
    
    @Binding var selectedAnnotations: Set<DisplayUnitAnnotation>
    @Binding var isMultiSelectModeEnabled: Bool
    @Binding var selectedAnnotationType: String?
    @Binding var showMultiSelectionBottomSheet: Bool
    
    @State var lineCoordinates: [CLLocationCoordinate2D] = []
    
    var onMapViewCreated: ((MKMapView) -> Void)?
    
    var contextualInfo: ((String) -> Void)?
    
    @Binding var useBingMaps: Bool 
    
    @Binding var tappedCoordinate: CLLocationCoordinate2D?
    
    var shadowOverlay: ShadowOverlay
        
    // Creates and configures the UIView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .standard
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        // Set user tracking mode
        mapView.userTrackingMode = trackingMode.mkUserTrackingMode
        // Hide points of interest except street names
        mapView.pointOfInterestFilter = .excludingAll
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: CustomAnnotationView.reuseIdentifier)
                
        if useBingMaps {
            let tileOverlay = BingTileOverlay()
                  tileOverlay.minimumZ = 3  // Set minimum zoom level
                  tileOverlay.maximumZ = 150 // Set maximum zoom level for better performance
            DispatchQueue.main.async {
                mapView.addOverlay(tileOverlay, level: .aboveLabels)
            }
        }
        
        let tapGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        DispatchQueue.main.async {
            onMapViewCreated?(mapView)
        }
        
        return mapView
    }
    
    // Updates the UIView with new data
    func updateUIView(_ mapView: MKMapView, context: Context) {
        //  mapView.setCenter(userLocation, animated: true)
        if isMultiSelectModeEnabled,
           selectedAnnotations.isEmpty {
            mapView.removeAnnotations(mapView.annotations)
        }
        context.coordinator.updateUserRegion(mapView)
        context.coordinator.updateVisibleAnnotations(in: mapView)
        manageAnnotations(mapView, context: context)
        
        // Remove existing overlays
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        
        mapView.addOverlay(shadowOverlay)

        
           // Re-add overlays based on selection
           if useBingMaps {
               let tileOverlay = BingTileOverlay()
               tileOverlay.minimumZ = 3
               tileOverlay.maximumZ = 19
               mapView.addOverlay(tileOverlay, level: .aboveLabels)
           }
        
//        if useBingMaps {
//            let tileOverlay = BingTileOverlay()
//                  tileOverlay.minimumZ = 3  // Set minimum zoom level
//                  tileOverlay.maximumZ = 18 // Set maximum zoom level for better performance
//                  mapView.addOverlay(tileOverlay, level: .aboveLabels)
//        } else {
//            // If switching back to Apple Maps, remove any overlays
//            mapView.removeOverlays(mapView.overlays)
//        }
        
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
        Coordinator(self, shadowOverlay: shadowOverlay)
    }
    
    // Coordinator class for managing delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMap
        var isRegionSet = false // boolean flag to track if region has been set
        var contextualInfo: ((String) -> Void)?
        var touchStartTime: Date?
        var longPressTimer: Timer?
        var currentAnnotation: DisplayUnitAnnotation?
        var mapView: MKMapView?
        
        let shadowOverlay: ShadowOverlay
        
        var isCenteredOnUser = false
        
        private let maxZoomAltitude: CLLocationDistance = 120
        private var zoomReachedLimit: Bool = false
        
        init(_ parent: CustomMap, shadowOverlay: ShadowOverlay) {
            self.parent = parent
            self.contextualInfo = parent.contextualInfo
            self.shadowOverlay = shadowOverlay
        }
        
        @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            DispatchQueue.main.async {
                self.parent.tappedCoordinate = coordinate
            }
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
        
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            guard fullyRendered else { return }

            let userCoordinate = mapView.userLocation.coordinate
            guard CLLocationCoordinate2DIsValid(userCoordinate) else { return }

            let region = MKCoordinateRegion(center: userCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            let userLocationRect = MKMapRect(region)

            if shadowOverlay.visibleRects.isEmpty {
                shadowOverlay.addVisibleRect(userLocationRect)
                mapView.removeOverlay(shadowOverlay)
                mapView.addOverlay(shadowOverlay)
            }
        }

        
        //renders polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let routePolyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = UIColor.orange
                renderer.lineWidth = 5
                return renderer
            }
            
            if let shadowOverlay = overlay as? ShadowOverlay {
                return ShadowOverlayRenderer(overlay: shadowOverlay)
            }
            
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            
            let clusterAnnotations = MKClusterAnnotation(memberAnnotations: memberAnnotations)
            return clusterAnnotations
        }
        
        // Customizes the view for each annotation
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            self.mapView = mapView
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
            let annotationView: CustomAnnotationView
            if var dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: CustomAnnotationView.reuseIdentifier) as? CustomAnnotationView {
                annotationView = dequeuedView
                
            } else {
                annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: CustomAnnotationView.reuseIdentifier)
            }
            annotationView.clusteringIdentifier = "cluster"
            
            if let ann = annotation as? DisplayUnitAnnotation {
                if let annotationType = (ann.displayUnit.parent as? LongElementQuest)?.elementType {
                    let isSelectable = (parent.selectedAnnotationType == nil || parent.selectedAnnotationType == annotationType)
                    // Dim other annotation types
                    annotationView.alpha = isSelectable ? 1.0 : 0.5
                    annotationView.isUserInteractionEnabled = isSelectable
                }
                annotationView.updateSelectionState(isSelected: parent.selectedAnnotations.contains(ann))
            }

            // Customize annotation view
            customizeAnnotationView(annotationView, with: displayUnitAnnotation)
            // Add a touch handler
            annotationView.isDraggable = false
            annotationView.isUserInteractionEnabled = true
            annotationView.addGestureRecognizer(CustomTouchGestureRecognizer(target: self, action: #selector(handleAnnotationTouch(_:))))
            return annotationView
        }
        
        // Handles selection of annotations
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            print("did select ")
            if let annotation = annotation as? MKClusterAnnotation {
                mapView.showAnnotations(annotation.memberAnnotations, animated: true)
                
                if zoomReachedLimit && annotation.memberAnnotations.count <= 3 {
                    let firstAnnotation = annotation.memberAnnotations.first as! DisplayUnitAnnotation
                    let secondAnnotation = annotation.memberAnnotations.last as! DisplayUnitAnnotation
                    
                    if let annotation = annotation.memberAnnotations.first as? DisplayUnitAnnotation {
                        selectedAnAnnotation(selectedQuest: annotation)
                    }
                }
                
            }
            // Deselect the annotation to prevent re-adding on selection
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        func handleSelected(annotation: MKAnnotation) {
            mapView?.selectAnnotation(annotation, animated: true)
            if let annotation = annotation as? DisplayUnitAnnotation {
                if self.parent.isMultiSelectModeEnabled {
                    guard let annotationType = (annotation.displayUnit.parent as? LongElementQuest)?.elementType else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        // If nothing is selected yet, set the type
                        if self.parent.selectedAnnotationType == nil {
                            self.parent.selectedAnnotationType = annotationType
                        }
                        
                        // Allow selection only if the type matches
                        if self.parent.selectedAnnotationType == annotationType {
                            if self.parent.selectedAnnotations.contains(annotation) {
                                self.parent.selectedAnnotations.remove(annotation) // Deselect if already selected
                                self.mapView?.deselectAnnotation(annotation, animated: true)
                            } else {
                                self.parent.selectedAnnotations.insert(annotation) // Add to selection
                            }
                        }
                        
                        // Refresh annotation view to update checkmark
                        if let annotationView = self.mapView?.view(for: annotation) as? CustomAnnotationView {
                            annotationView.updateSelectionState(isSelected: self.parent.selectedAnnotations.contains(annotation))
                        }
                        
                        // If all annotations are deselected, reset type filter
                        if self.parent.selectedAnnotations.isEmpty {
                            self.parent.selectedAnnotationType = nil
                        }
                        
                        self.mapView?.deselectAnnotation(annotation, animated: true)
                        
                        // Refresh annotations to apply dimming effect
                        for ann in self.mapView?.annotations ?? [] {
                            if let view = self.mapView?.view(for: ann) as? CustomAnnotationView {
                                if let annotation = ann as? DisplayUnitAnnotation,
                                   let annType = (annotation.displayUnit.parent as? LongElementQuest)?.elementType {
                                    view.alpha = (self.parent.selectedAnnotationType == nil || self.parent.selectedAnnotationType == annType) ? 1.0 : 0.5
                                    view.isUserInteractionEnabled = (self.parent.selectedAnnotationType == nil || self.parent.selectedAnnotationType == annType)
                                    view.updateSelectionState(isSelected: self.parent.selectedAnnotations.contains(annotation))
                                }
                            }
                        }
                        if self.parent.selectedAnnotations.isEmpty {
                            self.parent.selectedAnnotationType = nil
                            self.parent.showMultiSelectionBottomSheet = false
                            self.parent.isMultiSelectModeEnabled  = false // Disable multi-select mode
                        } else {
                            self.parent.showMultiSelectionBottomSheet = true
                        }
                    }
                } else {
                    selectedAnAnnotation(selectedQuest: annotation)
                    if let mapView = mapView {
                        centerAnnotationAtTop(mapView: mapView, annotation: annotation)
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            zoomReachedLimit = mapView.isZoomedIn()
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
        
        @objc func handleAnnotationTouch(_ gesture: CustomTouchGestureRecognizer) {
            guard let annotation = gesture.annotation else { return }

            switch gesture.state {
            case .began:
                touchStartTime = Date()
                currentAnnotation = annotation
                longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
                    if let currentAnnotation = self?.currentAnnotation {
                        print("Long press detected on annotation: \(currentAnnotation.coordinate)")
//                        self?.parent.onAnnotationLongPress?(currentAnnotation)
                        self?.parent.isMultiSelectModeEnabled = true
                        self?.handleSelected(annotation: annotation)
                        self?.longPressTimer = nil
                        self?.touchStartTime = nil
                        self?.currentAnnotation = nil
                    }
                }
            case .ended, .cancelled:
                if let startTime = touchStartTime, let currentAnnotation = currentAnnotation {
                    let touchDuration = Date().timeIntervalSince(startTime)
                    if touchDuration < 0.5 {
                        print("Tap detected on annotation: \(currentAnnotation.coordinate)")
                        self.handleSelected(annotation: annotation)
                    }
                }
                touchStartTime = nil
                currentAnnotation = nil
                longPressTimer?.invalidate()
                longPressTimer = nil
            default:
                break
            }
        }
    }
    
    // Helper method to manage annotations
    private func manageAnnotations(_ mapView: MKMapView, context: Context) {
        
        let existingCoordinates = mapView.annotations.compactMap {
             ($0 as? DisplayUnitAnnotation)?.coordinate
         }
        
         // Check for modals or settings before changing map
         if isPresented  {
             return
         }

         // ✅ Only if no annotations and safe state
//        if existingCoordinates.count == 0 {
//             mapView.setCenter(userLocation, animated: true)
//         }

        context.coordinator.isRegionSet = true
        
        
        let visibleAnnotations = items
               .filter { !$0.isHidden }
               .map { $0.annotation }
        
        if (existingCoordinates.isEmpty) {
           // print("Adding annotations completely")
            
//            for (index, annotation) in annotations.enumerated() {
//                annotation.coordinate = adjustCoordinateForOverlap(annotation.coordinate, with: index)
//            }
            mapView.addAnnotations(visibleAnnotations)
        }
        
        let currentAnnotations = Set(mapView.annotations.compactMap { $0 as? DisplayUnitAnnotation })
        
        let currentVisibleAnnotations = items
               .filter { !$0.isHidden }
               .map { $0.annotation }
        
        let newAnnotations = Set(currentVisibleAnnotations)
        
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


class CustomAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "CustomAnnotationView"
    
    private var checkmarkImageView: UIImageView?

    override func prepareForReuse() {
        super.prepareForReuse()
        removeCheckmark()
    }

    // Show or remove the checkmark based on selection
    func updateSelectionState(isSelected: Bool) {
        if isSelected {
            addCheckmark()
        } else {
            removeCheckmark()
        }
    }

    private func addCheckmark() {
        if checkmarkImageView == nil {
            let checkmarkImage = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.purple, renderingMode: .alwaysOriginal)
            let imageView = UIImageView(image: checkmarkImage)
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = (checkmarkImage?.size.width ?? 0.0) / 2.0
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: topAnchor, constant:0),
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 10),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                imageView.heightAnchor.constraint(equalToConstant: 24)
            ])

            checkmarkImageView = imageView
        }
    }

    private func removeCheckmark() {
        checkmarkImageView?.removeFromSuperview()
        checkmarkImageView = nil
    }
}

class CustomTouchGestureRecognizer: UIGestureRecognizer {
    weak var annotation: DisplayUnitAnnotation?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
        if let view = view as? CustomAnnotationView, let annotation = view.annotation as? DisplayUnitAnnotation {
            self.annotation = annotation
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}

