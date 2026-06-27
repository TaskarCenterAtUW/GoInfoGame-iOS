//
//  CustomMap.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/03/24.
//  Migrated to MapLibre Native iOS
//

import Foundation
import SwiftUI
import MapLibre
import MapKit     // For MapUserTrackingMode
import CoreLocation

// Represents a downloaded-data bounding region for the shadow overlay
struct CoordinateBounds {
    let sw: CLLocationCoordinate2D
    let ne: CLLocationCoordinate2D
}

// MARK: - Annotation Views

final class QuestAnnotationView: MLNAnnotationView {
    private let imageView = UIImageView()
    private let checkmark = UIImageView()

    var isChecked: Bool = false {
        didSet { checkmark.isHidden = !isChecked }
    }

    init(reuseIdentifier: String, iconName: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)

        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        if let raw = UIImage(named: iconName) {
            imageView.image = makeCircularIcon(raw)
        } else {
            imageView.backgroundColor = UIColor.systemBlue
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
        }
        addSubview(imageView)

        // Checkmark badge in top-right corner
        let badgeSize: CGFloat = 16
        checkmark.frame = CGRect(x: bounds.width - badgeSize, y: -2, width: badgeSize, height: badgeSize)
        checkmark.image = UIImage(systemName: "checkmark.circle.fill")
        checkmark.tintColor = UIColor.systemGreen
        checkmark.backgroundColor = UIColor.white
        checkmark.layer.cornerRadius = badgeSize / 2
        checkmark.clipsToBounds = true
        checkmark.isHidden = true
        addSubview(checkmark)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

final class QuestClusterAnnotationView: MLNAnnotationView {
    private let label = UILabel()

    var count: Int = 0 { didSet { label.text = "\(count)" } }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        layer.cornerRadius = 22
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        backgroundColor = UIColor(red: 135/255, green: 62/255, blue: 242/255, alpha: 1.0)
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.frame = bounds
        addSubview(label)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

// MARK: - Icon Helper

private func makeCircularIcon(_ image: UIImage) -> UIImage {
    let size = CGSize(width: 40, height: 40)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    defer { UIGraphicsEndImageContext() }
    guard let ctx = UIGraphicsGetCurrentContext() else { return image }

    let rect = CGRect(origin: .zero, size: size)
    let borderWidth: CGFloat = 2.0

    ctx.setFillColor(UIColor.white.cgColor)
    ctx.fillEllipse(in: rect)

    let imageRect = rect.insetBy(dx: borderWidth + 2, dy: borderWidth + 2)
    ctx.saveGState()
    UIBezierPath(ovalIn: imageRect).addClip()
    image.draw(in: imageRect)
    ctx.restoreGState()

    ctx.setStrokeColor(UIColor.white.cgColor)
    ctx.setLineWidth(borderWidth)
    ctx.strokeEllipse(in: rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))

    return UIGraphicsGetImageFromCurrentImageContext() ?? image
}

// MARK: - CustomMap

struct CustomMap: UIViewRepresentable {

    @Binding var centerCoordinate: CLLocationCoordinate2D
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
    @Binding var selectedSatelliteOption: SatelliteOption

    @Binding var lineCoordinates: [CLLocationCoordinate2D]

    var onMapViewCreated: ((MLNMapView) -> Void)?
    var contextualInfo: ((String) -> Void)?

    @Binding var tappedCoordinate: CLLocationCoordinate2D?
    @Binding var annotationCoordinate: CLLocationCoordinate2D?
    @Binding var shadowRegions: [CoordinateBounds]

    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = URL(string: "https://tiles.openfreemap.org/styles/liberty")!
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.userTrackingMode = trackingMode.mlnUserTrackingMode
        mapView.compassView.compassVisibility = .visible

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.5
        longPress.delegate = context.coordinator
        mapView.addGestureRecognizer(longPress)

        context.coordinator.mapView = mapView

        DispatchQueue.main.async { onMapViewCreated?(mapView) }
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateUserRegion(mapView)

        let itemsChanged = context.coordinator.previousItems != items
        let selectionChanged = context.coordinator.previousSelectedAnnotations != selectedAnnotations
        let typeChanged = context.coordinator.previousSelectedAnnotationType != selectedAnnotationType

