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
struct CoordinateBounds: Equatable {
    let sw: CLLocationCoordinate2D
    let ne: CLLocationCoordinate2D

    func overlaps(_ other: CoordinateBounds) -> Bool {
        sw.latitude  < other.ne.latitude  &&
        ne.latitude  > other.sw.latitude  &&
        sw.longitude < other.ne.longitude &&
        ne.longitude > other.sw.longitude
    }

    func union(_ other: CoordinateBounds) -> CoordinateBounds {
        CoordinateBounds(
            sw: CLLocationCoordinate2D(
                latitude:  min(sw.latitude,  other.sw.latitude),
                longitude: min(sw.longitude, other.sw.longitude)
            ),
            ne: CLLocationCoordinate2D(
                latitude:  max(ne.latitude,  other.ne.latitude),
                longitude: max(ne.longitude, other.ne.longitude)
            )
        )
    }
}

// Merge overlapping axis-aligned rectangles so GeoJSON holes never intersect.
private func mergeOverlappingBounds(_ regions: [CoordinateBounds]) -> [CoordinateBounds] {
    var result = regions
    var changed = true
    while changed {
        changed = false
        outer: for i in 0..<result.count {
            for j in (i + 1)..<result.count {
                if result[i].overlaps(result[j]) {
                    let merged = result[i].union(result[j])
                    result.remove(at: j)
                    result.remove(at: i)
                    result.insert(merged, at: i)
                    changed = true
                    break outer
                }
            }
        }
    }
    return result
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

/// Marks the coordinate a note or feature is currently being added at. Shown only
/// while the long-press action sheet or the Create Note/Add Feature sheet that
/// follows it is open, and removed as soon as that flow closes (submit or cancel).
final class TemporaryPinAnnotation: NSObject, MLNAnnotation {
    var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

final class TemporaryPinAnnotationView: MLNAnnotationView {
    private let imageView = UIImageView()

    init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        let size = CGSize(width: 32, height: 40)
        frame = CGRect(origin: .zero, size: size)

        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        imageView.image = UIImage(systemName: "mappin", withConfiguration: config)
        imageView.tintColor = Asset.Colors.ff0041Red.color
        addSubview(imageView)

        // The symbol's pointed tip sits at the bottom of its bounds — shift the view
        // up by half its height so the tip (not the center) lands on the coordinate.
        centerOffset = CGVector(dx: 0, dy: -size.height / 2)
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

// MARK: - Style Loading

// The bundled style ships with a placeholder in the Jawg tile URL (kept out of
// source control) — swap in the real token from Secrets.xcconfig/Info.plist and
// write the result to Caches, since the bundle itself isn't writable.
private func resolvedStyleURL() -> URL {
    let fallback = URL(string: "asset://map_theme/streetcomplete.json")!
    guard let bundledURL = Bundle.main.url(forResource: "streetcomplete", withExtension: "json", subdirectory: "map_theme"),
          var json = try? String(contentsOf: bundledURL, encoding: .utf8) else {
        return fallback
    }

    let token = Bundle.main.object(forInfoDictionaryKey: "JAWG_ACCESS_TOKEN") as? String ?? ""
    json = json.replacingOccurrences(of: "__JAWG_ACCESS_TOKEN__", with: token)

    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let resolvedURL = cachesURL.appendingPathComponent("streetcomplete.json")
    guard (try? json.write(to: resolvedURL, atomically: true, encoding: .utf8)) != nil else {
        return fallback
    }
    return resolvedURL
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
    @Binding var pendingAdditionCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MLNMapView {
        // Bundled StreetComplete style — shared with the Android app so both
        // platforms render the same map theme. Glyphs/sprite inside the style
        // still resolve via "asset://", which maps to the main bundle's resource
        // path regardless of where the top-level style document itself lives.
        let styleURL = resolvedStyleURL()
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.userTrackingMode = trackingMode.mlnUserTrackingMode
        mapView.compassView.compassVisibility = .adaptive
        mapView.compassViewPosition = .bottomRight
        mapView.compassViewMargins = CGPoint(x: 28, y: 218)

        mapView.showsScale = true
        mapView.scaleBarPosition = .bottomRight
        mapView.showsLogoView = false
        mapView.attributionButtonPosition = .bottomLeft
        mapView.attributionButton.tintColor = Asset.Colors.a2A2A2Gray.color

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

        if itemsChanged {
            // Items changed — full rebuild required.
            context.coordinator.previousItems = items
            context.coordinator.previousSelectedAnnotations = selectedAnnotations
            context.coordinator.previousSelectedAnnotationType = selectedAnnotationType
            context.coordinator.updateQuestAnnotations()
        } else if selectionChanged || typeChanged {
            // Only visual state changed — update existing annotation views in place.
            // This avoids a full remove/re-add of all annotations for every tap.
            context.coordinator.previousSelectedAnnotations = selectedAnnotations
            context.coordinator.previousSelectedAnnotationType = selectedAnnotationType
            context.coordinator.updateAnnotationAppearance()
        }

        // Guard each call with change detection so these don't run on every SwiftUI re-render.
        let polylineCoords = shouldShowPolyline ? lineCoordinates : []
        if polylineCoords != context.coordinator.previousLineCoordinates {
            context.coordinator.previousLineCoordinates = polylineCoords
            context.coordinator.updatePolyline(coordinates: polylineCoords)
        }

        context.coordinator.updateSatelliteOverlay(option: selectedSatelliteOption)

        if shadowRegions.count != context.coordinator.previousShadowRegions.count ||
           zip(shadowRegions, context.coordinator.previousShadowRegions).contains(where: { $0 != $1 }) {
            context.coordinator.previousShadowRegions = shadowRegions
            context.coordinator.updateShadowOverlay(regions: shadowRegions)
        }

        if pendingAdditionCoordinate != context.coordinator.previousNoteBeingAddedCoordinate {
            context.coordinator.previousNoteBeingAddedCoordinate = pendingAdditionCoordinate
            context.coordinator.updateNoteBeingAddedAnnotation(coordinate: pendingAdditionCoordinate)
        }
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
        private var currentlyDisplayedAnnotations: [MLNAnnotation] = []
        private var clusterTimer: Timer?
        private var clusterGeneration = 0
        private var lastClusteredZoom: Double = -1
        private var suppressNextDidSelect = false

        var previousLineCoordinates: [CLLocationCoordinate2D] = []
        var previousShadowRegions: [CoordinateBounds] = []
        var previousNoteBeingAddedCoordinate: CLLocationCoordinate2D?
        private var pendingAdditionAnnotation: TemporaryPinAnnotation?

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

            if annotation is TemporaryPinAnnotation {
                let reuseId = "note-being-added"
                return (mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? TemporaryPinAnnotationView)
                       ?? TemporaryPinAnnotationView(reuseIdentifier: reuseId)
            }

            if let quest = annotation as? DisplayUnitAnnotation {
                let iconName = quest.displayUnit?.parent?.iconName ?? "notes"
                let reuseId = "quest-\(iconName)"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? QuestAnnotationView)
                           ?? QuestAnnotationView(reuseIdentifier: reuseId, iconName: iconName)
                // Always apply current state — reused views may carry stale state from a
                // previous annotation that occupied the same reuse slot.
                let elementType = (quest.displayUnit?.parent as? LongElementQuest)?.elementType ?? ""
                let isSelectable = parent.selectedAnnotationType == nil ||
                                   parent.selectedAnnotationType == elementType
                view.isChecked = parent.selectedAnnotations.map(\.id).contains(quest.id)
                view.alpha     = isSelectable ? 1.0 : 0.4
                return view
            }

            return nil
        }

        func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
            mapView.deselectAnnotation(annotation, animated: false)

            // A long press on an annotation already handled the action; skip the
            // didSelect that MapLibre fires when the finger lifts.
            if suppressNextDidSelect {
                suppressNextDidSelect = false
                return
            }

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
            let zoom = mapView.zoomLevel
            let wasAbove = lastClusteredZoom >= maxClusterZoom
            let isAbove  = zoom >= maxClusterZoom

            // Individual-pin view: MapLibre culls off-screen pins internally — no work needed on pan.
            if isAbove && wasAbove { return }

            // Clustered view: clusters only change when zoom changes, not on pan.
            // Skip re-cluster if zoom hasn't moved enough to change groupings.
            if !isAbove && !wasAbove && abs(zoom - lastClusteredZoom) < 0.5 { return }

            // Zoom crossed the cluster threshold, or changed enough — schedule a re-cluster.
            clusterTimer?.invalidate()
            clusterTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
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

        // Update checkmarks and opacity on currently-visible annotation views without
        // touching the annotation list or triggering a re-cluster.
        func updateAnnotationAppearance() {
            guard let mapView = mapView else { return }
            let selectedIds = Set(parent.selectedAnnotations.map { $0.id })
            let selectedType = parent.selectedAnnotationType

            for annotation in (mapView.annotations ?? []) {
                guard let quest = annotation as? DisplayUnitAnnotation,
                      !(quest is CluserableDisplayUnitAnnotation),
                      let view = mapView.view(for: quest) as? QuestAnnotationView else { continue }
                let elementType = (quest.displayUnit?.parent as? LongElementQuest)?.elementType ?? ""
                let isSelectable = selectedType == nil || selectedType == elementType
                view.isChecked = selectedIds.contains(quest.id)
                view.alpha     = isSelectable ? 1.0 : 0.4
            }
        }

        func updateQuestAnnotations() {
            clusterTimer?.invalidate()
            let items = parent.items
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let annotations = items.filter { !$0.isHidden }.map { $0.annotation }
                DispatchQueue.main.async {
                    self.allQuestAnnotations = annotations
                    self.lastClusteredZoom = -1  // Force re-cluster regardless of zoom
                    self.refreshClusters()
                }
            }
        }

        // Zoom level at or above which all pins are shown individually (no clustering).
        private let maxClusterZoom: Double = 17

        func refreshClusters() {
            guard let mapView = mapView, mapView.bounds.width > 0 else { return }

            let annotations = allQuestAnnotations
            clusterGeneration += 1
            let generation    = clusterGeneration
            lastClusteredZoom = mapView.zoomLevel

            guard !annotations.isEmpty else {
                applyAnnotations([], to: mapView)
                return
            }

            // Past the cluster threshold — show all pins individually.
            // MapLibre culls off-screen pins itself; no background work needed.
            if mapView.zoomLevel >= maxClusterZoom {
                applyAnnotations(annotations, to: mapView)
                return
            }

            // Convert to screen points on main thread (UIKit requirement), then
            // run O(n²) grouping on a background thread.
            let points = annotations.map { mapView.convert($0.coordinate, toPointTo: mapView) }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let clustered = self.buildClusters(annotations: annotations, points: points, radius: 50)
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.clusterGeneration == generation else { return }
                    self.applyAnnotations(clustered, to: self.mapView)
                }
            }
        }

        // Uses own tracking instead of mapView.annotations (which iterates MapLibre's
        // internal spatial index on the main thread and is expensive for large sets).
        private func applyAnnotations(_ annotations: [MLNAnnotation], to mapView: MLNMapView?) {
            guard let mapView else { return }
            if !currentlyDisplayedAnnotations.isEmpty {
                mapView.removeAnnotations(currentlyDisplayedAnnotations)
            }
            currentlyDisplayedAnnotations = annotations
            if !annotations.isEmpty {
                mapView.addAnnotations(annotations)
            }
        }

        // Pure function — safe to call off the main thread.
        private func buildClusters(annotations: [DisplayUnitAnnotation],
                                   points: [CGPoint],
                                   radius: CGFloat) -> [MLNAnnotation] {
            var result: [MLNAnnotation] = []
            var visited = Set<Int>()

            for i in 0..<annotations.count {
                if visited.contains(i) { continue }
                visited.insert(i)

                var group = [annotations[i]]
                var sumX = points[i].x
                var sumY = points[i].y

                for j in (i + 1)..<annotations.count {
                    if visited.contains(j) { continue }
                    let n = CGFloat(group.count)
                    let centroidX = sumX / n
                    let centroidY = sumY / n
                    if hypot(centroidX - points[j].x, centroidY - points[j].y) < radius {
                        group.append(annotations[j])
                        visited.insert(j)
                        sumX += points[j].x
                        sumY += points[j].y
                    }
                }

                if group.count > 1 {
                    let clat = group.map { $0.coordinate.latitude  }.reduce(0, +) / Double(group.count)
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
            guard !coordinates.isEmpty else { src.shape = nil; return }

            // Build MLNPolyline off the main thread; assign to source on main thread.
            let coords = coordinates
            DispatchQueue.global(qos: .userInitiated).async {
                var mutable = coords
                let polyline = MLNPolyline(coordinates: &mutable, count: UInt(mutable.count))
                DispatchQueue.main.async { src.shape = polyline }
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

            // All geometry computation runs on a background thread.
            // Only the final src.shape assignment touches MapLibre on the main thread.
            DispatchQueue.global(qos: .userInitiated).async {
                // Merge overlapping rects so interior holes never intersect (invalid GeoJSON).
                let merged = mergeOverlappingBounds(regions)

                // Exterior ring — CCW per GeoJSON, closed, clamped to Web Mercator limits.
                var world = [
                    CLLocationCoordinate2D(latitude: -85.051129, longitude: -180), // SW
                    CLLocationCoordinate2D(latitude: -85.051129, longitude:  180), // SE
                    CLLocationCoordinate2D(latitude:  85.051129, longitude:  180), // NE
                    CLLocationCoordinate2D(latitude:  85.051129, longitude: -180), // NW
                    CLLocationCoordinate2D(latitude: -85.051129, longitude: -180)  // SW (closed)
                ]

                let holes: [MLNPolygon] = merged.map { b in
                    // Interior ring — CW per GeoJSON, closed.
                    var h = [
                        CLLocationCoordinate2D(latitude: b.sw.latitude, longitude: b.sw.longitude), // SW
                        CLLocationCoordinate2D(latitude: b.ne.latitude, longitude: b.sw.longitude), // NW
                        CLLocationCoordinate2D(latitude: b.ne.latitude, longitude: b.ne.longitude), // NE
                        CLLocationCoordinate2D(latitude: b.sw.latitude, longitude: b.ne.longitude), // SE
                        CLLocationCoordinate2D(latitude: b.sw.latitude, longitude: b.sw.longitude)  // SW (closed)
                    ]
                    return MLNPolygon(coordinates: &h, count: UInt(h.count))
                }

                let polygon = MLNPolygon(coordinates: &world,
                                         count: UInt(world.count),
                                         interiorPolygons: holes)

                DispatchQueue.main.async { src.shape = polygon }
            }
        }

        func updateNoteBeingAddedAnnotation(coordinate: CLLocationCoordinate2D?) {
            if let existing = pendingAdditionAnnotation {
                mapView?.removeAnnotation(existing)
                pendingAdditionAnnotation = nil
            }
            guard let coordinate else { return }
            let annotation = TemporaryPinAnnotation(coordinate: coordinate)
            pendingAdditionAnnotation = annotation
            mapView?.addAnnotation(annotation)
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

            // Long press near a quest annotation → enter multi-select.
            // Suppress the didSelect that MapLibre fires when the finger lifts
            // after a long press — otherwise the annotation toggles back off immediately.
            for annotation in (mapView.annotations ?? []) {
                guard let quest = annotation as? DisplayUnitAnnotation,
                      !(quest is CluserableDisplayUnitAnnotation) else { continue }
                let annotPt = mapView.convert(quest.coordinate, toPointTo: mapView)
                if hypot(point.x - annotPt.x, point.y - annotPt.y) < 30 {
                    suppressNextDidSelect = true
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
                    self.parent.shouldShowPolyline = true
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
