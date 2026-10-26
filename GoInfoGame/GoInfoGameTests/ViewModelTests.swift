//
//  ViewModelTests.swift
//  GoInfoGameTests
//
//  View models and map helpers: InitialViewModel (workspace list, filters, workspace quests),
//  MapViewModel (loading and refreshing pins), AccessibilityModeViewModel (nearest quests),
//  UndoEditsViewModel + QuestBase's undo handler, satellite imagery helpers.
//  All of it runs on the shared UI-test fixtures.
//

import XCTest
import Combine
import CoreLocation
@testable import GoInfoGame
@testable import osmparser

private let kondapur = CLLocationCoordinate2D(latitude: 17.4385, longitude: 78.3610)

// MARK: - InitialViewModel

@MainActor
final class InitialViewModelTests: AppTestCase {

    private var model: InitialViewModel!

    override func setUp() {
        super.setUp()
        signIn()
        MockServer.installWorkspaces(list: "WorkspacesList")
        MockHTTP.stub("GET", pathRegex: "project-group-roles/", reply: .fixture("ProjectGroupRoles"))
        MainActor.assumeIsolated { model = InitialViewModel() }
    }

    private func loadList() {
        model.fetchWorkspacesList(location: kondapur)
        XCTAssertTrue(model.isLoading)
        waitUntil("workspaces did not load") { model.workspaces != nil }
    }

    func testTheWorkspaceListLoadsAndOnlyAppEnabledOSWWorkspacesAreEligible() {
        loadList()
        XCTAssertEqual(model.workspaces?.count, 119)
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(Set(model.eligibleWorkspaces.map(\.id)), [186, 187, 222, 1758, 1595, 1765, 1857])
        XCTAssertTrue(model.eligibleWorkspaces.allSatisfy { $0.type == "osw" && $0.externalAppAccess == 1 })
    }

    func testTheRequestCarriesTheLocationAndTheToken() throws {
        loadList()
        let request = try XCTUnwrap(MockHTTP.requests(path: "/api/v1/workspaces/mine", method: "GET").first)
        XCTAssertEqual(request.header("Authorization"), "Bearer \(fixtureAccessToken)")
        let query = request.url.query ?? ""
        XCTAssertTrue(query.contains("17.4385"), query)
        XCTAssertTrue(query.contains("78.361"), query)
    }

    func testAServerErrorLeavesNoListAndAMessage() {
        MockHTTP.stub("GET", path: "/api/v1/workspaces/mine", reply: .fixture("WorkspacesServerError", status: 500))
        model.fetchWorkspacesList(location: kondapur)
        waitUntil("the failure was not reported") { model.errorMessage != nil }
        XCTAssertNil(model.workspaces)
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(model.filteredWorkspaces.isEmpty)
    }

    func testWithoutATokenNothingIsRequested() {
        _ = KeychainManager.delete(key: "accessToken")
        MockHTTP.reset()
        model.fetchWorkspacesList(location: kondapur)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(MockHTTP.requests(path: "/api/v1/workspaces/mine").isEmpty)
    }

    func testProjectGroupNamesAreFetchedAtStartup() {
        waitUntil("group names did not load") { !model.projectGroupNamesById.isEmpty }
        XCTAssertEqual(model.projectGroupDisplayName(for: "1ec1c79b-6b7a-4011-936b-c75dbbd903e3"), "AA Viewer Internal")
        XCTAssertEqual(model.projectGroupDisplayName(for: "unknown-id"), "unknown-id", "an unnamed group falls back to its id")
        XCTAssertEqual(model.projectGroupDisplayName(for: nil), "All")
    }

    func testProjectGroupRoleFailureIsNonFatal() {
        MockHTTP.stub("GET", pathRegex: "project-group-roles/", reply: .status(500))
        model.projectGroupNamesById = [:]
        model.fetchProjectGroupRoles()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertTrue(model.projectGroupNamesById.isEmpty)
    }

    func testProjectGroupRolesNeedASignedInUser() {
        waitUntil("the startup fetch did not finish") { !model.projectGroupNamesById.isEmpty }
        _ = KeychainManager.delete(key: "accessToken")
        MockHTTP.reset()
        model.fetchProjectGroupRoles()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(MockHTTP.requests(pathRegex: "project-group-roles").isEmpty)
    }