        if itemsChanged || selectionChanged || typeChanged {
            context.coordinator.previousItems = items
            context.coordinator.previousSelectedAnnotations = selectedAnnotations
            context.coordinator.previousSelectedAnnotationType = selectedAnnotationType
            context.coordinator.updateQuestAnnotations()
        }

        context.coordinator.updatePolyline(coordinates: shouldShowPolyline ? lineCoordinates : [])
        context.coordinator.updateSatelliteOverlay(option: selectedSatelliteOption)
        context.coordinator.updateShadowOverlay(regions: shadowRegions)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    class Coordinator: NSObject, MLNMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: CustomMap
        weak var mapView: MLNMapView?
        var isRegionSet = false

        var previousItems: [DisplayUnitWithCoordinate] = []
        var previousSelectedAnnotations: Set<DisplayUnitAnnotation> = []
        var previousSelectedAnnotationType: String?

        private var allQuestAnnotations: [DisplayUnitAnnotation] = []
        private var clusterTimer: Timer?

        let shadowSourceId   = "shadow-source"
        let shadowLayerId    = "shadow-layer"
        let polylineSourceId = "polyline-source"
        let polylineLayerId  = "polyline-layer"
        let wmtsSourceId     = "wmts-source"
        let wmtsLayerId      = "wmts-layer"

        private var appliedSatelliteOption: SatelliteOption = .none

        init(_ parent: CustomMap) {
            self.parent = parent
            super.init()
        }

        // MARK: MLNMapViewDelegate — Style

        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            setupShadowLayer(style: style)
            setupPolylineLayer(style: style)
            appliedSatelliteOption = .none
            updateSatelliteOverlay(option: parent.selectedSatelliteOption)
            refreshClusters()
            updateShadowOverlay(regions: parent.shadowRegions)
        }

        // MARK: MLNMapViewDelegate — Annotation Views

        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            if annotation is MLNUserLocation { return nil }

