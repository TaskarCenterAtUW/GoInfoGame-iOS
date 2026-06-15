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
import ClusterMap


// Custom Map for managing map interactions between SwiftUI and UIKit components
struct CustomMap: UIViewRepresentable {
    
    @Binding var region: MKCoordinateRegion
    @Binding var trackingMode: MapUserTrackingMode
   @Binding var items: [DisplayUnitWithCoordinate]
    @Binding var selectedQuest: DisplayUnit?
    @Binding var shouldShowPolyline: Bool
    @Binding var isPresented: Bool
    @Binding var isUserSettingsPresented: Bool
    var locationManagerDelegate = LocationManagerDelegate()
    
    @Binding var selectedAnnotations: Set<DisplayUnitAnnotation>
    @Binding var isMultiSelectModeEnabled: Bool
    @Binding var selectedAnnotationType: String?
    @Binding var showMultiSelectionBottomSheet: Bool
    @Binding var selectedSattiliteOption: SatelliteOption
    
    @State var lineCoordinates: [CLLocationCoordinate2D] = []
    
    var onMapViewCreated: ((MKMapView) -> Void)?
    
    var contextualInfo: ((String) -> Void)?
        
    @Binding var tappedCoordinate: CLLocationCoordinate2D?
    
    @Binding var annotationCoordinate: CLLocationCoordinate2D?
    
    @Binding var nearbyAnnotations: [DisplayUnitAnnotation]
    @Binding var showNearbyAnnotationsPicker: Bool
    
    // Distance threshold in meters for detecting nearby annotations
    var nearbyAnnotationThreshold: CLLocationDistance = 50
    
    var shadowOverlay: ShadowOverlay
        