    func testFiltersNarrowTheEligibleWorkspaces() {
        loadList()
        XCTAssertEqual(model.projectGroupIds, ["1bfb55d7-f4c8-4fde-b324-472b112e471b", "1ec1c79b-6b7a-4011-936b-c75dbbd903e3"])

        model.selectedProjectGroupId = "1bfb55d7-f4c8-4fde-b324-472b112e471b"
        XCTAssertEqual(Set(model.filteredWorkspaces.map(\.id)), [1758, 1595])

        model.searchText = "  la_test_new "
        XCTAssertEqual(model.filteredWorkspaces.map(\.id), [1595], "the search is trimmed and case-insensitive")

        model.searchText = "nothing like this"
        XCTAssertTrue(model.filteredWorkspaces.isEmpty)

        model.clearFilters()
        XCTAssertEqual(model.filteredWorkspaces.count, 7)
        XCTAssertNil(model.selectedProjectGroupId)
        XCTAssertEqual(model.searchText, "")
    }

    func testReloadingTheListResetsTheFilters() {
        loadList()
        model.searchText = "kondapur"
        model.selectedProjectGroupId = "x"
        model.fetchWorkspacesList(location: kondapur)
        XCTAssertEqual(model.searchText, "")
        XCTAssertNil(model.selectedProjectGroupId)
    }

    // MARK: Workspace quests

    private func fetchQuests(_ workspaceID: String = "222") -> (ok: Bool, message: String?, workspace: Workspace?) {
        var outcome: (Bool, String?, Workspace?)?
        model.fetchLongQuestsFor(workspaceId: workspaceID) { outcome = ($0, $1, $2) }
        waitUntil("quests request did not finish") { outcome != nil }
        return (outcome!.0, outcome!.1, outcome!.2)
    }

