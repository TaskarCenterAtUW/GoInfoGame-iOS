//
//  DatasyncManagerTests.swift
//  GoInfoGameTests
//
//  DatasyncManager against MockHTTP, using the UI tests' LongFormOSMElements.json /
//  LongFormLatestElements.json fixtures for the elements and the server-side "latest" state:
//
//    way 121949 - blank sidewalk at version 1 locally; the server is already at version 2 with
//                 ext:surface=asphalt and width=36 (so answering "concrete" is a real conflict)
//    node 900101 - a kerb (barrier=kerb, kerb=raised)
//
//  These replace the earlier tests that logged in to the live dev server.
//

import XCTest
import Combine
import RealmSwift
import CoreLocation
import osmapi
@testable import GoInfoGame

final class DatasyncManagerTests: AppTestCase {

    private let sync = DatasyncManager.shared
    private let db = DatabaseConnector.shared

    override func setUp() {
        super.setUp()
        signIn(workspaceID: "222")
        seedMap("LongFormOSMElements")
    }

    // MARK: Helpers

    private func way(tags: [String: String] = ["footway": "sidewalk", "highway": "footway", "ext:surface": "concrete"],
                     version: Int = 1, changeset: Int = 775) -> OSMWay {
        OSMWay(type: "way", id: 121949, timestamp: Date(), version: version, changeset: changeset, user: "", uid: 0,
               nodes: [800010, 800011], tags: tags)
    }

    private func node(tags: [String: String] = ["barrier": "kerb", "kerb": "flush"], version: Int = 2, changeset: Int = 775) -> OSMNode {
        OSMNode(type: "node", id: 900101, lat: 17.4385, lon: 78.361, timestamp: Date(), version: version, changeset: changeset,
                user: "", uid: 0, tags: tags)
    }