    // Creates and configures the UIView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .standard
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Set user tracking mode
        mapView.userTrackingMode = trackingMode.mkUserTrackingMode
        // Hide points of interest except street names
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: CustomAnnotationView.reuseIdentifier)
        
        if case .wmts(let satelliteServer) = selectedSattiliteOption {
            mapView.addOverlay(WMTSSeever(satelliteServer: satelliteServer), level: .aboveLabels)
        }
        
        let tapGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        context.coordinator.mapView = mapView
        DispatchQueue.main.async {
            onMapViewCreated?(mapView)
        }
        
        return mapView
    }
    
    // Updates the UIView with new data
    func updateUIView(_ mapView: MKMapView, context: Context) {
        //  mapView.setCenter(userLocation, animated: true)
        Task {
            
            if context.coordinator.previosMultiSelectionMode != isMultiSelectModeEnabled {
                context.coordinator.previosMultiSelectionMode = isMultiSelectModeEnabled
                /*Task {*/ await manageAnnotations(mapView, context: context) /*}*/
            }
            context.coordinator.updateUserRegion(mapView)
            context.coordinator.updateVisibleAnnotations(in: mapView)
            if context.coordinator.previousAnnotations != items {
                context.coordinator.previousAnnotations = items
//                Task {
                    await manageAnnotations(mapView, context: context)
//                }
            }
        }
        
        
        
        // Remove existing overlays
        mapView.overlays.forEach {
            if !($0 is WMTSSeever) {
                mapView.removeOverlay($0)
            }
        }
        
        mapView.addOverlay(shadowOverlay)
        
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
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
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
        
        var previousAnnotations: [DisplayUnitWithCoordinate] = []
        var previosMultiSelectionMode: Bool = false
        private var annotations: [DisplayUnitAnnotation] = []
        private(set) var clusterManager: ClusterManager = ClusterManager<DisplayUnitAnnotation>(configuration: .init(maxZoomLevel: 17, minCountForClustering: 2, clusterPosition: .nearCenter))
        
        init(_ parent: CustomMap, shadowOverlay: ShadowOverlay) {
            self.parent = parent
            self.contextualInfo = parent.contextualInfo
            self.shadowOverlay = shadowOverlay
            super.init()
        }
        
        func reloadMap() async {
            guard let mapView = mapView else { return }
            async let changes = clusterManager.reload(mapViewSize: mapView.bounds.size, coordinateRegion: mapView.region)
            await applyChanges(changes)
        }
                
        @MainActor
        func applyChanges(_ difference: ClusterManager<DisplayUnitAnnotation>.Difference) {
            for annotationType in difference.removals {
                switch annotationType {
                case .annotation(let annotation):
                    annotations.removeAll(where: { $0 == annotation })
                    mapView?.removeAnnotation(annotation)
                case .cluster(let clusterAnnotation):
                    if let result = annotations.enumerated().first(where: { $0.element.id == clusterAnnotation.id.uuidString }) {
                        annotations.remove(at: result.offset)
                        mapView?.removeAnnotation(result.element)
                    }
                }
            }
            for annotationType in difference.insertions {
                switch annotationType {
                case .annotation(let annotation):
                    annotations.append(annotation)
                    mapView?.addAnnotation(annotation)
                case .cluster(let clusterAnnotation):
                    let cluster = CluserableDisplayUnitAnnotation(id: clusterAnnotation.id.uuidString,
                                                                  coordinate:  clusterAnnotation.coordinate)
                    cluster.memberAnnotations = clusterAnnotation.memberAnnotations
                    annotations.append(cluster)
                    mapView?.addAnnotation(cluster)
                }
            }
            
            // ✅ Ensure user location stays on top after clustering changes
            if let mapView = mapView {
                ensureUserLocationOnTop(mapView)
            }
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
            guard !parent.isPresented else { return }

            let center = parent.region.center
            guard CLLocationCoordinate2DIsValid(center),
                  !(center.latitude == 0 && center.longitude == 0) else { return }

            if parent.selectedAnnotations.isEmpty && !isRegionSet {
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
            if annotation is MKUserLocation {
                return nil
            }
            
            switch annotation {
            case is CluserableDisplayUnitAnnotation:
                let identifier = "Cluster"
                let annotationView = mapView.annotationView(
                    of: MKMarkerAnnotationView.self,
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
                annotationView.markerTintColor = UIColor(red: 135/255, green: 62/255, blue: 242/255, alpha: 1.0)
                annotationView.glyphText = "\((annotation as? CluserableDisplayUnitAnnotation)?.memberAnnotations.count ?? 0)"
                annotationView.displayPriority = .required
                annotationView.layer.zPosition = 100
                return annotationView
                
            case is DisplayUnitAnnotation:
                let identifier = CustomAnnotationView.reuseIdentifier
                let annotationView = mapView.annotationView(
                    of: CustomAnnotationView.self,
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
                if let ann = annotation as? DisplayUnitAnnotation {
                    if let annotationType = (ann.displayUnit?.parent as? LongElementQuest)?.elementType {
                        let isSelectable = (parent.selectedAnnotationType == nil || parent.selectedAnnotationType == annotationType)
                        annotationView.alpha = isSelectable ? 1.0 : 0.5
                        annotationView.isUserInteractionEnabled = isSelectable
                    }
                    annotationView.updateSelectionState(isSelected: parent.selectedAnnotations.contains(ann))
                }
                customizeAnnotationView(annotationView, with: annotation as! DisplayUnitAnnotation)
                annotationView.isDraggable = false
                annotationView.isUserInteractionEnabled = true
                let touchRecognizer = CustomTouchGestureRecognizer(target: self, action: #selector(handleAnnotationTouch(_:)))
                touchRecognizer.delegate = self
                annotationView.addGestureRecognizer(touchRecognizer)
                annotationView.displayPriority = .required
                annotationView.layer.zPosition = 50
                return annotationView
            default:
                return nil
            }
        }
        
        // ✅ Ensure user location is always on top
        func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            for view in views {
                if view.annotation is MKUserLocation {
                    view.layer.zPosition = 10000
                    view.displayPriority = .required
                    if let superview = view.superview {
                        superview.bringSubviewToFront(view)
                    }
                } else {
                    // Keep other annotations below user location
                    view.layer.zPosition = view.annotation is CluserableDisplayUnitAnnotation ? 100 : 50
                }
            }
            
            // Schedule a delayed check to ensure user location stays on top
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.ensureUserLocationOnTop(mapView)
            }
        }
        
        // ✅ Helper to ensure user location is always on top
        private func ensureUserLocationOnTop(_ mapView: MKMapView) {
            // Direct access to user location view is more efficient
            guard let userLocationView = mapView.view(for: mapView.userLocation) else { return }
            
            userLocationView.layer.zPosition = 10000
            userLocationView.displayPriority = .required
            
            // Force the view to be on top in the view hierarchy
            if let superview = userLocationView.superview {
                superview.bringSubviewToFront(userLocationView)
            }
        }
        
        // ✅ Handle user location updates to keep it on top (primary method)
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            ensureUserLocationOnTop(mapView)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }

            if let cluster = annotation as? CluserableDisplayUnitAnnotation {
                var zoomRect = MKMapRect.null
                for annotation in cluster.memberAnnotations {
                    let annotationPoint = MKMapPoint(annotation.coordinate)
                    let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
                    if zoomRect.isNull {
                        zoomRect = pointRect
                    } else {
                        zoomRect = zoomRect.union(pointRect)
                    }
                }

                // When members are tightly packed, the union rect is essentially a point —
                // setVisibleMapRect won't zoom in enough for clustering to break apart.
                // Force a deep camera zoom centered on the cluster so the pins separate.
                let region = MKCoordinateRegion(zoomRect)
                let tightThreshold = 0.0005 // ~55m at the equator
                if region.span.latitudeDelta < tightThreshold && region.span.longitudeDelta < tightThreshold {
                    let camera = MKMapCamera(
                        lookingAtCenter: cluster.coordinate,
                        fromDistance: 150,
                        pitch: 0,
                        heading: mapView.camera.heading
                    )
                    mapView.setCamera(camera, animated: true)
                } else {
                    let padding = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
                    mapView.setVisibleMapRect(zoomRect, edgePadding: padding, animated: true)
                }
            }
        }
        
        // Find annotations within a certain distance of a tapped point
        // If a cluster is nearby, expand it to include all member annotations
        func findNearbyAnnotations(to targetAnnotation: DisplayUnitAnnotation, threshold: CLLocationDistance = 50) -> [DisplayUnitAnnotation] {
            guard let mapView = mapView else { return [] }
            
            let targetLocation = CLLocation(
                latitude: targetAnnotation.coordinate.latitude,
                longitude: targetAnnotation.coordinate.longitude
            )
            
            var nearby: [DisplayUnitAnnotation] = []
            
            for annotation in mapView.annotations {
                // Skip the target annotation itself
                if let displayAnnotation = annotation as? DisplayUnitAnnotation,
                   displayAnnotation != targetAnnotation,
                   !(displayAnnotation is CluserableDisplayUnitAnnotation) {
                    
                    let annotationLocation = CLLocation(
                        latitude: displayAnnotation.coordinate.latitude,
                        longitude: displayAnnotation.coordinate.longitude
                    )
                    
                    let distance = targetLocation.distance(from: annotationLocation)
                    
                    if distance <= threshold {
                        nearby.append(displayAnnotation)
                    }
                }
                // If we find a cluster nearby, expand it to include all member annotations
                else if let clusterAnnotation = annotation as? CluserableDisplayUnitAnnotation,
                        clusterAnnotation != targetAnnotation {
                    
                    let clusterLocation = CLLocation(
                        latitude: clusterAnnotation.coordinate.latitude,
                        longitude: clusterAnnotation.coordinate.longitude
                    )
                    
                    let distance = targetLocation.distance(from: clusterLocation)
                    
                    if distance <= threshold {
                        // Add all member annotations from the cluster instead of the cluster itself
                        let memberAnnotations = clusterAnnotation.memberAnnotations.compactMap { $0 as? DisplayUnitAnnotation }
                        nearby.append(contentsOf: memberAnnotations)
                    }
                }
            }
            
            return nearby
        }
        
        func handleSelected(annotation: MKAnnotation) {
            mapView?.selectAnnotation(annotation, animated: true)
            if let annotation = annotation as? DisplayUnitAnnotation {
                if self.parent.isMultiSelectModeEnabled {
                    guard let annotationType = (annotation.displayUnit?.parent as? LongElementQuest)?.elementType else {
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
                                   let annType = (annotation.displayUnit?.parent as? LongElementQuest)?.elementType {
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
                    // Check for nearby annotations before selecting
                    let nearbyAnnotations = findNearbyAnnotations(to: annotation, threshold: parent.nearbyAnnotationThreshold)
                    
                    if !nearbyAnnotations.isEmpty {
                        // There are nearby annotations - show picker
                        var allAnnotations = [annotation] + nearbyAnnotations
                        allAnnotations.sort { ($0.title ?? "") < ($1.title ?? "") }
                        
                        DispatchQueue.main.async {
                            self.parent.nearbyAnnotations = allAnnotations
                            self.parent.showNearbyAnnotationsPicker = true
                        }
                    } else {
                        // No nearby annotations - select normally
                        selectedAnAnnotation(selectedQuest: annotation)
                        if let mapView = mapView {
                            centerAnnotationAtTop(mapView: mapView, annotation: annotation)
                        }
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            Task { 
                await reloadMap()
                // ✅ Ensure user location stays on top after region change
                await MainActor.run {
                    self.ensureUserLocationOnTop(mapView)
                }
            }
        }
        
        private func selectedAnAnnotation(selectedQuest: DisplayUnitAnnotation) {
            parent.annotationCoordinate = selectedQuest.coordinate
            parent.selectedQuest = selectedQuest.displayUnit
            parent.isPresented = true
            var contextualString = ""
            let distance = Int(parent.calculateDistance(selectedAnnotation: selectedQuest.coordinate))
            // let direction = parent.inferDirection(selectedAnnotation: selectedQuest.coordinate)
            
            let annotationLocation = CLLocation(latitude: selectedQuest.coordinate.latitude, longitude: selectedQuest.coordinate.longitude)
            
            if let polyline = selectedQuest.displayUnit?.parent?.polylines {
                self.parent.lineCoordinates = polyline
            } else {
                self.parent.lineCoordinates = []
            }
            
            parent.inferStreetName(location: annotationLocation) { streetName in
                if let streetName = streetName {
                    if let sidewalk =  self.parent.selectedQuest?.parent as? SideWalkWidth {
                        contextualString = "The Sidewalk is along \(streetName == "" ? "the street" : streetName) at \(distance) meters"
                    } else {
                        contextualString = "The \(selectedQuest.title ?? "") is on \(streetName == "" ? "the street" : streetName) at \(distance) meters"
                    }
                    self.contextualInfo?(contextualString)
                }
            }
        }
        
        // Customizes the appearance of the annotation view
        private func customizeAnnotationView(_ annotationView: MKAnnotationView?, with displayUnitAnnotation: DisplayUnitAnnotation) {
            guard let annotationView = annotationView else { return }
            
            let pinImage = UIImage(named: displayUnitAnnotation.displayUnit?.parent?.iconName ?? "notes")
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
        
        // Let the map's pan/zoom gestures run at the same time as our annotation touch recognizer,
        // so a touch that starts on a pin can still pan the map.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
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
            case .ended:
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
            case .cancelled:
                // Finger moved beyond the tap threshold — treat as a pan, not a tap.
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
    private func manageAnnotations(_ mapView: MKMapView, context: Context) async {
        
        await context.coordinator.clusterManager.removeAll()
        await context.coordinator.reloadMap()
//        let existingCoordinates = mapView.annotations.compactMap {
//             ($0 as? DisplayUnitAnnotation)?.coordinate
//         }
        
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
        await context.coordinator.clusterManager.add(visibleAnnotations)
        await context.coordinator.reloadMap()
    }
    
    func adjustCoordinateForOverlap(_ coordinate: CLLocationCoordinate2D, with index: Int) -> CLLocationCoordinate2D {
             let offset = 0.00002 * Double(index)
             return CLLocationCoordinate2D(latitude: coordinate.latitude + offset, longitude: coordinate.longitude + offset)
         }

    
    // calculate distance between user current location and selected annotation
    private func calculateDistance(selectedAnnotation: CLLocationCoordinate2D) -> CLLocationDistance {
            guard let userCurrentLocation = locationManagerDelegate.location?.coordinate else { return CLLocationDistance(0) }
        
            let fromLocation = CLLocation(latitude: userCurrentLocation.latitude, longitude: userCurrentLocation.longitude)
            let toLocation = CLLocation(latitude: selectedAnnotation.latitude, longitude: selectedAnnotation.longitude)
            return CLLocationDistance(Int(fromLocation.distance(from: toLocation)))
        }
    
    // infer direction
    private func inferDirection(selectedAnnotation: CLLocationCoordinate2D) -> String {
        guard let userCurrentLocation = locationManagerDelegate.location?.coordinate else { return "undetermined" }
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
    private var initialLocation: CGPoint?
    // How far the finger can drift before we treat the touch as a pan instead of a tap.
    private let movementTolerance: CGFloat = 10

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
        if let view = view as? CustomAnnotationView, let annotation = view.annotation as? DisplayUnitAnnotation {
            self.annotation = annotation
        }
        initialLocation = touches.first?.location(in: view)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let initial = initialLocation, let current = touches.first?.location(in: view) else { return }
        let dx = current.x - initial.x
        let dy = current.y - initial.y
        if dx * dx + dy * dy > movementTolerance * movementTolerance {
            state = .cancelled
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
        initialLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
        initialLocation = nil
    }
}

extension MKMapView {
    func annotationView<T: MKAnnotationView>(of type: T.Type, annotation: MKAnnotation?, reuseIdentifier: String) -> T {
        guard let annotationView = dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? T else {
            return type.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        annotationView.annotation = annotation
        return annotationView
    }
}