    func testTheWorkspaceQuestsAreInstalledForTheMap() throws {
        let outcome = fetchQuests()
        XCTAssertTrue(outcome.ok)
        XCTAssertEqual(outcome.workspace?.id, 222)
        XCTAssertFalse(model.isLoading)

        let repo = QuestsRepository.shared
        XCTAssertEqual(model.longQuests.count, repo.allQuests.count)
        XCTAssertEqual(repo.allQuests.map(\.questId), (1...model.longQuests.count).map(String.init))
        XCTAssertEqual(repo.allQuests.compactMap { ($0.quest as? LongElementQuest)?.elementType }, model.longQuests.map(\.elementType))
        XCTAssertFalse(repo.featurePresets.isEmpty)
        XCTAssertEqual(repo.recencyPeriodDays, outcome.workspace?.longFormQuest?.recencyPeriod)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "workspace_overrideConflicts"))

        let saved = try XCTUnwrap(try FileStorageManager.shared.load(from: "longQuestJson") as [LongFormElement]?)
        XCTAssertEqual(saved.count, model.longQuests.count, "the definitions are cached on disk for the map")
    }

    func testReloadingReplacesThePreviousQuests() {
        _ = fetchQuests()
        let count = QuestsRepository.shared.allQuests.count
        _ = fetchQuests()
        XCTAssertEqual(QuestsRepository.shared.allQuests.count, count, "no duplicates after a second load")
    }

    func testAWorkspaceWithoutAFormIsReportedAsNotConfigured() {
        MockHTTP.stub("GET", pathRegex: #"^/api/v1/workspaces/\d+$"#, reply: .fixture("WorkspaceDetailsSingle"))
        let outcome = fetchQuests()
        XCTAssertFalse(outcome.ok)
        XCTAssertEqual(outcome.message, "Please configure longform.")
        XCTAssertFalse(model.isLoading)
    }

    func testAQuestWithAnInvalidQueryRejectsTheWorkspace() throws {
        var json = try XCTUnwrap(MockHTTP.fixtureJSON("WorkspaceDetailsWithQuests") as? [String: Any])
        var def = try XCTUnwrap(json["longFormQuestDef"] as? [String: Any])
        var elements = try XCTUnwrap(def["elements"] as? [[String: Any]])
        elements[0]["quest_query"] = "this is ((not a query"
        def["elements"] = elements
        json["longFormQuestDef"] = def
        MockHTTP.stub("GET", pathRegex: #"^/api/v1/workspaces/\d+$"#, reply: .json(try JSONSerialization.data(withJSONObject: json)))

        let outcome = fetchQuests()
        XCTAssertFalse(outcome.ok)
        XCTAssertEqual(outcome.message, "Invalid quest query.")
        XCTAssertNotNil(outcome.workspace)
        XCTAssertTrue(QuestsRepository.shared.allQuests.isEmpty)
    }

    func testAFailedWorkspaceRequestIsReported() {
        MockHTTP.stub("GET", pathRegex: #"^/api/v1/workspaces/\d+$"#, reply: .status(500))
        let outcome = fetchQuests()
        XCTAssertFalse(outcome.ok)
        XCTAssertEqual(outcome.message, "Not able to load the workspace details. Please try again later.")
        XCTAssertNil(outcome.workspace)
    }

    func testTheConflictPreferenceOfTheWorkspaceIsRemembered() throws {
        var json = try XCTUnwrap(MockHTTP.fixtureJSON("WorkspaceDetailsWithQuests") as? [String: Any])
        json["overrideConflicts"] = true
        MockHTTP.stub("GET", pathRegex: #"^/api/v1/workspaces/\d+$"#, reply: .json(try JSONSerialization.data(withJSONObject: json)))
        XCTAssertTrue(fetchQuests().ok)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "workspace_overrideConflicts"))
    }

    func testChangingWorkspaceWipesTheLocalData() {
        seedMap()
        _ = KeychainManager.save(key: "workspaceID", data: "222")

        model.checkAndDeleteWorkspaceDB(workspaceId: "222")
        XCTAssertGreaterThan(DatabaseConnector.shared.getWays(NSPredicate(value: true)).count, 0, "the same workspace keeps its data")

        model.checkAndDeleteWorkspaceDB(workspaceId: "999")
        XCTAssertEqual(DatabaseConnector.shared.getWays(NSPredicate(value: true)).count, 0)
        XCTAssertEqual(DatabaseConnector.shared.getNodes(NSPredicate(value: true)).count, 0)
        XCTAssertFalse(model.isLoading)
    }
}

// MARK: - MapViewModel

final class MapViewModelTests: AppTestCase {

    private var workspace: Workspace!
    private var model: MapViewModel!

    override func setUp() {
        super.setUp()
        workspace = loadQuestsSync()
        MockServer.installMapData()
        model = MapViewModel(workspace: workspace)
    }

    private func loadMap() {
        model.fetchOSMDataFor(from: .currentLocation(location: kondapur))
        waitUntil("the map did not load") { !model.isLoading && !model.items.isEmpty }
    }

    func testTheMapLoadsPinsForTheElementsAroundTheLocation() {
        model.fetchOSMDataFor(from: .currentLocation(location: kondapur))
        XCTAssertTrue(model.isLoading)
        waitUntil("the map did not load") { !model.isLoading }
        XCTAssertEqual(Set(model.items.map(\.id)), [121949, 409777, 409776, 409893, 900101])
        XCTAssertEqual(model.centerCoordinate.latitude, kondapur.latitude, accuracy: 1e-9)
    }

    func testTheRequestedAreaIsAKilometreAroundTheLocation() throws {
        loadMap()
        let request = try XCTUnwrap(MockHTTP.requests(path: MockServer.mapJSON).first)
        let bbox = try XCTUnwrap(URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "bbox" }?.value)
        let parts = bbox.split(separator: ",").compactMap { Double($0) }
        XCTAssertEqual(parts.count, 4)
        XCTAssertEqual(parts[0], kondapur.longitude - 0.00921, accuracy: 0.0005)   // west
        XCTAssertEqual(parts[1], kondapur.latitude - 0.00899, accuracy: 0.0005)    // south
        XCTAssertEqual(parts[2], kondapur.longitude + 0.00921, accuracy: 0.0005)   // east
        XCTAssertEqual(parts[3], kondapur.latitude + 0.00899, accuracy: 0.0005)    // north
        XCTAssertEqual(request.header("X-Workspace"), "222")
    }

    func testTheElementsAreStoredLocallyForOfflineUse() {
        loadMap()
        XCTAssertNotNil(DatabaseConnector.shared.getWay(id: 121949))
        XCTAssertNotNil(DatabaseConnector.shared.getNode(id: 900101))
    }

    func testARequestWhileLoadingIsIgnored() {
        model.fetchOSMDataFor(from: .currentLocation(location: kondapur))
        model.fetchOSMDataFor(from: .currentLocation(location: kondapur))
        waitUntil("the map did not load") { !model.isLoading }
        XCTAssertEqual(MockHTTP.requests(path: MockServer.mapJSON).count, 1)
    }

    func testWithoutAWorkspaceNothingIsRequested() {
        _ = KeychainManager.delete(key: "workspaceID")
        model.fetchOSMDataFor(from: .currentLocation(location: kondapur))
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(MockHTTP.requests(path: MockServer.mapJSON).isEmpty)
    }

    func testAFailedRefreshKeepsThePinsAlreadyShown() {
        loadMap()
        let shown = model.items.map(\.id)
        MockHTTP.stub("GET", path: MockServer.mapJSON, reply: .offline)
        model.fetchOSMDataFor(from: .currentLocation(location: kondapur))
        waitUntil("the refresh did not finish") { !model.isLoading }
        XCTAssertEqual(model.items.map(\.id), shown)
    }

    func testThePendingWorkIsCounted() {
        XCTAssertEqual(model.syncFailedElementsCount, 0)
        XCTAssertEqual(model.pendingNotesCount, 0)
        XCTAssertEqual(model.pendingFeaturesCount, 0)
        DatabaseConnector.shared.createChangeset(id: 1, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")
        model.checkSyncStatus()
        XCTAssertEqual(model.syncFailedElementsCount, 1)
    }

    // MARK: Refreshing pins

    func testASubmittedElementsPinIsRemoved() {
        loadMap()
        model.refreshMapAfterSubmission(elementId: 900101)
        XCTAssertFalse(model.items.contains { $0.id == 900101 })
        model.refreshMapAfterSubmission(elementId: 31337)   // unknown: harmless
        XCTAssertEqual(model.items.count, 4)
    }

    func testAnAnsweredElementKeepsItsPinUntilEverythingIsAnswered() {
        loadMap()
        // Sidewalk 121949 is only partly answered, so it stays; the fully answered 900001 never had a pin.
        model.refreshMapAfterAnswerSync(elementId: 121949)
        XCTAssertTrue(model.items.contains { $0.id == 121949 })
        model.refreshMapAfterAnswerSync(elementId: 900001)
        XCTAssertFalse(model.items.contains { $0.id == 900001 })
    }

    func testAnElementThatBecameCompleteLosesItsPin() {
        loadMap()
        // Answer every question of the kerb with the values the fully answered fixture element carries.
        let complete = DatabaseConnector.shared.getNode(id: 900001)?.tags.toDictionary() ?? [:]
        let kerb = DatabaseConnector.shared.getNode(id: 900101)
        XCTAssertNotNil(kerb)
        _ = DatabaseConnector.shared.addNodeTags(id: 900101, tags: complete, version: kerb?.version ?? 1)
        model.refreshMapAfterAnswerSync(elementId: 900101)
        XCTAssertFalse(model.items.contains { $0.id == 900101 })
    }

    func testRefreshingRebuildsThePinsFromTheDatabase() {
        loadMap()
        model.items = []
        model.refreshQuests()
        // The rebuild runs off the main thread, so the pins arrive asynchronously.
        waitUntil("the pins were not rebuilt") { !model.items.isEmpty }
        XCTAssertEqual(model.items.count, 5)
    }

    func testALocationUpdateInsideARecentlyFetchedAreaIsNotRefetched() {
        loadMap()
        let nearby = CLLocationCoordinate2D(latitude: kondapur.latitude + 0.001, longitude: kondapur.longitude)
        model.fetchOSMDataFor(from: .currentLocation(location: nearby))
        XCTAssertFalse(model.isLoading, "the area around a ~110 m move is already on the device")
        XCTAssertEqual(MockHTTP.requests(path: MockServer.mapJSON).count, 1)
        XCTAssertEqual(model.centerCoordinate.latitude, nearby.latitude, accuracy: 1e-9)
    }

    func testALocationUpdateOutsideTheFetchedAreaFetchesAgain() {
        loadMap()
        let farAway = CLLocationCoordinate2D(latitude: kondapur.latitude + 0.01, longitude: kondapur.longitude)
        model.fetchOSMDataFor(from: .currentLocation(location: farAway))
        XCTAssertTrue(model.isLoading)
        waitUntil("the second fetch did not finish") { !model.isLoading }
        XCTAssertEqual(MockHTTP.requests(path: MockServer.mapJSON).count, 2)
    }

    func testAHiddenQuestDisappearsFromTheMap() {
        loadMap()
        model.hideQuest(elementId: "121949-1", elementName: "Sidewalk 121949")
        XCTAssertTrue(model.items.first { $0.id == 121949 }?.isHidden ?? false)
    }

    func testAnUndoneAnswerBringsItsPinBack() throws {
        loadMap()
        let changeset = try XCTUnwrap(DatabaseConnector.shared.createChangeset(id: 900101, questType: "Kerbs", type: .node, originalTags: [:],
                                                                               tags: ["testing": "x"], version: 1, iconName: "kerb"))
        let id = changeset.id
        _ = DatabaseConnector.shared.assignChangesetId(obj: id, changesetId: 0, updatedVersion: 2)   // synced, so undoable
        model.refreshMapAfterSubmission(elementId: 900101)
        XCTAssertFalse(model.items.contains { $0.id == 900101 })

        model.refreshMapAfterUndoSumbit(storedChangesetId: id)
        XCTAssertEqual(model.items.filter { $0.id == 900101 }.count, 1, "the element is a pin again")
    }

    func testUndoingAnUnknownChangesetAddsNothing() {
        loadMap()
        let before = model.items.count
        model.refreshMapAfterUndoSumbit(storedChangesetId: "missing")
        XCTAssertEqual(model.items.count, before)
    }

    // MARK: Selection

    func testASingleSelectedQuestAnswersItself() throws {
        loadMap()
        let unit = try XCTUnwrap(model.items.first { $0.id == 900101 })
        model.selectedQuest = unit.displayUnit
        let quest = try XCTUnwrap(model.getSelectedQuest()?.parent as? LongElementQuest)
        XCTAssertNotNil(quest.questAnswersSelected, "the map wires the answer callback")
    }

    func testNothingSelectedMeansNoQuest() {
        XCTAssertNil(model.getSelectedQuest())
        model.isMultiSelectModeEnabled = true
        XCTAssertNil(model.getSelectedQuest())
    }

    // MARK: Satellite imagery

    func testImageryIsOfferedWhereItsExtentCoversTheMapCentre() {
        XCTAssertEqual(workspace.imageryList?.count, 1)
        XCTAssertEqual(model.sattiliteServersFor(point: kondapur).map(\.id), ["EsriWorldImageryClarity"])
        model.updateOptions(for: kondapur)
        XCTAssertEqual(model.availableOptions.map(\.id), ["none", "EsriWorldImageryClarity"])
        XCTAssertEqual(model.availableOptions.map(\.name), ["Default Imagery", "Esri World Imagery (Clarity) Beta"])
    }
}

// MARK: - Satellite helpers

final class SatelliteGeometryTests: XCTestCase {

    private func extent(_ ring: [[Double]]) throws -> Extent {
        let data = try JSONSerialization.data(withJSONObject: ["max_zoom": 19, "polygon": [ring]])
        return try JSONDecoder().decode(Extent.self, from: data)
    }

    func testPointsInsideAndOutsideAPolygon() throws {
        // lon/lat square around Kondapur
        let square = try extent([[78.35, 17.43], [78.37, 17.43], [78.37, 17.45], [78.35, 17.45], [78.35, 17.43]])
        XCTAssertTrue(square.isPointInsideBoundary(kondapur))
        XCTAssertFalse(square.isPointInsideBoundary(CLLocationCoordinate2D(latitude: 17.5, longitude: 78.361)))
        XCTAssertFalse(square.isPointInsideBoundary(CLLocationCoordinate2D(latitude: 17.4385, longitude: 78.4)))
        XCTAssertFalse(square.isPointInsideBoundary(CLLocationCoordinate2D(latitude: 47.6, longitude: -122.2)))
    }

    func testADegeneratePolygonContainsNothing() throws {
        XCTAssertFalse(try extent([[78.35, 17.43], [78.37, 17.43]]).isPointInsideBoundary(kondapur))
        let empty = try JSONDecoder().decode(Extent.self, from: Data(#"{"max_zoom":1,"polygon":[]}"#.utf8))
        XCTAssertFalse(empty.isPointInsideBoundary(kondapur))
    }

    func testAConcavePolygonRespectsItsNotch() throws {
        // A "C" shape open towards the east: the notch (17.44, 78.365) is outside.
        let c = try extent([[78.35, 17.43], [78.37, 17.43], [78.37, 17.437], [78.36, 17.437], [78.36, 17.443],
                            [78.37, 17.443], [78.37, 17.45], [78.35, 17.45], [78.35, 17.43]])
        XCTAssertTrue(c.isPointInsideBoundary(CLLocationCoordinate2D(latitude: 17.44, longitude: 78.355)))
        XCTAssertFalse(c.isPointInsideBoundary(CLLocationCoordinate2D(latitude: 17.44, longitude: 78.365)))
    }

    func testOptionsAreIdentifiedByTheirLayer() throws {
        let layer = try JSONDecoder().decode(SatelliteServer.self, from: JSONSerialization.data(withJSONObject: [
            "attribution": ["required": false, "text": "t", "url": "u"], "description": "d",
            "extent": ["max_zoom": 3, "polygon": []], "icon": "i", "id": "L1", "name": "Layer", "type": "xyz", "url": "https://t/{z}/{x}/{y}"]))
        XCTAssertEqual(SatelliteOption.none.id, "none")
        XCTAssertEqual(SatelliteOption.none.name, "Default Imagery")
        XCTAssertEqual(SatelliteOption.wmts(layer).id, "L1")
        XCTAssertEqual(SatelliteOption.wmts(layer).name, "Layer")
        XCTAssertEqual(SatelliteOption.wmts(layer), SatelliteOption.wmts(layer))
        XCTAssertNotEqual(SatelliteOption.wmts(layer), SatelliteOption.none)
        XCTAssertEqual(Set([SatelliteOption.none, .none, .wmts(layer)]).count, 2)
        XCTAssertFalse(layer.attribution.attributionRequired)
    }
}

// MARK: - AccessibilityModeViewModel

final class AccessibilityModeViewModelTests: AppTestCase {

    private var map: MapViewModel!
    private var model: AccessibilityModeViewModel!
    private let locationDelegate = LocationManagerDelegate()

    override func setUp() {
        super.setUp()
        let workspace = loadQuestsSync()
        seedMap("AccessibilityModeOSMElements")
        map = MapViewModel(workspace: workspace!)
        map.refreshQuests()
        waitUntil("the pins were not rebuilt") { !map.items.isEmpty }
        model = AccessibilityModeViewModel(mapViewModel: map, locationManager: locationDelegate)
    }

    func testTheNearestQuestsAreListedClosestFirst() {
        XCTAssertGreaterThanOrEqual(map.items.count, 5)
        model.filterQuestsNerestToUser(location: kondapur)
        let distances = model.nearestQuest.map(\.distance)
        XCTAssertEqual(distances, distances.sorted())
        XCTAssertLessThanOrEqual(model.nearestQuest.count, 5, "only the five closest are announced")
        XCTAssertTrue(distances.allSatisfy { $0 <= 250 })
        XCTAssertEqual(model.nearestQuest.first?.quest.id, 700001, "the sidewalk just north is the closest")
        XCTAssertEqual(model.nearestQuest.first?.direction, "North")
        XCTAssertEqual(model.nearestQuest.first?.questType, "Sidewalks")
    }

    func testTheDirectionToEachQuestIsCardinal() {
        model.filterQuestsNerestToUser(location: kondapur)
        let byID = Dictionary(uniqueKeysWithValues: model.nearestQuest.map { ($0.quest.id, $0.direction) })
        XCTAssertEqual(byID[700002], "East")
        XCTAssertEqual(byID[700003], "South")
        XCTAssertEqual(byID[700004], "West")
    }

    func testAShorterThresholdKeepsOnlyTheNearestOnes() {
        model.filterQuestsNerestToUser(location: kondapur, distanceThreshold: 60)
        XCTAssertEqual(model.nearestQuest.map(\.quest.id), [700001])
        model.filterQuestsNerestToUser(location: kondapur, distanceThreshold: 1)
        XCTAssertTrue(model.nearestQuest.isEmpty)
    }

    func testFarAwayUsersHearNothing() {
        model.filterQuestsNerestToUser(location: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3))
        XCTAssertTrue(model.nearestQuest.isEmpty)
    }

    func testHiddenQuestsAreNotAnnounced() {
        model.filterQuestsNerestToUser(location: kondapur)
        let before = model.nearestQuest.count
        guard let index = map.items.firstIndex(where: { $0.id == 700001 }) else { return XCTFail("700001 has no pin") }
        map.items[index].isHidden = true
        model.filterQuestsNerestToUser(location: kondapur)
        XCTAssertFalse(model.nearestQuest.contains { $0.quest.id == 700001 })
        XCTAssertEqual(before, 5)
        XCTAssertEqual(model.nearestQuest.count, 5, "another quest takes the hidden one's place in the top five")
    }

    func testMonitoringFollowsLocationUpdatesUntilStopped() {
        XCTAssertNil(model.lastKnownLocation)
        model.startMonitoring()
        locationDelegate.locationUpdateHandler?(kondapur)
        XCTAssertEqual(model.lastKnownLocation?.latitude, kondapur.latitude)
        XCTAssertFalse(model.nearestQuest.isEmpty)

        model.stopMonitoring()
        XCTAssertNil(locationDelegate.locationUpdateHandler)
    }

    func testQuestsAreHashedByTheirPin() {
        model.filterQuestsNerestToUser(location: kondapur)
        let set = Set(model.nearestQuest + model.nearestQuest)
        XCTAssertEqual(set.count, model.nearestQuest.count)
        XCTAssertEqual(model.distanceThreshold, 250)
    }
}

// MARK: - Location delegate

final class LocationManagerDelegateTests: XCTestCase {

    func testLocationAndHeadingUpdatesAreForwarded() {
        let delegate = LocationManagerDelegate()
        var location: CLLocationCoordinate2D?
        var heading: Double?
        delegate.locationUpdateHandler = { location = $0 }
        delegate.headingUpdateHandler = { heading = $0 }
        XCTAssertNil(delegate.coordinate)

        let manager = CLLocationManager()
        delegate.locationManager(manager, didUpdateLocations: [])
        XCTAssertNil(location, "an empty update is ignored")

        delegate.locationManager(manager, didUpdateLocations: [CLLocation(latitude: 1, longitude: 2), CLLocation(latitude: 17.4385, longitude: 78.361)])
        XCTAssertEqual(location?.latitude, 17.4385)
        XCTAssertEqual(delegate.coordinate?.longitude, 78.361)
        XCTAssertEqual(delegate.location?.coordinate.latitude, 17.4385, "the most recent fix wins")

        delegate.locationManager(manager, didFailWithError: NSError(domain: "t", code: 1))
        XCTAssertEqual(delegate.coordinate?.latitude, 17.4385, "an error keeps the last fix")
        _ = heading   // CLHeading cannot be constructed in tests; the closure is wired in the app
    }

    func testStartingAndStoppingNeverCrashWithoutPermission() {
        let delegate = LocationManagerDelegate()
        delegate.startUpdatingLocation()
        delegate.startUpdatingLocation(distanceFilter: kCLDistanceFilterNone)
        delegate.startUpdatingHeading()
        delegate.stopUpdatingHeading()
        delegate.stopUpdatingLocation()
        delegate.requestLocationAuthorization()
    }
}

// MARK: - Undo

final class UndoFlowTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private var events: SheetEvents!
    /// QuestBase wires MapUndoManager's handler weakly, so the quest has to outlive the undo.
    private var quest: LongElementQuest!

    override func setUp() {
        super.setUp()
        signIn()
        loadQuestsSync()
        seedMap("LongFormOSMElements")
        MockServer.installChangesets(changesetID: 700)
        MockServer.installLatestElements()
        events = recordSheetEvents()
        quest = LongElementQuest(questId: "1", questQuery: "ways with (footway=sidewalk)", elementType: "Sidewalks", elementTypeIcon: nil)
    }

    private func undoDoneCount() -> Int { events.names.filter { $0 == "undoDone" }.count }

    private func answerSidewalk() {
        quest.updateTags(id: 121949, questType: "Sidewalks", tags: ["ext:surface": "gravel"], type: .way, iconName: "sidewalk_surface")
        waitUntil(timeout: 10, "the answer never synced") { events.contains("synced") }
    }

    func testAWayAnswerCanBeUndone() throws {
        answerSidewalk()
        let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first)
        XCTAssertEqual(item.elementId, 121949)
        XCTAssertEqual(item.type, .way)
        XCTAssertEqual(item.questType, "Sidewalks")

        MapUndoManager.shared.undo(for: item.id)
        waitUntil(timeout: 10, "the undo never finished") { undoDoneCount() == 1 }

        XCTAssertEqual(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex, method: "POST").count, 2)
        XCTAssertTrue(MapUndoManager.shared.getUndoItems().isEmpty)
        XCTAssertTrue(events.names.suffix(3).contains("undoDone"))
        guard case .undoDone(let id)? = events.events.last(where: { SheetEvents.name($0) == "undoDone" }) else { return XCTFail() }
        XCTAssertEqual(id, item.id)
    }

    func testAFailedUndoIsReportedAndStaysUndoable() throws {
        answerSidewalk()
        let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first)

        MockServer.installChangesets(changesetID: 701, upload: .serverError)
        MapUndoManager.shared.undo(for: item.id)
        waitUntil(timeout: 10, "the failure was not reported") { events.contains("failed") }

        XCTAssertEqual(undoDoneCount(), 0)
        XCTAssertEqual(MapUndoManager.shared.getUndoItems().count, 1, "the user can try again")
    }

    func testUndoingAnUnknownEditDoesNothing() {
        MapUndoManager.shared.undo(for: "no-such-changeset")
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(events.names.isEmpty)
    }

    func testACreatedFeatureIsDeletedWhenUndone() throws {
        MockServer.installChangesets(changesetID: 900, upload: .nodeCreated(id: 555, version: 1))
        FeatureSubmissionManager.submit(FeatureDraft(presetName: "Bench", iconName: "preset_temaki_bench", tags: ["amenity": "bench"],
                                                     images: [], coordinates: kondapur))
        waitUntil(timeout: 12, "the feature never synced") { events.contains("featuresSyncFinished") }
        let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first { $0.isCreatedElement })
        XCTAssertNotNil(db.getNode(id: 555))

        MockServer.installChangesets(changesetID: 901)   // the delete upload answers a plain diffResult
        MapUndoManager.shared.undo(for: item.id)
        waitUntil(timeout: 10, "the removal was not announced") { events.contains("elementRemoved") }

        XCTAssertNil(db.getNode(id: 555), "the local copy is dropped")
        XCTAssertTrue(MapUndoManager.shared.getUndoItems().isEmpty)
        let delete = MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex, method: "POST").last
        XCTAssertTrue(delete?.bodyString.contains("<delete>") ?? false, delete?.bodyString ?? "no upload")
    }

    func testAFeatureThatCannotBeDeletedStaysUndoable() throws {
        MockServer.installChangesets(changesetID: 900, upload: .nodeCreated(id: 555, version: 1))
        FeatureSubmissionManager.submit(FeatureDraft(presetName: "Bench", iconName: "preset_temaki_bench", tags: ["amenity": "bench"],
                                                     images: [], coordinates: kondapur))
        waitUntil(timeout: 12, "the feature never synced") { events.contains("featuresSyncFinished") }
        let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first { $0.isCreatedElement })

        MockServer.installChangesets(changesetID: 902, upload: .serverError)
        MapUndoManager.shared.undo(for: item.id)
        waitUntil(timeout: 10, "the failure was not reported") { events.contains("failed") }
        XCTAssertNotNil(db.getNode(id: 555))
        XCTAssertEqual(MapUndoManager.shared.getUndoItems().count, 1)
    }

    // MARK: UndoEditsViewModel

    func testEditsAreGroupedByDay() {
        // 0 is the "synced, undoable" marker of a stored changeset.
        for changeset in [db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: ["footway": "sidewalk"], tags: ["ext:surface": "a"], version: 1, iconName: "i"),
                          db.createChangeset(id: 900101, questType: "Kerbs", type: .node, originalTags: [:], tags: ["kerb": "b"], version: 1, iconName: "i")] {
            _ = db.assignChangesetId(obj: changeset?.id ?? "", changesetId: 0, updatedVersion: 2)
        }

        // MapUndoManager reads through its own long-lived Realm, which picks up writes on the next run-loop turn.
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let viewModel = UndoEditsViewModel(undoItems: [])
        XCTAssertEqual(viewModel.undoItems.count, 1, "both were made today")
        XCTAssertEqual(viewModel.undoItems.first?.items.count, 2)
        XCTAssertEqual(viewModel.undoItems.first?.date, Calendar.current.startOfDay(for: viewModel.undoItems[0].items[0].timestamp))
        let kerb = viewModel.undoItems[0].items.first { $0.elementId == 900101 }
        XCTAssertEqual(kerb?.tags.first?.action, .added)
        let sidewalk = viewModel.undoItems[0].items.first { $0.elementId == 121949 }
        XCTAssertEqual(sidewalk?.changedKeys, ["ext:surface"])
    }

    func testTheViewModelUndoesThroughTheManager() throws {
        answerSidewalk()
        let viewModel = UndoEditsViewModel(undoItems: [])
        let item = try XCTUnwrap(viewModel.undoItems.first?.items.first)
        viewModel.undo(item: item)
        waitUntil(timeout: 10, "the undo never finished") { undoDoneCount() == 1 }
        viewModel.loadUndoItems()
        XCTAssertTrue(viewModel.undoItems.isEmpty)
    }

    func testAnOverrideingHandlerOfALaterQuestTakesOver() throws {
        // Documents how the handler works: the most recently created quest answers every undo.
        answerSidewalk()
        let later = LongElementQuest(questId: "2", questQuery: "nodes with (kerb)", elementType: "Kerbs", elementTypeIcon: nil)
        let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first)
        MapUndoManager.shared.undo(for: item.id)
        waitUntil(timeout: 10, "the undo never finished") { undoDoneCount() == 1 }
        withExtendedLifetime(later) {}
    }
}
