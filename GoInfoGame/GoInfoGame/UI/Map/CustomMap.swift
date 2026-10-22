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
    // Rendered pin images are identical for a given iconName (size never varies),
    // so cache them once per process instead of re-running Core Graphics on every
    // fresh view instance MapLibre creates when a reuse pool needs to grow.
    private static let pinIconCache = NSCache<NSString, UIImage>()

    private let imageView = UIImageView()
    private let checkmark = UIImageView()

    var isChecked: Bool = false {
        didSet { checkmark.isHidden = !isChecked }
    }

    init(reuseIdentifier: String, iconName: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        let size = CGSize(width: 36, height: 46)
        frame = CGRect(origin: .zero, size: size)

        // A bare MLNAnnotationView (a plain UIView, not a UIControl) is not an
        // accessibility element by default - without this XCUITest cannot query it as
        // one element at all, only (if anything) its subviews individually.
        isAccessibilityElement = true
        accessibilityIdentifier = A11yID.Map.questAnnotation

        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        if let raw = UIImage(named: iconName) ?? UIImage(named: "notes") {
            let cacheKey = iconName as NSString
            if let cached = QuestAnnotationView.pinIconCache.object(forKey: cacheKey) {
                imageView.image = cached
            } else {
                let pin = makePinIcon(raw, size: size)
                QuestAnnotationView.pinIconCache.setObject(pin, forKey: cacheKey)
                imageView.image = pin
            }
        } else {
            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            imageView.backgroundColor = UIColor.systemBlue
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
        }
        addSubview(imageView)

        // The pin's sharp tip sits at the bottom of its bounds — shift the view up
        // by half its height so the tip (not the center) lands on the coordinate.
        centerOffset = CGVector(dx: 0, dy: -size.height / 2)

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

// Placeholder marker for a quest hidden behind another pin at the current
// zoom level because it would otherwise visually overlap it. Sits at that
// quest's own real coordinate as a small dot; replaced by its own full pin
// once the user zooms in far enough to separate them on screen.
final class OverlapDotAnnotation: NSObject, MLNAnnotation {
    let coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

final class OverlapDotAnnotationView: MLNAnnotationView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 14, height: 14)
        layer.cornerRadius = 7
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.white.cgColor
        backgroundColor = Asset.Colors.a2A2A2Gray.color //UIColor(red: 135/255, green: 62/255, blue: 242/255, alpha: 1.0)
        // Sit behind every other annotation view (pins, clusters, temp pin —
        // all left at the default zPosition of 0) so a dot never paints over
        // a real pin that happens to land nearby on screen.
        layer.zPosition = -1
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

final class QuestClusterAnnotationView: MLNAnnotationView {
    private let label = UILabel()

    // accessibilityValue is a UI test's only way to read the cluster count XCUITest
    // cannot see the UILabel's text directly, since this view's own
    // isAccessibilityElement = true (below) makes it a leaf that does not expose its
    // subviews as separate queryable elements.
    var count: Int = 0 {
        didSet {
            label.text = "\(count)"
            accessibilityValue = "\(count)"
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        layer.cornerRadius = 22
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        backgroundColor = Asset.Colors.a2A2A2Gray.color //UIColor(red: 135/255, green: 62/255, blue: 242/255, alpha: 1.0)
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.frame = bounds
        addSubview(label)

        isAccessibilityElement = true
        accessibilityIdentifier = A11yID.Map.clusterAnnotation
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

// Draws a map-pin silhouette (round head + pointed tail, à la the "mapPoint"
// asset) with `image` clipped into a circle inside the head. The tail's tip
// lands at the bottom-center of `size` — callers anchor the view there via
// `centerOffset` so the tip, not the shape's center, marks the coordinate.
private func makePinIcon(_ image: UIImage, size: CGSize) -> UIImage {
    let borderWidth: CGFloat = 2.0
    let margin: CGFloat = borderWidth + 1
    let headRadius = (size.width - margin * 2) / 2
    let center = CGPoint(x: size.width / 2, y: margin + headRadius)
    let tipPoint = CGPoint(x: center.x, y: size.height - margin)

    // The tail attaches to the head 30° either side of straight down, and the
    // head's arc sweeps the long way around (through the top) between those
    // two points so the tail reads as a natural extension of the circle.
    let tailAngle: CGFloat = .pi / 6
    let leftAngle = CGFloat.pi / 2 + tailAngle
    let rightAngle = CGFloat.pi / 2 - tailAngle
    let leftPoint = CGPoint(x: center.x + headRadius * cos(leftAngle), y: center.y + headRadius * sin(leftAngle))
    let rightPoint = CGPoint(x: center.x + headRadius * cos(rightAngle), y: center.y + headRadius * sin(rightAngle))

    let pinPath = UIBezierPath()
    pinPath.move(to: leftPoint)
    pinPath.addArc(withCenter: center, radius: headRadius, startAngle: leftAngle, endAngle: rightAngle, clockwise: true)
    pinPath.addLine(to: tipPoint)
    pinPath.close()

    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    defer { UIGraphicsEndImageContext() }
    guard let ctx = UIGraphicsGetCurrentContext() else { return image }

    ctx.saveGState()
    pinPath.addClip()
    ctx.setFillColor(UIColor.white.cgColor)
    ctx.fill(CGRect(origin: .zero, size: size))

    let iconInset = headRadius * 0.15
    let imageRect = CGRect(
        x: center.x - headRadius + iconInset,
        y: center.y - headRadius + iconInset,
        width: (headRadius - iconInset) * 2,
        height: (headRadius - iconInset) * 2
    )
    UIBezierPath(ovalIn: imageRect).addClip()
    image.draw(in: imageRect)
    ctx.restoreGState()

    ctx.setStrokeColor(UIColor.white.cgColor)
    pinPath.lineWidth = borderWidth
    pinPath.stroke()

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
    var locationManagerDelegate = LocationManagerDelegate()

    @Binding var selectedAnnotations: Set<DisplayUnitAnnotation>
    @Binding var isMultiSelectModeEnabled: Bool
    @Binding var selectedAnnotationType: String?
    @Binding var showMultiSelectionBottomSheet: Bool
    @Binding var selectedSatelliteOption: SatelliteOption

    @Binding var lineCoordinates: [CLLocationCoordinate2D]

    var onMapViewCreated: ((MLNMapView) -> Void)?
    var contextualInfo: ((String) -> Void)?
    /// Reports meters-per-point at the map's current center/zoom whenever the camera
    /// settles, so a custom SwiftUI scale bar (see `ScaleBarView`) can stay in sync —
    /// MapLibre's built-in `MLNScaleBar` only supports one unit system at a time, so
    /// it's disabled in favor of this.
    var onMetersPerPointChanged: ((Double) -> Void)?
    /// Reports the map's current rotation (degrees clockwise from north) as the
    /// camera moves, so a custom SwiftUI compass button (see `CompassButtonView`)
    /// can rotate to match — replaces MapLibre's built-in compass, which is a
    /// bare `UIImageView` with no background chip and is pinned by UIKit
    /// margins rather than laid out inline in the SwiftUI bottom-right stack.
    var onHeadingChanged: ((Double) -> Void)?

    @Binding var tappedCoordinate: CLLocationCoordinate2D?
    @Binding var annotationCoordinate: CLLocationCoordinate2D?
    @Binding var shadowRegions: [CoordinateBounds]
    @Binding var pendingAdditionCoordinate: CLLocationCoordinate2D?

    /// The screen point of the fixed crosshair shown while Create Note/Add Feature is
    /// open (nil otherwise). While non-nil, the coordinate under it is continuously
    /// written back to `editedCoordinate` as the user drags the map.
    @Binding var pinEditAnchor: CGPoint?
    @Binding var editedCoordinate: CLLocationCoordinate2D?

    /// True while a sheet that keeps the map interactive underneath it (satellite
    /// picker, long-press action sheet, create note, add feature) is currently open.
    /// Those sheets let taps reach the map, so a new selection can otherwise try to
    /// present a second `.sheet()` on MapView while one is still up — SwiftUI can only
    /// run one such transition at a time, which leaves both stuck.
    var isAnySheetBlockingSelection: Bool = false
    /// Closes every sheet covered by `isAnySheetBlockingSelection` (not including the
    /// quest-answer sheet, which the coordinator dismisses itself via `isPresented`).
    var dismissOtherSheets: (() -> Void)?

    /// Zoom level captured just before zooming in on a selected quest; MapView restores
    /// it once the quest sheet is dismissed. `nil` when no quest-driven zoom is active.
    @Binding var previousZoomLevel: Double?
    /// Camera center captured alongside `previousZoomLevel`, so MapView can restore the
    /// whole camera (not just zoom) once the quest sheet is dismissed.
    @Binding var previousCenter: CLLocationCoordinate2D?
    /// Nudges the map so `coordinate` clears the quest sheet, called once the
    /// select-a-quest zoom/pan animation finishes.
    var ensureQuestVisibleAboveSheet: ((CLLocationCoordinate2D) -> Void)?
    /// Edge padding to use when fitting a selected way's full path in view — the
    /// bottom side accounts for the quest sheet, sized by MapView (the single source
    /// of truth for the sheet's on-screen height).
    var questPathEdgePadding: (() -> UIEdgeInsets)?

    // Larger on-disk ambient tile cache than MapLibre's 50 MB default, so panning back
    // over an area reuses cached tiles instead of re-downloading them (slow on cellular).
    private static let configureTileCache: Void = {
        MLNOfflineStorage.shared.setMaximumAmbientCacheSize(200 * 1024 * 1024) { error in
            if let error { print("Failed to set map tile cache size: \(error)") }
        }
    }()

    func makeUIView(context: Context) -> MLNMapView {
        _ = CustomMap.configureTileCache
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
        // Replaced by CompassButtonView (SwiftUI) so it can render as a proper
        // white circular button (matching the zoom/locate buttons) and sit
        // inline in the bottom-right control stack, above the zoom pill.
        // MLNCompassButton is a bare UIImageView with no background chip.
        mapView.compassView.compassVisibility = .hidden

        // Replaced by ScaleBarView (SwiftUI) — MLNScaleBar only shows one unit
        // system at a time and can't match the dual ft/m bracket style.
        mapView.showsScale = false
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
        /// The in-flight background clustering pass, cancelled as soon as a newer one starts
        /// so stale passes don't pile up on the CPU during continuous pinch/zoom.
        private var currentClusterJob: ClusterJob?
        /// Coordinate area (the viewport plus a margin) the displayed annotations were
        /// computed for. Only quests inside it are put on the map; panning outside it
        /// triggers a recluster.
        private var clusteredBounds: MLNCoordinateBounds?
        /// Annotation objects kept per quest id across data reloads, so a reload that
        /// returns the same quests doesn't make MapLibre remove and re-add every pin.
        private var annotationCache: [String: DisplayUnitAnnotation] = [:]
        /// Overlap dots kept per hidden quest id, for the same reason.
        private var overlapDotCache: [String: OverlapDotAnnotation] = [:]
        private var lastReportedMetersPerPoint: Double = 0
        private var lastReportedHeading: Double = -1
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
            reportMetersPerPoint(mapView)
            reportHeading(mapView)
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

            if annotation is OverlapDotAnnotation {
                let reuseId = "overlap-dot"
                return (mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? OverlapDotAnnotationView)
                       ?? OverlapDotAnnotationView(reuseIdentifier: reuseId)
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

            if let dot = annotation as? OverlapDotAnnotation {
                // Zoom in toward the hidden quest so it separates from the pin
                // it was overlapping and gets its own full pin.
                mapView.setCenter(dot.coordinate,
                                  zoomLevel: min(mapView.zoomLevel + 2, mapView.maximumZoomLevel),
                                  animated: true)
                return
            }

            if let quest = annotation as? DisplayUnitAnnotation {
                if parent.isMultiSelectModeEnabled {
                    handleMultiSelectAnnotation(quest)
                } else {
                    presentAfterClearingOtherSheets { [weak self] in
                        self?.handleSingleSelect(annotation: quest, coordinate: quest.coordinate)
                    }
                }
            }
        }

        /// Fires continuously while the camera is moving (drag, pinch, momentum, or
        /// programmatic animation) — the cheapest hook for keeping `editedCoordinate` in
        /// sync with the fixed crosshair while Create Note/Add Feature is open.
        func mapViewRegionIsChanging(_ mapView: MLNMapView) {
            updateEditedCoordinateIfNeeded(mapView)
            // Thresholded: each report sets MapView @State and re-evaluates its whole
            // body, which at 60 fps during a gesture was a large share of frame time.
            reportMetersPerPoint(mapView, force: false)
            reportHeading(mapView, force: false)
        }

        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            updateEditedCoordinateIfNeeded(mapView)
            reportMetersPerPoint(mapView)
            reportHeading(mapView)

            // Only quests inside `clusteredBounds` are on the map — re-run once the
            // viewport moves past it, in every regime.
            if let covered = clusteredBounds, !covered.contains(mapView.visibleCoordinateBounds) {
                scheduleRecluster()
                return
            }

            let zoom = mapView.zoomLevel
            let previousBucket = clusterBucket(for: lastClusteredZoom, mapView: mapView)
            let currentBucket  = clusterBucket(for: zoom, mapView: mapView)

            // Crossed into a different regime (density / overlap / fully individual)
            // — always re-run so the transition renders correctly.
            if previousBucket != currentBucket {
                scheduleRecluster()
                return
            }

            switch currentBucket {
            case .individual:
                // Covered area unchanged (checked above) — no work needed on pan.
                return
            case .density, .overlap:
                // Groupings only change when zoom changes, not on pure pan.
                // Skip re-cluster if zoom hasn't moved enough to change them.
                if abs(zoom - lastClusteredZoom) >= 0.5 { scheduleRecluster() }
            }
        }

        private func scheduleRecluster() {
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

        /// `force: false` skips changes under ~1%, too small to move the scale bar.
        private func reportMetersPerPoint(_ mapView: MLNMapView, force: Bool = true) {
            let metersPerPoint = mapView.metersPerPoint(atLatitude: mapView.centerCoordinate.latitude)
            let last = lastReportedMetersPerPoint
            guard metersPerPoint != last else { return }
            if !force, last > 0, abs(metersPerPoint - last) / last < 0.01 { return }
            lastReportedMetersPerPoint = metersPerPoint
            DispatchQueue.main.async { [weak self] in self?.parent.onMetersPerPointChanged?(metersPerPoint) }
        }

        /// `force: false` skips changes under 1 degree.
        private func reportHeading(_ mapView: MLNMapView, force: Bool = true) {
            let heading = mapView.direction
            let last = lastReportedHeading
            guard heading != last else { return }
            if !force, last >= 0, abs(heading - last) < 1 { return }
            lastReportedHeading = heading
            DispatchQueue.main.async { [weak self] in self?.parent.onHeadingChanged?(heading) }
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

            for annotation in currentlyDisplayedAnnotations {
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
            var cache: [String: DisplayUnitAnnotation] = [:]
            var annotations: [DisplayUnitAnnotation] = []
            for item in parent.items where !item.isHidden {
                let id = item.displayUnit.id
                let iconName = item.displayUnit.parent?.iconName
                // Reuse the existing object when its pin would look the same, pointing it
                // at the freshly built quest; otherwise (moved, or icon changed) make a new
                // one, since MapLibre doesn't observe changes on an added annotation.
                let annotation: DisplayUnitAnnotation
                if let existing = annotationCache[id],
                   existing.coordinate.latitude == item.coordinateInfo.latitude,
                   existing.coordinate.longitude == item.coordinateInfo.longitude,
                   existing.displayUnit?.parent?.iconName == iconName {
                    existing.displayUnit = item.displayUnit
                    annotation = existing
                } else {
                    annotation = item.annotation
                }
                cache[id] = annotation
                annotations.append(annotation)
            }
            annotationCache = cache
            overlapDotCache = overlapDotCache.filter { cache[$0.key] != nil }
            allQuestAnnotations = annotations
            lastClusteredZoom = -1  // Force re-cluster regardless of zoom
            refreshClusters()
        }

        // Zoom level at or above which the density-count clustering (large radius,
        // generic circle+count bubble) stops and individual pins begin.
        private let maxClusterZoom: Double = 17

        // Radius (screen points) below which two individual pins (40x40) are
        // treated as visually overlapping and one gets replaced by a small dot.
        private let overlapRadius: CGFloat = 40

        private enum ClusterBucket: Equatable {
            case density, overlap, individual
        }

        private func clusterBucket(for zoom: Double, mapView: MLNMapView) -> ClusterBucket {
            if zoom < maxClusterZoom { return .density }
            if zoom >= mapView.maximumZoomLevel { return .individual }
            return .overlap
        }

        func refreshClusters() {
            guard let mapView = mapView, mapView.bounds.width > 0 else { return }

            currentClusterJob?.cancel()
            currentClusterJob = nil
            clusterGeneration += 1
            let generation    = clusterGeneration
            lastClusteredZoom = mapView.zoomLevel

            // Only quests in (and just around) the viewport are clustered and put on the
            // map — clustering every quest in a large workspace and handing MapLibre
            // thousands of off-screen annotations is what stalled pan/zoom.
            let covered = mapView.visibleCoordinateBounds.expanded(by: 0.5)
            clusteredBounds = covered
            let annotations = allQuestAnnotations.filter { covered.contains($0.coordinate) }

            guard !annotations.isEmpty else {
                applyAnnotations([], to: mapView)
                return
            }

            // Fully zoomed in — always show every pin individually, no matter how close.
            if clusterBucket(for: mapView.zoomLevel, mapView: mapView) == .individual {
                applyAnnotations(annotations, to: mapView)
                return
            }

            // Convert to screen points on main thread (UIKit requirement), then
            // group on a background thread.
            let points = annotations.map { mapView.convert($0.coordinate, toPointTo: mapView) }
            let job = ClusterJob()
            currentClusterJob = job

            if mapView.zoomLevel < maxClusterZoom {
                // Below the cluster threshold — group into density clusters with a count bubble.
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let groups = Self.buildClusterGroups(points: points, radius: 50, job: job) else { return }
                    DispatchQueue.main.async { [weak self] in
                        guard let self, self.clusterGeneration == generation else { return }
                        self.applyAnnotations(self.makeClusterAnnotations(groups, annotations: annotations), to: self.mapView)
                    }
                }
                return
            }

            // Between the cluster threshold and max zoom — pins show individually,
            // but ones that would visually overlap leave just one real pin on
            // screen; the rest become small dots at their own real coordinate
            // until the user zooms in far enough to separate them.
            let radius = overlapRadius
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let hidden = Self.findOverlapped(points: points, radius: radius, job: job) else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.clusterGeneration == generation else { return }
                    self.applyAnnotations(self.makeOverlapAnnotations(hidden: hidden, annotations: annotations), to: self.mapView)
                }
            }
        }

        // Uses own tracking instead of mapView.annotations (which iterates MapLibre's
        // internal spatial index on the main thread and is expensive for large sets).
        // Only the difference is removed/added — pins present before and after stay put.
        private func applyAnnotations(_ annotations: [MLNAnnotation], to mapView: MLNMapView?) {
            guard let mapView else { return }
            let newIds = Set(annotations.map { ObjectIdentifier($0) })
            let oldIds = Set(currentlyDisplayedAnnotations.map { ObjectIdentifier($0) })
            let toRemove = currentlyDisplayedAnnotations.filter { !newIds.contains(ObjectIdentifier($0)) }
            let toAdd = annotations.filter { !oldIds.contains(ObjectIdentifier($0)) }
            if !toRemove.isEmpty { mapView.removeAnnotations(toRemove) }
            currentlyDisplayedAnnotations = annotations
            if !toAdd.isEmpty { mapView.addAnnotations(toAdd) }
        }

        // Pure function — safe to call off the main thread. Greedy grouping: each
        // unvisited point starts a group and absorbs later points within `radius` of the
        // group's running centroid. A spatial grid limits candidates to nearby points
        // (the centroid stays close to the seed), instead of comparing every pair.
        // Returns nil if `job` was cancelled.
        private static func buildClusterGroups(points: [CGPoint], radius: CGFloat, job: ClusterJob) -> [[Int]]? {
            let grid = PointGrid(points: points, cellSize: radius)
            var groups: [[Int]] = []
            var visited = [Bool](repeating: false, count: points.count)

            for i in 0..<points.count {
                if visited[i] { continue }
                if job.isCancelled { return nil }
                visited[i] = true

                var group = [i]
                var sumX = points[i].x
                var sumY = points[i].y

                for j in grid.indices(near: points[i], cellRadius: 2) where j > i && !visited[j] {
                    let n = CGFloat(group.count)
                    if hypot(sumX / n - points[j].x, sumY / n - points[j].y) < radius {
                        group.append(j)
                        visited[j] = true
                        sumX += points[j].x
                        sumY += points[j].y
                    }
                }
                groups.append(group)
            }
            return groups
        }

        private func makeClusterAnnotations(_ groups: [[Int]], annotations: [DisplayUnitAnnotation]) -> [MLNAnnotation] {
            groups.map { group -> MLNAnnotation in
                guard group.count > 1 else { return annotations[group[0]] }
                let members = group.map { annotations[$0] }
                let clat = members.map { $0.coordinate.latitude  }.reduce(0, +) / Double(members.count)
                let clon = members.map { $0.coordinate.longitude }.reduce(0, +) / Double(members.count)
                let cluster = CluserableDisplayUnitAnnotation(
                    id: "cluster-\(group[0])",
                    coordinate: CLLocationCoordinate2D(latitude: clat, longitude: clon)
                )
                cluster.memberAnnotations = members
                return cluster
            }
        }

        // Pure function — safe to call off the main thread. Unlike buildClusterGroups,
        // this doesn't merge overlapping quests into a single generic cluster — each
        // group keeps its first member as a real, tappable pin at its own coordinate.
        // Returns which indices are hidden behind an earlier pin (shown as dots at their
        // own real coordinate), or nil if `job` was cancelled.
        private static func findOverlapped(points: [CGPoint], radius: CGFloat, job: ClusterJob) -> Set<Int>? {
            let grid = PointGrid(points: points, cellSize: radius)
            var hidden = Set<Int>()
            var visited = [Bool](repeating: false, count: points.count)

            for i in 0..<points.count {
                if visited[i] { continue }
                if job.isCancelled { return nil }
                visited[i] = true

                for j in grid.indices(near: points[i], cellRadius: 1) where j > i && !visited[j] {
                    if hypot(points[i].x - points[j].x, points[i].y - points[j].y) < radius {
                        visited[j] = true
                        hidden.insert(j)
                    }
                }
            }
            return hidden
        }

        private func makeOverlapAnnotations(hidden: Set<Int>, annotations: [DisplayUnitAnnotation]) -> [MLNAnnotation] {
            annotations.enumerated().map { index, annotation -> MLNAnnotation in
                guard hidden.contains(index) else { return annotation }
                if let dot = overlapDotCache[annotation.id],
                   dot.coordinate.latitude == annotation.coordinate.latitude,
                   dot.coordinate.longitude == annotation.coordinate.longitude {
                    return dot
                }
                let dot = OverlapDotAnnotation(coordinate: annotation.coordinate)
                overlapDotCache[annotation.id] = dot
                return dot
            }
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

        /// While `pinEditAnchor` is set (Create Note/Add Feature is open), keeps
        /// `editedCoordinate` matching whatever coordinate currently sits under that
        /// fixed on-screen point, so it reflects the map's position at all times.
        private func updateEditedCoordinateIfNeeded(_ mapView: MLNMapView) {
            guard let anchor = parent.pinEditAnchor else { return }
            parent.editedCoordinate = mapView.convert(anchor, toCoordinateFrom: mapView)
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
            for annotation in currentlyDisplayedAnnotations {
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
            for annotation in currentlyDisplayedAnnotations {
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
            presentAfterClearingOtherSheets { [weak self] in
                self?.parent.tappedCoordinate = coordinate
            }
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

        /// Runs `present` immediately, unless another sheet with map background
        /// interaction is already up — in which case it closes that sheet first and
        /// waits out its dismiss animation before presenting. Skipping the wait when
        /// nothing is open keeps the common case (map tap, nothing else showing) snappy;
        /// running it when something is open avoids presenting a new `.sheet()` on
        /// MapView while another is still mid-transition, which otherwise leaves both
        /// stuck (old one never finishes dismissing, new one never appears).
        private func presentAfterClearingOtherSheets(_ present: @escaping () -> Void) {
            guard parent.isAnySheetBlockingSelection else {
                DispatchQueue.main.async(execute: present)
                return
            }
            DispatchQueue.main.async {
                self.parent.isPresented = false
                self.parent.dismissOtherSheets?()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: present)
            }
        }

        /// Fits the full path (plus the tapped point, in case it isn't exactly on the
        /// line) in view with padding, capping the zoom-in at 19 — unless the user was
        /// already zoomed in past 19 before selecting, in which case their closer zoom
        /// is respected instead of forcing the view back out to fit the whole path.
        private func fitPath(_ pathCoordinates: [CLLocationCoordinate2D],
                             focusCoordinate: CLLocationCoordinate2D,
                             mapView: MLNMapView,
                             previousZoom: Double) {
            var minLat = focusCoordinate.latitude, maxLat = focusCoordinate.latitude
            var minLon = focusCoordinate.longitude, maxLon = focusCoordinate.longitude
            for coordinate in pathCoordinates {
                minLat = min(minLat, coordinate.latitude)
                maxLat = max(maxLat, coordinate.latitude)
                minLon = min(minLon, coordinate.longitude)
                maxLon = max(maxLon, coordinate.longitude)
            }
            let bounds = MLNCoordinateBounds(
                sw: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
                ne: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
            )
            let padding = parent.questPathEdgePadding?()
                ?? UIEdgeInsets(top: 60, left: 40, bottom: 40, right: 40)

            mapView.setVisibleCoordinateBounds(bounds, edgePadding: padding, animated: true) {
                guard previousZoom <= 19, mapView.zoomLevel > 19 else { return }
                mapView.setZoomLevel(min(19, mapView.maximumZoomLevel), animated: true)
            }
        }

        private func handleSingleSelect(annotation: DisplayUnitAnnotation,
                                        coordinate: CLLocationCoordinate2D) {
            DispatchQueue.main.async {
                self.parent.annotationCoordinate = coordinate
                self.parent.selectedQuest = annotation.displayUnit
                self.parent.isPresented = true

                let polyline = annotation.displayUnit?.parent?.polylines
                if let polyline {
                    self.parent.lineCoordinates = polyline
                    self.parent.shouldShowPolyline = true
                } else {
                    self.parent.lineCoordinates = []
                }

                if let mapView = self.mapView {
                    // Remember the camera as it was before this quest was picked —
                    // MapView restores it once the sheet is cancelled or submitted.
                    if self.parent.previousZoomLevel == nil {
                        self.parent.previousZoomLevel = mapView.zoomLevel
                        self.parent.previousCenter = mapView.centerCoordinate
                    }
                    let previousZoom = self.parent.previousZoomLevel ?? mapView.zoomLevel

                    if let polyline, polyline.count > 1 {
                        self.fitPath(polyline, focusCoordinate: coordinate,
                                    mapView: mapView, previousZoom: previousZoom)
                    } else {
                        let targetZoom = min(19, mapView.maximumZoomLevel)
                        mapView.setCenter(coordinate, zoomLevel: targetZoom, direction: -1, animated: true) {
                            // Nudge only after the zoom/pan settles — the sheet-clearance
                            // math needs the post-zoom camera to convert coordinates correctly.
                            self.parent.ensureQuestVisibleAboveSheet?(coordinate)
                        }
                    }
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

// MARK: - Clustering Helpers

/// Cancellation flag for one background clustering pass. Set on the main thread,
/// polled from the background one.
private final class ClusterJob {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock(); cancelled = true; lock.unlock()
    }
}

/// Buckets screen points into square cells so neighbour lookups only visit nearby
/// points instead of every point.
private struct PointGrid {
    private struct Cell: Hashable { let x: Int; let y: Int }
    private let cellSize: CGFloat
    private var cells: [Cell: [Int]] = [:]

    init(points: [CGPoint], cellSize: CGFloat) {
        self.cellSize = cellSize
        for (index, point) in points.enumerated() {
            cells[cell(for: point), default: []].append(index)
        }
    }

    private func cell(for point: CGPoint) -> Cell {
        Cell(x: Int((point.x / cellSize).rounded(.down)), y: Int((point.y / cellSize).rounded(.down)))
    }

    /// Indices of points within `cellRadius` cells of `point`, in ascending order
    /// (matching the order a full scan would visit them in).
    func indices(near point: CGPoint, cellRadius: Int) -> [Int] {
        let center = cell(for: point)
        var result: [Int] = []
        for dx in -cellRadius...cellRadius {
            for dy in -cellRadius...cellRadius {
                if let bucket = cells[Cell(x: center.x + dx, y: center.y + dy)] {
                    result.append(contentsOf: bucket)
                }
            }
        }
        return result.sorted()
    }
}

private extension MLNCoordinateBounds {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude  >= sw.latitude  && coordinate.latitude  <= ne.latitude &&
        coordinate.longitude >= sw.longitude && coordinate.longitude <= ne.longitude
    }

    func contains(_ other: MLNCoordinateBounds) -> Bool {
        contains(other.sw) && contains(other.ne)
    }

    /// Grown by `fraction` of its own span on every side.
    func expanded(by fraction: Double) -> MLNCoordinateBounds {
        let latPad = (ne.latitude  - sw.latitude)  * fraction
        let lonPad = (ne.longitude - sw.longitude) * fraction
        return MLNCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: sw.latitude - latPad, longitude: sw.longitude - lonPad),
            ne: CLLocationCoordinate2D(latitude: ne.latitude + latPad, longitude: ne.longitude + lonPad)
        )
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