    private func uploads() -> [MockHTTP.Recorded] { MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex, method: "POST") }

    /// Subscribes to the conflict prompt and answers it (on the main queue, like the real sheet).
    @discardableResult
    private func answerConflicts(with decide: @escaping (PendingSyncConflict) -> ConflictResolutionDecision) -> Prompts {
        let prompts = Prompts()
        MapViewPublisher.shared.conflictDetected.sink { conflict in
            prompts.seen.append(conflict)
            conflict.resolve(decide(conflict))
        }.store(in: &cancellables)
        return prompts
    }
    final class Prompts { var seen: [PendingSyncConflict] = [] }

    // MARK: openChangeset / closeChangeset

    func testOpeningAChangesetReturnsTheServerIdAndSendsTheCreatorPayload() async throws {
        MockServer.installChangesets(changesetID: 4242)
        let id = try await sync.openChangeset()
        XCTAssertEqual(id, 4242)

        let sent = try XCTUnwrap(MockHTTP.requests(path: MockServer.changesetCreate).first)
        XCTAssertEqual(sent.method, "PUT")
        XCTAssertEqual(sent.header("X-Workspace"), "222")
        XCTAssertEqual(sent.header("Authorization"), "Bearer \(fixtureAccessToken)")
        XCTAssertEqual(sent.header("Content-Type"), "application/xml")
        XCTAssertTrue(sent.bodyString.contains(#"<tag k="created_by" v="GIG "#))
        XCTAssertTrue(sent.bodyString.contains(#"<tag k="comment" v="iOS OSM client"/>"#))
    }

    func testOpeningAChangesetRequiresASignedInUser() async {
        _ = KeychainManager.delete(key: "accessToken")
        do {
            _ = try await sync.openChangeset()
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "NoAccessToken")
        }
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testOpeningAChangesetSurfacesServerFailures() async {
        MockServer.installChangesets(createFails: true)
        do {
            _ = try await sync.openChangeset()
            XCTFail("expected an error")
        } catch {
            guard case APIError.noNetworkConnection = error else { return XCTFail("got \(error)") }
        }
    }

    func testClosingAChangeset() async throws {
        MockServer.installChangesets()
        let closed = try await sync.closeChangeset(id: "775")
        XCTAssertTrue(closed)
        let sent = try XCTUnwrap(MockHTTP.requests(path: "\(MockServer.osm)/changeset/775/close").first)
        XCTAssertEqual(sent.method, "PUT")
        XCTAssertEqual(sent.header("X-Workspace"), "222")
    }

    func testClosingRequiresASignedInUserAndSurfacesFailures() async {
        _ = KeychainManager.delete(key: "accessToken")
        do { _ = try await sync.closeChangeset(id: "1"); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).domain, "NoAccessToken")
        }

        signIn()
        MockHTTP.stub("PUT", pathRegex: MockServer.changesetCloseRegex, reply: .statusWithBody(500, "boom"))
        do { _ = try await sync.closeChangeset(id: "1"); XCTFail("expected an error") } catch {
            XCTAssertNotNil(error as? APIError)
        }
    }

    // MARK: updateWay / updateNode (one upload attempt)

    func testUpdatingAWayUploadsAModifyAndStoresTheNewVersionLocally() async throws {
        MockServer.installChangesets()
        let newVersion = try await sync.updateWay(way: way(version: 1), exclude_gig_tags: false)

        XCTAssertEqual(newVersion, 2)
        let sent = try XCTUnwrap(uploads().first)
        XCTAssertEqual(sent.path, "\(MockServer.osm)/changeset/775/upload")
        XCTAssertTrue(sent.bodyString.hasPrefix("<osmChange version=\"0.6\" generator=\"GIG Change generator\"><modify>"))
        XCTAssertTrue(sent.bodyString.contains(#"<tag k="ext:surface" v="concrete"/>"#))
        XCTAssertTrue(sent.bodyString.contains(#"version = "1""#), "the upload is made against the local version")
        XCTAssertTrue(sent.bodyString.contains(#"<nd ref="800010" />"#))
        XCTAssertEqual(db.getWay(id: 121949)?.version, 2)
        XCTAssertEqual(db.getWay(id: 121949)?.tags["ext:surface"], "concrete")
    }

    func testUpdatingAWayRequiresASignedInUser() async {
        _ = KeychainManager.delete(key: "accessToken")
        do { _ = try await sync.updateWay(way: way(), exclude_gig_tags: false); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).domain, "No AccessToken")
        }
    }

    func testAConflictingWayUploadThrowsConflict() async {
        MockServer.installChangesets(upload: .alwaysConflict)
        do { _ = try await sync.updateWay(way: way(), exclude_gig_tags: false); XCTFail("expected an error") } catch {
            guard case APIError.conflict = error else { return XCTFail("got \(error)") }
        }
        XCTAssertNil(db.getWay(id: 121949)?.tags["ext:surface"], "a rejected upload must not touch the local copy")
    }

    func testUpdatingANodeUploadsAModifyAndStoresTheNewVersionLocally() async throws {
        MockServer.installChangesets()
        let newVersion = try await sync.updateNode(node: node(tags: ["barrier": "kerb", "kerb": "flush"], version: 2), exclude_gig_tags: false)

        XCTAssertEqual(newVersion, 3)
        let sent = try XCTUnwrap(uploads().first)
        XCTAssertTrue(sent.bodyString.contains(#"<tag k="kerb" v="flush"/>"#))
        XCTAssertEqual(db.getNode(id: 900101)?.version, 3)
        XCTAssertEqual(db.getNode(id: 900101)?.tags["kerb"], "flush")
    }

    func testUpdatingANodeSurfacesUploadFailuresAndMissingTokens() async {
        MockServer.installChangesets(upload: .serverError)
        do { _ = try await sync.updateNode(node: node(), exclude_gig_tags: false); XCTFail("expected an error") } catch {
            XCTAssertNotNil(error as? APIError)
        }
        _ = KeychainManager.delete(key: "accessToken")
        do { _ = try await sync.updateNode(node: node(), exclude_gig_tags: false); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).domain, "No AccessToken")
        }
    }

    // MARK: createNode / deleteNode

    func testCreatingANodeRunsTheFullChangesetLifecycleAndReturnsTheServerIds() async throws {
        MockServer.installChangesets(changesetID: 900, upload: .nodeCreated(id: 555, version: 1))
        let created = try await sync.createNode(node: UserNodesHelper.getPowerPole(lat: 17.4, lon: 78.3, changeset: 1, tags: ["amenity": "bench"]))

        XCTAssertEqual(created.id, 555)
        XCTAssertEqual(created.version, 1)
        XCTAssertEqual(MockHTTP.requests.map { "\($0.method) \($0.path)" }.filter { $0.contains("changeset") },
                       ["PUT \(MockServer.changesetCreate)", "POST \(MockServer.osm)/changeset/900/upload", "PUT \(MockServer.osm)/changeset/900/close"])
        let upload = uploads().first!.bodyString
        XCTAssertTrue(upload.contains("<create>"))
        XCTAssertTrue(upload.contains(#"<tag k="amenity" v="bench"/>"#))
        XCTAssertTrue(upload.contains(#"changeset = "900""#), "the new node is created inside the freshly opened changeset")
    }

    func testCreatingANodeFailsWhenTheServerDoesNotEchoTheNewId() async {
        MockServer.installChangesets(upload: .ok)   // a plain <diffResult /> has no <node new_id=...>
        do {
            _ = try await sync.createNode(node: UserNodesHelper.getPowerPole(lat: 1, lon: 2, changeset: 1, tags: ["a": "b"]))
            XCTFail("expected an error")
        } catch {
            guard case APIError.decodingFailed = error else { return XCTFail("got \(error)") }
        }
    }

    func testCreatingANodeStopsIfTheChangesetCannotBeOpened() async {
        MockServer.installChangesets(createFails: true)
        do {
            _ = try await sync.createNode(node: UserNodesHelper.getPowerPole(lat: 1, lon: 2, changeset: 1, tags: [:]))
            XCTFail("expected an error")
        } catch {
            XCTAssertTrue(uploads().isEmpty)
        }
    }

    func testCreatingANodeNeedsAToken() async {
        _ = KeychainManager.delete(key: "accessToken")
        do {
            _ = try await sync.uploadNode(node: UserNodesHelper.getPowerPole(lat: 1, lon: 2, changeset: 1, tags: [:]))
            XCTFail("expected an error")
        } catch {
            guard case APIError.unauthorized = error else { return XCTFail("got \(error)") }
        }
    }

    func testDeletingANodeUploadsADeleteAndClosesTheChangeset() async throws {
        MockServer.installChangesets(changesetID: 31)
        let closed = try await sync.deleteNode(node: node(version: 3))
        XCTAssertTrue(closed)
        let upload = try XCTUnwrap(uploads().first)
        XCTAssertTrue(upload.bodyString.contains("<delete>"))
        XCTAssertTrue(upload.bodyString.contains(#"id = "900101""#))
        XCTAssertEqual(MockHTTP.requests(path: "\(MockServer.osm)/changeset/31/close").count, 1)
    }

    func testDeletingANodeSurfacesFailures() async {
        MockServer.installChangesets(upload: .serverError)
        do { _ = try await sync.deleteNode(node: node()); XCTFail("expected an error") } catch {
            XCTAssertTrue(MockHTTP.requests(pathRegex: MockServer.changesetCloseRegex).isEmpty, "a failed delete is not closed")
        }
        _ = KeychainManager.delete(key: "accessToken")
        do { _ = try await sync.deleteNode(node: node()); XCTFail("expected an error") } catch {}
    }

    // MARK: syncWay

    func testSyncingAWayWithoutConflictsOpensUploadsAndCloses() async throws {
        MockServer.installChangesets()
        let result = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"])

        XCTAssertTrue(result.result)
        XCTAssertEqual(result.version, 2)
        XCTAssertEqual(db.getWay(id: 121949)?.version, 2)
        XCTAssertEqual(MockHTTP.requests(pathRegex: MockServer.changesetCloseRegex).count, 1)
        XCTAssertEqual(uploads().count, 1)
    }

    func testAnOverriddenConflictKeepsTheUsersAnswersOnTheLatestServerVersion() async throws {
        UserDefaults.standard.set(true, forKey: "workspace_overrideConflicts")
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        let prompts = answerConflicts { _ in XCTFail("an overriding workspace never prompts"); return .cancelled }

        let result = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"])

        XCTAssertTrue(result.result)
        XCTAssertTrue(prompts.seen.isEmpty)
        XCTAssertEqual(uploads().count, 2)
        let retry = uploads()[1].bodyString
        XCTAssertTrue(retry.contains(#"version = "2""#), "retried on the server's version")
        XCTAssertTrue(retry.contains(#"<tag k="ext:surface" v="concrete"/>"#), "the user's value wins")
        XCTAssertTrue(retry.contains(#"<tag k="width" v="36"/>"#), "tags the user never touched come from the server")
        XCTAssertEqual(result.version, 3)
        XCTAssertEqual(db.getWay(id: 121949)?.tags["ext:surface"], "concrete")
    }

    func testAConflictOnUntouchedKeysRetriesWithoutAskingTheUser() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        let prompts = answerConflicts { _ in XCTFail("nothing the user answered conflicts"); return .cancelled }

        // The server moved (surface/width were added) but this answer only sets a tag it doesn't have.
        let result = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:text_entry": "hello"])

        XCTAssertTrue(result.result)
        XCTAssertTrue(prompts.seen.isEmpty)
        XCTAssertEqual(uploads().count, 2)
        XCTAssertTrue(uploads()[1].bodyString.contains(#"<tag k="ext:surface" v="asphalt"/>"#), "the server's value is kept")
    }

    func testARealConflictAsksTheUserAndAppliesTheirChoiceForTheServer() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        let prompts = answerConflicts { _ in .resolved(["ext:surface": .useServer]) }

        let result = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"],
                                            elementTypeName: "Sidewalks", iconName: "sidewalk_surface")

        let prompt = try XCTUnwrap(prompts.seen.first)
        XCTAssertEqual(prompt.elementId, 121949)
        XCTAssertEqual(prompt.elementTypeName, "Sidewalks")
        XCTAssertEqual(prompt.iconName, "sidewalk_surface")
        XCTAssertEqual(prompt.conflicts.count, 1)
        XCTAssertEqual(prompt.conflicts[0].key, "ext:surface")
        XCTAssertEqual(prompt.conflicts[0].existingValue, "asphalt")
        XCTAssertEqual(prompt.conflicts[0].answeredValue, "concrete")

        XCTAssertTrue(result.result)
        XCTAssertTrue(uploads()[1].bodyString.contains(#"<tag k="ext:surface" v="asphalt"/>"#), "'use server' keeps the server's value")
    }

    func testARealConflictAppliesTheUsersChoiceForTheirOwnAnswer() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        answerConflicts { _ in .resolved(["ext:surface": .useMine]) }

        let result = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"])

        XCTAssertTrue(result.result)
        XCTAssertTrue(uploads()[1].bodyString.contains(#"<tag k="ext:surface" v="concrete"/>"#))
    }

    func testAnUnansweredConflictDefaultsToTheUsersOwnValue() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        answerConflicts { _ in .resolved([:]) }
        _ = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"])
        XCTAssertTrue(uploads()[1].bodyString.contains(#"<tag k="ext:surface" v="concrete"/>"#))
    }

    func testCancellingTheConflictPromptLeavesTheElementUnsynced() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        answerConflicts { _ in .cancelled }

        let result = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"])

        XCTAssertFalse(result.result)
        XCTAssertEqual(uploads().count, 1, "no retry after the user declines")
        XCTAssertTrue(MockHTTP.requests(pathRegex: MockServer.changesetCloseRegex).isEmpty)
        XCTAssertNotEqual(db.getWay(id: 121949)?.tags["ext:surface"], "concrete", "the user's answer was not applied")
    }

    func testAnElementDeletedOnTheServerIsRemovedLocally() async {
        MockServer.installChangesets(upload: .alwaysConflict)
        MockHTTP.stub("GET", pathRegex: #"^/prod/api/0\.6/way/\d+\.json$"#, reply: .statusWithBody(410, "gone"))
        db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")
        var removed: [Int] = []
        QuestsPublisher.shared.elementDeleted.sink { removed.append($0) }.store(in: &cancellables)

        do {
            _ = try await sync.syncWay(way: way(changeset: -1), exclude_gig_tags: false, editedTags: ["ext:surface": "concrete"])
            XCTFail("expected .deleted")
        } catch {
            guard case APIError.deleted = error else { return XCTFail("got \(error)") }
        }

        XCTAssertNil(db.getWay(id: 121949))
        XCTAssertTrue(db.getChangesets().isEmpty)
        waitUntil("elementDeleted was not published") { removed == [121949] }
    }

    func testAnUndoWithNothingLeftToRevertReturnsTheServerVersionWithoutUploading() async throws {
        // Undo (exclude_gig_tags) of a tag someone else has since changed can't be merged safely.
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()

        let result = try await sync.updateWay2(way: way(tags: ["ext:surface": "gravel"], changeset: 775), exclude_gig_tags: true,
                                               editedTags: ["ext:surface": "concrete"])

        XCTAssertEqual(result, 2, "the latest server version is returned and nothing is overwritten")
        XCTAssertEqual(uploads().count, 1)
    }

    func testAnUndoThatCanBeMergedIsUploadedOnTheLatestVersion() async throws {
        // Server = {surface: asphalt, width: 36}. The edit being undone set width 36 (original: none).
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()

        let result = try await sync.updateWay2(way: way(tags: ["footway": "sidewalk", "highway": "footway"], changeset: 775),
                                               exclude_gig_tags: true, editedTags: ["width": "36"])

        XCTAssertEqual(uploads().count, 2)
        XCTAssertEqual(result, 3)
        let retry = uploads()[1].bodyString
        XCTAssertFalse(retry.contains(#"k="width""#), "the undone tag is gone")
    }

    func testOtherFailuresPropagateWithoutTheConflictMachinery() async {
        MockServer.installChangesets(upload: .serverError)
        do { _ = try await sync.updateWay2(way: way(), exclude_gig_tags: false, editedTags: ["a": "b"]); XCTFail("expected an error") } catch {
            XCTAssertNotNil(error as? APIError)
        }
        XCTAssertTrue(MockHTTP.requests(pathRegex: #"/way/\d+\.json$"#).isEmpty, "only a 409 triggers the latest-version fetch")
    }

    // MARK: syncNode

    func testSyncingANodeWithoutConflicts() async throws {
        MockServer.installChangesets()
        let result = try await sync.syncNode(node: node(changeset: -1), exclude_gig_tags: false, editedTags: ["kerb": "flush"])
        XCTAssertTrue(result.result)
        XCTAssertEqual(result.version, 3)
        XCTAssertEqual(db.getNode(id: 900101)?.version, 3)
    }

    func testANodeConflictIsResolvedThroughThePromptToo() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()    // server: kerb=raised at version 2
        let prompts = answerConflicts { _ in .resolved(["kerb": .useServer]) }

        let result = try await sync.syncNode(node: node(version: 1, changeset: -1), exclude_gig_tags: false, editedTags: ["kerb": "flush"])

        XCTAssertEqual(prompts.seen.first?.conflicts.first?.existingValue, "raised")
        XCTAssertTrue(result.result)
        XCTAssertTrue(uploads()[1].bodyString.contains(#"<tag k="kerb" v="raised"/>"#))
    }

    func testANodeConflictUnderAnOverridingWorkspaceFavoursTheUser() async throws {
        UserDefaults.standard.set(true, forKey: "workspace_overrideConflicts")
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        let result = try await sync.syncNode(node: node(version: 1, changeset: -1), exclude_gig_tags: false, editedTags: ["kerb": "flush"])
        XCTAssertTrue(result.result)
        XCTAssertTrue(uploads()[1].bodyString.contains(#"<tag k="kerb" v="flush"/>"#))
    }

    func testCancellingANodeConflictLeavesItUnsynced() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        answerConflicts { _ in .cancelled }
        let result = try await sync.syncNode(node: node(version: 1, changeset: -1), exclude_gig_tags: false, editedTags: ["kerb": "flush"])
        XCTAssertFalse(result.result)
        XCTAssertEqual(uploads().count, 1)
    }

    func testANodeUntouchedConflictAndANodeUndoMerge() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        let result = try await sync.updateNode2(node: node(version: 1, changeset: 775), exclude_gig_tags: false, editedTags: ["ext:note": "x"])
        XCTAssertEqual(uploads().count, 2)
        XCTAssertEqual(result, 3)

        MockHTTP.reset(); MockServer.installChangesets(upload: .conflict(times: 1)); MockServer.installLatestElements()
        let undone = try await sync.updateNode2(node: node(tags: ["barrier": "kerb", "kerb": "flush"], version: 1, changeset: 775),
                                                exclude_gig_tags: true, editedTags: ["kerb": "raised"])
        XCTAssertEqual(undone, 3)
        XCTAssertEqual(uploads().count, 2)
    }

    func testANodeDeletedOnTheServerIsRemovedLocally() async {
        MockServer.installChangesets(upload: .alwaysConflict)
        MockHTTP.stub("GET", pathRegex: #"^/prod/api/0\.6/node/\d+\.json$"#, reply: .statusWithBody(410, "gone"))
        db.createChangeset(id: 900101, questType: "Kerbs", type: .node, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")
        do {
            _ = try await sync.updateNode2(node: node(changeset: 775), exclude_gig_tags: false, editedTags: ["kerb": "flush"])
            XCTFail("expected .deleted")
        } catch {
            guard case APIError.deleted = error else { return XCTFail("got \(error)") }
        }
        XCTAssertTrue(db.getChangesets().isEmpty)
    }

    // MARK: syncData (drain the pending edits)

    @discardableResult
    private func queueWayEdit(tags: [String: String] = ["ext:surface": "concrete"]) -> StoredChangeset {
        let stored = db.getWay(id: 121949)!
        return db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: stored.tags.toDictionary(), tags: tags,
                                  version: stored.version, iconName: "sidewalk_surface", nodes: stored.nodes)!
    }

    func testSyncDataWithNothingPendingIsASuccess() async throws {
        let ok = try await sync.syncData()
        XCTAssertTrue(ok)
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testSyncDataUploadsEachPendingEditAndMarksItSynced() async throws {
        MockServer.installChangesets()
        // Realm objects are thread-confined and this test resumes on another thread after each
        // await, so only plain ids are carried across.
        let changesetID = queueWayEdit().id
        let nodeChangesetID = db.createChangeset(id: 900101, questType: "Kerbs", type: .node, originalTags: ["barrier": "kerb", "kerb": "raised"],
                                                 tags: ["kerb": "flush"], version: 2, iconName: "kerb", point: CLLocationCoordinate2D(latitude: 1, longitude: 2))!.id

        let ok = try await sync.syncData()

        XCTAssertTrue(ok)
        XCTAssertEqual(uploads().count, 2)
        XCTAssertEqual(db.getChangeset(for: changesetID)?.updatedVersion, 2)
        XCTAssertEqual(db.getChangeset(for: changesetID)?.changesetId, 0)
        XCTAssertEqual(db.getChangeset(for: nodeChangesetID)?.updatedVersion, 3)
        XCTAssertTrue(db.getChangesets().isEmpty, "nothing is pending any more")
        XCTAssertEqual(db.getChangesets(synced: true).count, 2)
    }

    func testSyncDataIgnoresEditsWhoseElementIsNoLongerStored() async throws {
        MockServer.installChangesets()
        db.createChangeset(id: 31337, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")
        let ok = try await sync.syncData()
        XCTAssertTrue(ok)
        XCTAssertTrue(uploads().isEmpty)
        XCTAssertEqual(db.getChangesets().count, 1, "left queued - nothing to upload it against")
    }

    func testSyncDataThrowsAndKeepsTheEditQueuedWhenTheUploadFails() async {
        MockServer.installChangesets(upload: .serverError)
        let changesetID = queueWayEdit().id
        do { _ = try await sync.syncData(); XCTFail("expected an error") } catch {
            XCTAssertNotNil(error as? APIError)
        }
        XCTAssertEqual(db.getChangeset(for: changesetID)?.updatedVersion, -1)
    }

    func testSyncDataReportsFalseWhenTheUserDeclinesAConflict() async throws {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        answerConflicts { _ in .cancelled }
        let changesetID = queueWayEdit().id
        let ok = try await sync.syncData()
        XCTAssertFalse(ok)
        XCTAssertEqual(db.getChangeset(for: changesetID)?.updatedVersion, -1)
    }

    func testSyncDataToOSMReportsSuccessThroughTheCompletionHandler() {
        MockServer.installChangesets()
        queueWayEdit()
        let exp = expectation(description: "sync")
        var outcome: Result<Bool, APIError>?
        sync.syncDataToOSM(exclude_gig_tags: false) { outcome = $0; exp.fulfill() }
        wait(for: [exp], timeout: 10)
        guard case .success(true)? = outcome else { return XCTFail("got \(String(describing: outcome))") }
    }

    func testSyncDataToOSMReportsAFalseSyncAsAFailure() {
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        answerConflicts { _ in .cancelled }
        queueWayEdit()
        let exp = expectation(description: "sync")
        var outcome: Result<Bool, APIError>?
        sync.syncDataToOSM(exclude_gig_tags: false) { outcome = $0; exp.fulfill() }
        wait(for: [exp], timeout: 10)
        guard case .failure(let error)? = outcome, case .custom(let message) = error else { return XCTFail("got \(String(describing: outcome))") }
        XCTAssertEqual(message, "Sync failed. Please try again.")
    }

    // MARK: Fetching the latest element

    func testFetchingTheLatestWayAndNode() async throws {
        MockServer.installLatestElements()
        let latestWay = try await sync.fetchway2(wayId: "121949")
        XCTAssertEqual(latestWay.version, 2)
        XCTAssertEqual(latestWay.tags["ext:surface"], "asphalt")
        let latestNode = try await sync.fetchNode2(nodeId: "900101")
        XCTAssertEqual(latestNode.tags["kerb"], "raised")
    }

    func testFetchingAnElementThatIsNotThereFails() async {
        MockHTTP.stub("GET", pathRegex: #"/(way|node)/\d+\.json$"#, reply: .json(#"{"version":"0.6","generator":"g","copyright":"c","attribution":"a","license":"l","elements":[]}"#))
        do { _ = try await sync.fetchway2(wayId: "1"); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).code, 404)
        }
        do { _ = try await sync.fetchNode2(nodeId: "1"); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).domain, "No Node Found")
        }
    }

    func testFetchingNeedsAWorkspace() async {
        _ = KeychainManager.delete(key: "workspaceID")
        do { _ = try await sync.fetchNode2(nodeId: "1"); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).domain, "No WorkspaceID")
        }
        let exp = expectation(description: "completion")
        sync.fetchWay21(wayId: "1") { result in
            if case .failure(let error) = result { XCTAssertEqual((error as NSError).code, 401) } else { XCTFail("expected failure") }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testCallbackStyleWayFetch() {
        MockServer.installLatestElements()
        let exp = expectation(description: "fetch")
        sync.fetchWay21(wayId: "121949") { result in
            XCTAssertEqual((try? result.get())?.version, 2)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        MockHTTP.reset()
        MockHTTP.stub("GET", pathRegex: #"/way/\d+\.json$"#, reply: .json(#"{"version":"0.6","generator":"g","copyright":"c","attribution":"a","license":"l","elements":[]}"#))
        let empty = expectation(description: "empty")
        sync.fetchWay21(wayId: "1") { result in
            if case .failure(let error) = result { XCTAssertEqual((error as NSError).code, 404) } else { XCTFail("expected failure") }
            empty.fulfill()
        }
        wait(for: [empty], timeout: 5)

        MockHTTP.reset()
        MockHTTP.stub("GET", pathRegex: #"/way/\d+\.json$"#, reply: .offline)
        let failed = expectation(description: "failed")
        sync.fetchWay21(wayId: "1") { result in
            if case .failure = result {} else { XCTFail("expected failure") }
            failed.fulfill()
        }
        wait(for: [failed], timeout: 5)
    }

    func testFetchLatestTagsRefreshesTheLocalCopy() async throws {
        MockServer.installLatestElements()
        let wayResult = await sync.fetchLatestTags(id: 121949, isWay: true)
        XCTAssertEqual(wayResult?.tags["width"], "36")
        XCTAssertEqual(db.getWay(id: 121949)?.version, 2, "the cache now reflects the server")
        XCTAssertEqual(db.getWay(id: 121949)?.tags["ext:surface"], "asphalt")

        let nodeResult = await sync.fetchLatestTags(id: 900101, isWay: false)
        XCTAssertEqual(nodeResult?.tags["barrier"], "kerb")
    }

    func testFetchLatestTagsIsNilWhenOffline() async {
        MockHTTP.stubAll(.offline)
        let result = await sync.fetchLatestTags(id: 121949, isWay: true)
        XCTAssertNil(result)
        XCTAssertEqual(db.getWay(id: 121949)?.version, 1, "the cache is left as it was")
    }

    // MARK: Cache refresh

    func testRefreshingAnOriginalElementOnlyTakesNewerVersions() {
        // Stored: way 121949 v1.
        let newer = OSMWay(type: "way", id: 121949, timestamp: Date(), version: 5, changeset: 1, user: "", uid: 0,
                           nodes: [800010, 800011], tags: ["highway": "footway", "ext:surface": "gravel"])
        sync.refreshOriginalWayIfNewer(newer)
        XCTAssertEqual(db.getWay(id: 121949)?.version, 5)

        let older = OSMWay(type: "way", id: 121949, timestamp: Date(), version: 3, changeset: 1, user: "", uid: 0,
                           nodes: [800010, 800011], tags: ["highway": "footway", "ext:surface": "stale"])
        sync.refreshOriginalWayIfNewer(older)
        XCTAssertEqual(db.getWay(id: 121949)?.tags["ext:surface"], "gravel", "an older copy never overwrites a newer one")

        let unseen = OSMWay(type: "way", id: 424242, timestamp: Date(), version: 1, changeset: 1, user: "", uid: 0, nodes: [], tags: ["highway": "footway"])
        sync.refreshOriginalWayIfNewer(unseen)
        XCTAssertNotNil(db.getWay(id: 424242), "an unknown element is simply stored")
    }

    func testRefreshingAnOriginalNodeBehavesTheSame() {
        let newer = node(tags: ["barrier": "kerb", "kerb": "lowered"], version: 9, changeset: 1)
        sync.refreshOriginalNodeIfNewer(newer)
        XCTAssertEqual(db.getNode(id: 900101)?.tags["kerb"], "lowered")
        sync.refreshOriginalNodeIfNewer(node(tags: ["barrier": "kerb", "kerb": "stale"], version: 4, changeset: 1))
        XCTAssertEqual(db.getNode(id: 900101)?.tags["kerb"], "lowered")
        sync.refreshOriginalNodeIfNewer(OSMNode(type: "node", id: 424243, lat: 1, lon: 2, timestamp: Date(), version: 1, changeset: 1, user: "", uid: 0, tags: ["a": "b"]))
        XCTAssertNotNil(db.getNode(id: 424243))
    }

    // MARK: Merging for undo

    func testMergingTagsForUndoRestoresOriginalsWhenTheServerStillHoldsTheEdit() {
        // The edit set surface=concrete over an original asphalt; the server still has concrete.
        let merged = sync.mergeTagsForUndo(originalTags: ["ext:surface": "asphalt", "highway": "footway"],
                                           edited: ["ext:surface": "concrete"],
                                           serverTags: ["ext:surface": "concrete", "highway": "footway", "ext:gig_complete": "yes", "ext:gig_last_updated": "2026-01-01"])
        XCTAssertEqual(merged, ["ext:surface": "asphalt", "highway": "footway"])
    }

    func testMergingTagsForUndoRefusesWhenSomeoneElseChangedTheTag() {
        XCTAssertNil(sync.mergeTagsForUndo(originalTags: ["ext:surface": "asphalt"], edited: ["ext:surface": "concrete"], serverTags: ["ext:surface": "gravel"]))
        XCTAssertNil(sync.mergeTagsForUndo(originalTags: ["ext:surface": "asphalt"], edited: ["ext:surface": "concrete"], serverTags: [:]),
                     "the tag was removed upstream")
        XCTAssertNil(sync.mergeTagsForUndo(originalTags: [:], edited: ["width": "40"], serverTags: ["width": "36"]),
                     "a tag the edit added now holds someone else's value")
    }

    func testMergingTagsForUndoRemovesTagsTheEditAddedAndKeepsOthers() {
        let merged = sync.mergeTagsForUndo(originalTags: ["highway": "footway"], edited: ["width": "40"],
                                           serverTags: ["highway": "footway", "width": "40", "name": "Main St"])
        XCTAssertEqual(merged, ["highway": "footway", "name": "Main St"])
    }

    func testMergingWaysAndNodes() {
        let local = way(tags: ["a": "mine", "b": "mine"], changeset: 11)
        let latest = OSMWay(type: "way", id: 121949, timestamp: Date(), version: 7, changeset: 1, user: "", uid: 0, nodes: [800010, 800011],
                            tags: ["a": "server", "c": "server"])

        let normal = sync.mergeWays(localWay: local, latestWay: latest, exclude_gig_tags: false, editedTags: [:])
        XCTAssertEqual(normal?.tags, ["a": "mine", "b": "mine", "c": "server"], "local values override, server-only tags survive")
        XCTAssertEqual(normal?.version, 7)
        XCTAssertEqual(normal?.changeset, 11)

        let undoable = sync.mergeWays(localWay: way(tags: ["a": "orig"], changeset: 11), latestWay: latest, exclude_gig_tags: true, editedTags: ["a": "server"])
        XCTAssertEqual(undoable?.tags, ["a": "orig", "c": "server"])
        XCTAssertNil(sync.mergeWays(localWay: way(tags: ["a": "orig"], changeset: 11), latestWay: latest, exclude_gig_tags: true, editedTags: ["a": "edited"]))

        let nodeLocal = node(tags: ["kerb": "flush"], changeset: 12)
        let nodeLatest = OSMNode(type: "node", id: 900101, lat: 1, lon: 2, timestamp: Date(), version: 8, changeset: 1, user: "", uid: 0, tags: ["kerb": "raised", "x": "y"])
        let mergedNode = sync.mergeNodes(localNode: nodeLocal, latestNode: nodeLatest, exclude_gig_tags: false, editedTags: [:])
        XCTAssertEqual(mergedNode?.tags, ["kerb": "flush", "x": "y"])
        XCTAssertEqual(mergedNode?.changeset, 12)
        XCTAssertNil(sync.mergeNodes(localNode: nodeLocal, latestNode: nodeLatest, exclude_gig_tags: true, editedTags: ["kerb": "flush"]))
    }
}
