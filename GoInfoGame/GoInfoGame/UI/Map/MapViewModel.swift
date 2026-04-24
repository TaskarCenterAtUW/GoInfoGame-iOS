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
                switch result {
                case .success(let success):
                    debugPrint("response sucess: start \(Date())")
                   let osmElements = success.getOSMElements()
                  //  print("OSM ELEMENTS ??? \(osmElements)")
                    debugPrint("saveOSMElements: start \(Date())")
                    let response = Array(osmElements.values)
                    self.dbInstance.saveOSMElements(response) // Save all where there are tags
                    debugPrint("saveOSMElements: end \(Date())")
                    debugPrint("fetchQuestsFromDB: start \(Date())")
                    let items = AppQuestManager.shared.fetchQuestsFromDB().compactMap { [weak self] displayUnitWithCoordinate in
                        // Filtering the quests to be shown in map my if the
                        let elementType = displayUnitWithCoordinate.displayUnit.parent?.elementType ?? "unknown"
                        if let _ = self?.workspace.longFormQuest?.elements.first(where: { element in
                            element.elementType == elementType
                        })?.quests.first(where: { longQuest in
                            longQuest.questType == .autoCapture
                        }) {
                            return displayUnitWithCoordinate
                        } else {
                            if displayUnitWithCoordinate.showOnlyLiDARQuest {
                                return nil
                            }
                            return displayUnitWithCoordinate
                        }
                    }
                    debugPrint("fetchQuestsFromDB: end \(Date())")
                    DispatchQueue.main.async { [weak self, items] in
                        self?.items = items
                        self?.isLoading = false
                        if self?.items.count == 0 {self?.refreshMap = UUID()}
                    }
                    debugPrint("response sucess: end \(Date())")
                case .failure(let failure):
                    DispatchQueue.main.async { [weak self] in
                        self?.items = []
                        self?.isLoading = false
                        if self?.items.count == 0 {self?.refreshMap = UUID()}
                    }
                    
                    print(failure)
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
