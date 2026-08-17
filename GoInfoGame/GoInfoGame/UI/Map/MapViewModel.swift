//
//  MapViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 29/01/24.
//

import Foundation
import SwiftUI
import MapLibre
import CoreLocation
import osmapi

enum BBoxSource {
    case currentLocation(location: CLLocationCoordinate2D)
    case visibleRect(mapView: MLNMapView)
}

class MapViewModel: ObservableObject {

    let locationManagerDelegate = LocationManagerDelegate()
    @Published var isLoading: Bool = false
    @Published var centerCoordinate = CLLocationCoordinate2D()
    private let viewSpanDelta = 0.005
    @Published var refreshMap = UUID()
    @Published var items: [DisplayUnitWithCoordinate] = []
    @Published var selectedQuest: DisplayUnit?
    let dataSpanDistance: CLLocationDistance = 1000
    @Published var selectedAnnotaions: Set<DisplayUnitAnnotation> = []
    @Published var selectedAnnotationType: String?

    var isMultiSelectModeEnabled = false

    private let dbInstance = DatabaseConnector.shared
    private var allSattileLayers: [SatelliteServer] = []

    @Published var availableOptions: [SatelliteOption] = []
    @Published var selectedOption: SatelliteOption = .none
    @Published var showSatellitePicker: Bool = false
    @Published private(set) var syncFailedElementsCount: Int = 0
    @Published private(set) var pendingNotesCount: Int = 0
    @Published private(set) var pendingFeaturesCount: Int = 0
    let workspace: Workspace

    init(workspace: Workspace) {
        self.workspace = workspace
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            self.fetchOSMDataFor(from: .currentLocation(location: location))
        }
        locationManagerDelegate.requestLocationAuthorization()
        locationManagerDelegate.startUpdatingLocation()
        self.allSattileLayers = workspace.imageryList ?? []
        checkSyncStatus()
    }

    func checkSyncStatus() {
        self.syncFailedElementsCount = dbInstance.getChangesets(synced: false).count
        self.pendingNotesCount = dbInstance.pendingNoteDraftsCount()
        self.pendingFeaturesCount = dbInstance.pendingFeatureDraftsCount()
    }

    func sattiliteServersFor(point: CLLocationCoordinate2D) -> [SatelliteServer] {
        return allSattileLayers.filter { $0.extent.isPointInsideBoundary(point) }
    }

    func updateOptions(for center: CLLocationCoordinate2D) {
        let supported = sattiliteServersFor(point: center)
        self.availableOptions = [.none] + supported.map { SatelliteOption.wmts($0) }
    }

    func getSelectedQuest() -> DisplayUnit? {
        if isMultiSelectModeEnabled {
            let displayUnit = selectedAnnotaions.first?.displayUnit
            if let longElementQuest = displayUnit?.parent as? LongElementQuest {
                longElementQuest.questAnswersSelected = { [weak self] tags in
                    guard let self = self else { return }
                    for quest in self.selectedAnnotaions {
                        if let leq = quest.displayUnit?.parent as? LongElementQuest {
                            leq.onAnswer(answer: tags)
                        }
                    }
                    self.selectedAnnotaions.removeAll()
                    self.selectedAnnotationType = nil
                    self.isMultiSelectModeEnabled = false
                    self.selectedAnnotaions = Set<DisplayUnitAnnotation>()
                }
            }
            return displayUnit
        } else {
            if let longElementQuest = selectedQuest?.parent as? LongElementQuest {
                longElementQuest.questAnswersSelected = { [weak self] tags in
                    guard let self = self else { return }
                    longElementQuest.onAnswer(answer: tags)
                }
            }
            return selectedQuest
        }
    }

    func fetchOSMDataFor(from bboxSource: BBoxSource) {
        guard !isLoading else { return }
        isLoading = true
        let bBox: BBox
        switch bboxSource {
        case .currentLocation(let center):
            self.centerCoordinate = center
            bBox = boundingBoxAroundLocation(location: center, distance: dataSpanDistance)
        case .visibleRect(let mapView):
            bBox = boundingBoxFromVisibleMapRect(mapView: mapView)
        }

        guard let workspaceID = KeychainManager.load(key: "workspaceID") else {
            isLoading = false
            return
        }

        ApiManager.shared.performRequest(
            to: .fetchOSMElements(bBox.minLon, bBox.minLat, bBox.maxLon, bBox.maxLat, workspaceID),
            setupType: .osm,
            modelType: OSMMapDataResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                let response = Array(success.getOSMElements().values)
                self.dbInstance.saveOSMElements(response)
                let items = AppQuestManager.shared.fetchQuestsFromDB()
                DispatchQueue.main.async { [weak self, items] in
                    self?.items = items
                    self?.isLoading = false
                    if self?.items.count == 0 { self?.refreshMap = UUID() }
                }
            case .failure(let failure):
                // Keep whatever annotations are already showing — a failed background
                // refresh (e.g. no network) doesn't mean the previously loaded data is gone.
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                }
                print(failure)
            }
        }
    }

    func refreshQuests() {
        self.items = AppQuestManager.shared.fetchQuestsFromDB()
    }

    func refreshMapAfterSubmission(elementId: Int) {
        if let index = self.items.firstIndex(where: { $0.id == elementId }) {
            self.items.remove(at: index)
        }
    }

    /// Re-checks a single element against the just-merged local tags after its
    /// answers have actually synced, instead of assuming any submission means
    /// "fully answered, hide it". `getUpdatedQuest` re-runs `isApplicable` (and
    /// so `LongFormElement.isFullyAnswered`) — it returns nil once every
    /// currently-applicable question has an answer, non-nil (with fresh tags/
    /// coordinate) if the element still needs more answers.
    func refreshMapAfterAnswerSync(elementId: Int) {
        if let updated = AppQuestManager.shared.getUpdatedQuest(elementId: String(elementId)) {
            if let index = self.items.firstIndex(where: { $0.id == elementId }) {
                self.items[index] = updated
            } else {
                self.items.append(updated)
            }
        } else if let index = self.items.firstIndex(where: { $0.id == elementId }) {
            self.items.remove(at: index)
        }
    }

    func refreshMapAfterUndoSumbit(storedChangesetId: String) {
        if let newItem = AppQuestManager.shared.fetchQuestForChangeset(storedChangesetId: storedChangesetId) {
            self.items.append(newItem)
        }
    }

    func hideQuest(elementId: String, elementName: String) {
        HiddenQuestManager.shared.hideQuest(elementId: elementId, elementName: elementName, items: &items)
    }

    // MARK: – BBox helpers

    func boundingBoxFromVisibleMapRect(mapView: MLNMapView) -> BBox {
        let bounds = mapView.visibleCoordinateBounds
        return BBox(
            minLat: bounds.sw.latitude,
            maxLat: bounds.ne.latitude,
            minLon: bounds.sw.longitude,
            maxLon: bounds.ne.longitude
        )
    }

    private func boundingBoxAroundLocation(location: CLLocationCoordinate2D,
                                           distance: CLLocationDistance) -> BBox {
        let earthRadius = 6_371_000.0
        let latDelta = (distance / earthRadius) * (180.0 / .pi)
        let lonDelta = (distance / (earthRadius * cos(location.latitude * .pi / 180.0))) * (180.0 / .pi)
        return BBox(
            minLat: location.latitude - latDelta,
            maxLat: location.latitude + latDelta,
            minLon: location.longitude - lonDelta,
            maxLon: location.longitude + lonDelta
        )
    }
}
