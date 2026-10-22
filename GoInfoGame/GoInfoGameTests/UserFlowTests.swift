//
//  UserFlowTests.swift
//  GoInfoGameTests
//
//  End-to-end user journeys run against the shared mock server (the same fixtures the UI tests
//  use) instead of the live staging server these tests used to depend on:
//
//    login -> workspaces -> workspace quests -> map data -> answer a quest -> upload -> undo
//

import XCTest
import Combine
import CoreLocation
@testable import GoInfoGame
@testable import osmparser
@testable import osmapi

final class UserFlowTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private var events: SheetEvents!

    override func setUp() {
        super.setUp()
        MockServer.installChangesets()
        MockServer.installLatestElements()
        events = recordSheetEvents()
    }

    // MARK: Journey steps

    /// Logs in through the real view model and waits for success.
    private func login() {
        SessionManager.shared.setDeclinedBiometric(true, for: .production)
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        let viewModel = PosmLoginViewModel()
        viewModel.username = "tester@example.com"
        viewModel.password = "pw"
        viewModel.performLogin(for: .production)
        waitUntil("login did not finish") { viewModel.isLoginSuccess }
    }

    /// Fetches the workspace list and then the quests of the first workspace; returns the workspace.
    @MainActor
    private func openFirstWorkspace() -> Workspace? {
        MockServer.installWorkspaces()
        let initial = InitialViewModel()
        initial.fetchWorkspacesList(location: CLLocationCoordinate2D(latitude: 47.62619, longitude: -122.24255))
        waitUntil("workspaces did not load") { !initial.isLoading }

        _ = KeychainManager.save(key: "workspaceID", data: "222")
        var workspace: Workspace?
        var finished = false
        initial.fetchLongQuestsFor(workspaceId: "222") { ok, _, loaded in
            workspace = ok ? loaded : nil
            finished = true
        }
        waitUntil("quests did not load") { finished }
        QuestsRepository.shared.loadLongQuests(from: "longQuestJson")
        return workspace
    }

    /// Loads the map the way the map screen does and returns the view model (kept alive by the caller).
    @MainActor
    private func loadMap(for workspace: Workspace) -> MapViewModel {
        MockServer.installMapData()
        let map = MapViewModel(workspace: workspace)
        map.fetchOSMDataFor(from: .currentLocation(location: CLLocationCoordinate2D(latitude: 47.62619, longitude: -122.24255)))
        waitUntil("map data did not load") { !map.isLoading && !map.items.isEmpty }
        return map
    }

    private func uploads() -> [MockHTTP.Recorded] {
        MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex, method: "POST")
    }

    private func pinQuest(id: Int64, in map: MapViewModel) -> (unit: DisplayUnitWithCoordinate, quest: LongElementQuest)? {
        guard let unit = map.items.first(where: { $0.id == id }),
              let quest = unit.displayUnit.parent as? LongElementQuest else { return nil }
        return (unit, quest)
    }

    // MARK: Journeys

    @MainActor
    func testAnAnsweredQuestIsUploadedThenUndone() throws {
        login()
        let workspace = try XCTUnwrap(openFirstWorkspace(), "workspace quests should load")
        let map = loadMap(for: workspace)
        let pin = try XCTUnwrap(pinQuest(id: 900101, in: map), "the kerb node should have a quest pin")
        XCTAssertNil(db.getNode(id: 900101)?.tags["testing"])

        // Answer
        let tags = ["testing": "testQuestUndoFlow"]
        pin.quest.updateTags(id: pin.unit.id, questType: pin.quest.elementType, tags: tags, type: .node, iconName: pin.quest.iconName)
        waitUntil(timeout: 10, "the answer never synced") { events.contains("synced") }

        XCTAssertEqual(uploads().count, 1)
        XCTAssertTrue(uploads()[0].bodyString.contains("testing"), "the answer is part of the uploaded change")
        XCTAssertEqual(db.getNode(id: 900101)?.tags["testing"], "testQuestUndoFlow")
        XCTAssertEqual(db.getChangesets(synced: true).count, 1)

        // The edit is listed for undo, then reverted through the same upload pipeline.
        let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first { $0.elementId == 900101 && $0.type == .node })
        XCTAssertEqual(item.changedKeys, ["testing"])
        MapUndoManager.shared.undo(for: item.id)
        waitUntil(timeout: 10, "the undo never finished") { events.names.filter { $0 == "undoDone" }.count == 1 }

        XCTAssertEqual(uploads().count, 2, "the undo is a second upload")
        XCTAssertFalse(uploads()[1].bodyString.contains("testQuestUndoFlow"), "the undo no longer carries the answer")
        XCTAssertTrue(MapUndoManager.shared.getUndoItems().isEmpty, "a completed undo leaves the list")
    }

    @MainActor
    func testSeveralSelectedQuestsAreAnsweredTogetherAndUndoneIndividually() throws {
        login()
        let workspace = try XCTUnwrap(openFirstWorkspace())
        let map = loadMap(for: workspace)
        map.isMultiSelectModeEnabled = true

        let ids: [Int64] = [900101, 409776]
        let units = AppQuestManager.shared.fetchQuestsFromDB().filter { ids.contains($0.id) }
        XCTAssertEqual(units.count, 2, "both elements have a pin")
        units.forEach { map.selectedAnnotaions.insert($0.annotation) }

        // The map's own multi-answer callback fans one answer out to every selected quest.
        let selected = try XCTUnwrap(map.getSelectedQuest()?.parent as? LongElementQuest)
        let answer = LongFormAnswer(tags: ["testing": "testMultiQuestAnswer"], capturedImage: nil, imageTagKey: nil)
        let callback = try XCTUnwrap(selected.questAnswersSelected, "getSelectedQuest wires the multi-answer callback")
        callback(answer)
        waitUntil(timeout: 10, "both answers should sync") { db.getChangesets(synced: true).count == 2 }

        XCTAssertTrue(map.selectedAnnotaions.isEmpty, "the selection is cleared once answered")
        XCTAssertFalse(map.isMultiSelectModeEnabled)
        XCTAssertEqual(Set(MapUndoManager.shared.getUndoItems().map { Int64($0.elementId) }), Set(ids))

        for id in ids {
            let item = try XCTUnwrap(MapUndoManager.shared.getUndoItems().first { $0.elementId == id })
            let before = events.names.filter { $0 == "undoDone" }.count
            MapUndoManager.shared.undo(for: item.id)
            waitUntil(timeout: 10, "undo of \(id) never finished") { events.names.filter { $0 == "undoDone" }.count == before + 1 }
        }
        XCTAssertTrue(MapUndoManager.shared.getUndoItems().isEmpty)
    }

    @MainActor
    func testTheSyncedChangesetsOfAJourneyCanBeFetched() throws {
        login()
        let workspace = try XCTUnwrap(openFirstWorkspace())
        let map = loadMap(for: workspace)
        XCTAssertTrue(db.getChangesets(synced: true).isEmpty, "nothing has been answered yet")

        let pin = try XCTUnwrap(pinQuest(id: 900101, in: map))
        pin.quest.updateTags(id: pin.unit.id, questType: pin.quest.elementType, tags: ["testing": "journey"], type: .node, iconName: pin.quest.iconName)
        waitUntil(timeout: 10, "the answer never synced") { events.contains("synced") }

        let synced = db.getChangesets(synced: true)
        XCTAssertEqual(synced.count, 1)
        XCTAssertEqual(synced.first?.elementId, 900101)
        XCTAssertEqual(synced.first?.tags["testing"], "journey")
        XCTAssertEqual(synced.first?.changesetId, 0, "changesetId stays 0 while the edit is still undoable")
        XCTAssertTrue(db.getChangesets(synced: false).isEmpty)
    }

    func testAChangesetCanBeOpenedOnTheServer() {
        MockHTTP.stub("PUT", path: "/api/0.6/changeset/create", reply: .json("4242"))
        let connection = OSMConnection()
        connection.accessToken = fixtureAccessToken

        var opened: Int?
        let done = expectation(description: "changeset opened")
        connection.openChangeSet(createdByTag: "unit-test") { result in
            opened = try? result.get()
            done.fulfill()
        }
        wait(for: [done], timeout: 5)

        XCTAssertEqual(opened, 4242)
        XCTAssertEqual(connection.currentChangesetId, 4242)
        let request = MockHTTP.requests(path: "/api/0.6/changeset/create", method: "PUT").first
        XCTAssertEqual(request?.header("Authorization"), "Bearer \(fixtureAccessToken)")
        XCTAssertTrue(request?.bodyString.contains("unit-test") ?? false, "the created_by tag is sent")
    }

    func testAFailedChangesetOpenIsReported() {
        MockHTTP.stub("PUT", path: "/api/0.6/changeset/create", reply: .statusWithBody(500, "boom"))
        let connection = OSMConnection()
        connection.accessToken = fixtureAccessToken

        var failed = false
        let done = expectation(description: "failure reported")
        connection.openChangeSet(createdByTag: "unit-test") { result in
            if case .failure = result { failed = true }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(failed)
    }
}