            if let cluster = annotation as? CluserableDisplayUnitAnnotation {
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: "cluster") as? QuestClusterAnnotationView)
                           ?? QuestClusterAnnotationView(reuseIdentifier: "cluster")
                view.count = cluster.memberAnnotations.count
                return view
            }

            if let cluster = annotation as? CluserableDisplayUnitAnnotation {
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: "cluster") as? QuestClusterAnnotationView)
                           ?? QuestClusterAnnotationView(reuseIdentifier: "cluster")
                view.count = cluster.memberAnnotations.count
                return view
            }

            if let quest = annotation as? DisplayUnitAnnotation {
                let iconName = quest.displayUnit?.parent?.iconName ?? "notes"
                let reuseId = "quest-\(iconName)"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? QuestAnnotationView)
                           ?? QuestAnnotationView(reuseIdentifier: reuseId, iconName: iconName)
                let elementType = (quest.displayUnit?.parent as? LongElementQuest)?.elementType ?? ""
                let isSelectable: Bool = {
                    guard let selected = parent.selectedAnnotationType else { return true }
                    return selected == elementType
                }()
                view.isChecked = parent.selectedAnnotations.contains(quest)
                view.alpha = isSelectable ? 1.0 : 0.4
                return view
            }

            return nil
        }

        func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
            mapView.deselectAnnotation(annotation, animated: false)

            if let cluster = annotation as? CluserableDisplayUnitAnnotation {
                if mapView.zoomLevel < maxClusterZoom {
                    // Zoom in toward the cluster centre.
                    mapView.setCenter(cluster.coordinate,
                                      zoomLevel: min(mapView.zoomLevel + 2, maxClusterZoom),
                                      animated: true)
                } else {
                    // Already past the cluster threshold — force individual pins to show now.
                    refreshClusters()
                }
                return
            }

            if let quest = annotation as? DisplayUnitAnnotation {
                if parent.isMultiSelectModeEnabled {
                    handleMultiSelectAnnotation(quest)
                } else {
                    handleSingleSelect(annotation: quest, coordinate: quest.coordinate)
                }
            }
        }

        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            clusterTimer?.invalidate()
            clusterTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                self?.refreshClusters()
            }
        }

        func mapViewDidFinishRenderingMap(_ mapView: MLNMapView, fullyRendered: Bool) {
            guard fullyRendered else { return }
            guard let coord = mapView.userLocation?.coordinate,
                  CLLocationCoordinate2DIsValid(coord) else { return }

            if parent.shadowRegions.isEmpty {
                let pad = 0.009
                let bounds = CoordinateBounds(
                    sw: CLLocationCoordinate2D(latitude: coord.latitude - pad, longitude: coord.longitude - pad),
                    ne: CLLocationCoordinate2D(latitude: coord.latitude + pad, longitude: coord.longitude + pad)
                )
                DispatchQueue.main.async { self.parent.shadowRegions.append(bounds) }
            }
        }

        // MARK: - Layer Setup

        private func setupShadowLayer(style: MLNStyle) {
            let src = MLNShapeSource(identifier: shadowSourceId, shape: nil, options: nil)
            style.addSource(src)
            let layer = MLNFillStyleLayer(identifier: shadowLayerId, source: src)
            layer.fillColor = NSExpression(forConstantValue: UIColor.black.withAlphaComponent(0.25))
            // Add on top so it overlays both the base map tiles and any satellite layer.
            // MLNAnnotationViews always render above all style layers.
            style.addLayer(layer)
        }

        private func setupPolylineLayer(style: MLNStyle) {
            let src = MLNShapeSource(identifier: polylineSourceId, shape: nil, options: nil)
            style.addSource(src)
            let layer = MLNLineStyleLayer(identifier: polylineLayerId, source: src)
            layer.lineColor = NSExpression(forConstantValue: UIColor.orange)
            layer.lineWidth = NSExpression(forConstantValue: 5)
            layer.lineCap  = NSExpression(forConstantValue: "round")
            layer.lineJoin = NSExpression(forConstantValue: "round")
            // Below shadow so the download-area dimming still applies over the route.
            if let shadowLayer = style.layer(withIdentifier: shadowLayerId) {
                style.insertLayer(layer, below: shadowLayer)
            } else {
                style.addLayer(layer)
            }
        }

        // MARK: - Quest Annotation Management

        func updateQuestAnnotations() {
            clusterTimer?.invalidate()
            let visibleItems = parent.items.filter { !$0.isHidden }
            allQuestAnnotations = visibleItems.map { $0.annotation }
            refreshClusters()
        }

        // Zoom level at or above which all pins are shown individually (no clustering).
        private let maxClusterZoom: Double = 17

        func refreshClusters() {
            guard let mapView = mapView, mapView.bounds.width > 0 else { return }

            let existing = (mapView.annotations ?? []).filter { $0 is DisplayUnitAnnotation }
            if !existing.isEmpty { mapView.removeAnnotations(existing) }

            guard !allQuestAnnotations.isEmpty else { return }

            let toShow: [MLNAnnotation]
            if mapView.zoomLevel >= maxClusterZoom {
                // Past the cluster threshold — show every pin individually.
                toShow = allQuestAnnotations
            } else {
                toShow = clusterAnnotations(allQuestAnnotations, in: mapView)
            }
            mapView.addAnnotations(toShow)
        }

        private func clusterAnnotations(_ annotations: [DisplayUnitAnnotation],
                                        in mapView: MLNMapView) -> [MLNAnnotation] {
            let clusterRadius: CGFloat = 50
            var result: [MLNAnnotation] = []
            var visited = Set<Int>()

            for i in 0..<annotations.count {
                if visited.contains(i) { continue }
                visited.insert(i)

                let ptI = mapView.convert(annotations[i].coordinate, toPointTo: mapView)
                var group = [annotations[i]]

                for j in (i + 1)..<annotations.count {
                    if visited.contains(j) { continue }
                    let ptJ = mapView.convert(annotations[j].coordinate, toPointTo: mapView)
                    if hypot(ptI.x - ptJ.x, ptI.y - ptJ.y) < clusterRadius {
                        group.append(annotations[j])
                        visited.insert(j)
                    }
                }

                if group.count > 1 {
                    let clat = group.map { $0.coordinate.latitude }.reduce(0, +) / Double(group.count)
                    let clon = group.map { $0.coordinate.longitude }.reduce(0, +) / Double(group.count)
                    let cluster = CluserableDisplayUnitAnnotation(
                        id: "cluster-\(i)",
                        coordinate: CLLocationCoordinate2D(latitude: clat, longitude: clon)
                    )
                    cluster.memberAnnotations = group
                    result.append(cluster)
                } else {
                    result.append(group[0])
                }
            }

            return result
        }

        // MARK: - Other Data Updates

        func updatePolyline(coordinates: [CLLocationCoordinate2D]) {
            guard let src = mapView?.style?.source(withIdentifier: polylineSourceId) as? MLNShapeSource
            else { return }
            if coordinates.isEmpty {
                src.shape = nil
            } else {
                var coords = coordinates
                src.shape = MLNPolyline(coordinates: &coords, count: UInt(coords.count))
            }
        }

        func updateSatelliteOverlay(option: SatelliteOption) {
            // Combine guards: only proceed when both the option has changed AND the style is ready.
            // Separating them caused the option to be consumed (appliedSatelliteOption updated)
            // before style was available, silently dropping the change.
            guard option != appliedSatelliteOption,
                  let style = mapView?.style else { return }

            appliedSatelliteOption = option

            if let l = style.layer(withIdentifier: wmtsLayerId)  { style.removeLayer(l) }
            if let s = style.source(withIdentifier: wmtsSourceId) { style.removeSource(s) }

            guard case .wmts(let server) = option else { return }

            // MapLibre uses {z}/{y}/{x}; ArcGIS WMTS uses {zoom}/{y}/{x}.
            let mlnURL = server.url.replacingOccurrences(of: "{zoom}", with: "{z}")

            let tileSrc = MLNRasterTileSource(
                identifier: wmtsSourceId,
                tileURLTemplates: [mlnURL],
                options: [
                    .tileSize: 256,
                    .maximumZoomLevel: NSNumber(value: server.extent.maxZoom)
                ]
            )
            style.addSource(tileSrc)

            let rasterLayer = MLNRasterStyleLayer(identifier: wmtsLayerId, source: tileSrc)
            // Insert below polyline so the route stays visible over satellite.
            // Fall back to below shadow, then top of stack.
            if let polylineLayer = style.layer(withIdentifier: polylineLayerId) {
                style.insertLayer(rasterLayer, below: polylineLayer)
            } else if let shadowLayer = style.layer(withIdentifier: shadowLayerId) {
                style.insertLayer(rasterLayer, below: shadowLayer)
            } else {
                style.addLayer(rasterLayer)
            }
        }

        func updateShadowOverlay(regions: [CoordinateBounds]) {
            guard let src = mapView?.style?.source(withIdentifier: shadowSourceId) as? MLNShapeSource,
                  !regions.isEmpty else { return }

            var worldCoords = [
                CLLocationCoordinate2D(latitude:  90, longitude: -180),
                CLLocationCoordinate2D(latitude:  90, longitude:  180),
                CLLocationCoordinate2D(latitude: -90, longitude:  180),
                CLLocationCoordinate2D(latitude: -90, longitude: -180)
            ]

            let holes: [MLNPolygon] = regions.map { b in
                var h = [
                    CLLocationCoordinate2D(latitude: b.sw.latitude, longitude: b.sw.longitude),
                    CLLocationCoordinate2D(latitude: b.ne.latitude, longitude: b.sw.longitude),
                    CLLocationCoordinate2D(latitude: b.ne.latitude, longitude: b.ne.longitude),
                    CLLocationCoordinate2D(latitude: b.sw.latitude, longitude: b.ne.longitude)
                ]
                return MLNPolygon(coordinates: &h, count: UInt(h.count))
            }

            src.shape = MLNPolygon(
                coordinates: &worldCoords,
                count: UInt(worldCoords.count),
                interiorPolygons: holes
            )
        }

        func updateUserRegion(_ mapView: MLNMapView) {
            guard !parent.isPresented, !isRegionSet else { return }
            let center = parent.centerCoordinate
            guard CLLocationCoordinate2DIsValid(center),
                  !(center.latitude == 0 && center.longitude == 0),
                  parent.selectedAnnotations.isEmpty else { return }
            mapView.setCenter(center, zoomLevel: 15, animated: true)
            isRegionSet = true
        }

        // MARK: - Gesture Handlers

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, let mapView = mapView else { return }
            let point = gesture.location(in: mapView)

            // Long press near a cluster → zoom in
            for annotation in (mapView.annotations ?? []) {
                guard let cluster = annotation as? CluserableDisplayUnitAnnotation else { continue }
                let annotPt = mapView.convert(cluster.coordinate, toPointTo: mapView)
                if hypot(point.x - annotPt.x, point.y - annotPt.y) < 30 {
                    if mapView.zoomLevel < maxClusterZoom {
                        mapView.setCenter(cluster.coordinate,
                                          zoomLevel: min(mapView.zoomLevel + 2, maxClusterZoom),
                                          animated: true)
                    } else {
                        refreshClusters()
                    }
                    return
                }
            }

            // Long press near a quest annotation → enter multi-select
            for annotation in (mapView.annotations ?? []) {
                guard let quest = annotation as? DisplayUnitAnnotation,
                      !(quest is CluserableDisplayUnitAnnotation) else { continue }
                let annotPt = mapView.convert(quest.coordinate, toPointTo: mapView)
                if hypot(point.x - annotPt.x, point.y - annotPt.y) < 30 {
                    DispatchQueue.main.async {
                        self.parent.isMultiSelectModeEnabled = true
                        self.handleMultiSelectAnnotation(quest)
                    }
                    return
                }
            }

            // Long press on empty area → add note/feature
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            DispatchQueue.main.async { self.parent.tappedCoordinate = coordinate }
        }

        // MARK: UIGestureRecognizerDelegate

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }

        // MARK: - Selection Helpers

        private func handleMultiSelectAnnotation(_ annotation: DisplayUnitAnnotation) {
            guard let annotationType = (annotation.displayUnit?.parent as? LongElementQuest)?.elementType
            else { return }

            DispatchQueue.main.async {
                if self.parent.selectedAnnotationType == nil {
                    self.parent.selectedAnnotationType = annotationType
                }
                guard self.parent.selectedAnnotationType == annotationType else { return }

                if self.parent.selectedAnnotations.contains(annotation) {
                    self.parent.selectedAnnotations.remove(annotation)
                } else {
                    self.parent.selectedAnnotations.insert(annotation)
                }

                if self.parent.selectedAnnotations.isEmpty {
                    self.parent.selectedAnnotationType = nil
                    self.parent.showMultiSelectionBottomSheet = false
                    self.parent.isMultiSelectModeEnabled = false
                } else {
                    self.parent.showMultiSelectionBottomSheet = true
                }
            }
        }

        private func handleSingleSelect(annotation: DisplayUnitAnnotation,
                                        coordinate: CLLocationCoordinate2D) {
            DispatchQueue.main.async {
                self.parent.annotationCoordinate = coordinate
                self.parent.selectedQuest = annotation.displayUnit
                self.parent.isPresented = true

                if let polyline = annotation.displayUnit?.parent?.polylines {
                    self.parent.lineCoordinates = polyline
                } else {
                    self.parent.lineCoordinates = []
                }

                if let mapView = self.mapView {
                    let bounds = mapView.visibleCoordinateBounds
                    let latSpan = bounds.ne.latitude - bounds.sw.latitude
                    let shifted = CLLocationCoordinate2D(
                        latitude: coordinate.latitude - latSpan * 0.25,
                        longitude: coordinate.longitude
                    )
                    mapView.setCenter(shifted, animated: true)
                }

                let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let distance = Int(self.distanceToUserLocation(from: coordinate))
                self.parent.inferStreetName(location: loc) { streetName in
                    let street = (streetName?.isEmpty == false) ? streetName! : "the street"
                    var info = ""
                    if let _ = annotation.displayUnit?.parent as? SideWalkWidth {
                        info = "The Sidewalk is along \(street) at \(distance) meters"
                    } else {
                        info = "The \(annotation.title ?? "") is on \(street) at \(distance) meters"
                    }
                    self.parent.contextualInfo?(info)
                }
            }
        }

        private func distanceToUserLocation(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
            guard let userCoord = parent.locationManagerDelegate.location?.coordinate else { return 0 }
            return CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }
}

// MARK: - Helpers on CustomMap

extension CustomMap {
    func inferStreetName(location: CLLocation, completion: @escaping (String?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            guard let p = placemarks?.first else { completion(""); return }
            var parts: [String] = []
            if let n = p.subThoroughfare { parts.append(n) }
            if let s = p.thoroughfare     { parts.append(s) }
            completion(parts.joined(separator: ", "))
        }
    }
}

// MARK: - MapUserTrackingMode → MLNUserTrackingMode

extension MapUserTrackingMode {
    var mlnUserTrackingMode: MLNUserTrackingMode {
        switch self {
        case .none:              return .none
        case .follow:            return .follow
        case .followWithHeading: return .followWithHeading
        default:                 return .none
        }
    }
}
