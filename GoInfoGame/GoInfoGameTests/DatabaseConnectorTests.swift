//
//  DatabaseConnectorTests.swift
//  GoInfoGameTests
//
//  The Realm-backed local store: elements saved from map data, tag edits, the changeset
//  (offline answer) queue, undo bookkeeping, and the note / feature draft queues. Element data
//  comes from the same LongFormOSMElements.json / MapOSMElements.json fixtures the UI tests use.
//

import XCTest
import CoreLocation
import RealmSwift
import osmapi
@testable import GoInfoGame

final class DatabaseConnectorElementTests: AppTestCase {

    private let db = DatabaseConnector.shared

    private func node(_ id: Int, lat: Double = 1, lon: Double = 2, tags: [String: String] = [:], version: Int = 1) -> OSMNode {
        OSMNode(type: "node", id: id, lat: lat, lon: lon, timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                version: version, changeset: 1, user: "u", uid: 1, tags: tags)
    }

    private func way(_ id: Int, nodes: [Int], tags: [String: String], version: Int = 1) -> OSMWay {
        OSMWay(type: "way", id: id, timestamp: Date(timeIntervalSince1970: 1_700_000_000), version: version,
               changeset: 1, user: "u", uid: 1, nodes: nodes, tags: tags)
    }

    // MARK: Saving map data

    func testSavingTheSharedFixtureStoresItsNodesAndTaggedWays() {
        seedMap("LongFormOSMElements")

        XCTAssertNotNil(db.getNode(id: 800010), "nodes without tags are stored too - ways need them for geometry")
        XCTAssertEqual(db.getNode(id: 900101)?.tags["barrier"], "kerb")
        XCTAssertEqual(db.getWay(id: 121949)?.tags["footway"], "sidewalk")
        XCTAssertEqual(db.getWay(id: 409776)?.tags["ext:obstruction"], "yes")
        XCTAssertEqual(db.getWay(id: 409776)?.version, 3)
        XCTAssertNil(db.getWay(id: 1), "an id that was never saved")
        XCTAssertNil(db.getNode(id: 1))
    }

    func testWaysWithoutTagsAreNotStored() {
        db.saveOSMElements([way(10, nodes: [1, 2], tags: [:]), way(11, nodes: [1, 2], tags: ["highway": "footway"])])
        XCTAssertNil(db.getWay(id: 10))
        XCTAssertNotNil(db.getWay(id: 11))
    }

    func testLinkWaysAreSkipped() {
        db.saveOSMElements([way(12, nodes: [], tags: ["highway": "footway", "ext:link": "true"]),
                            way(13, nodes: [], tags: ["highway": "footway", "ext:link": "false"])])
        XCTAssertNil(db.getWay(id: 12))
        XCTAssertNotNil(db.getWay(id: 13))
    }

    func testWayTagKeysContainingADotAreDropped() {
        db.saveOSMElements([way(14, nodes: [], tags: ["highway": "footway", "a.b": "x", "ext:ok": "y"])])
        let tags = db.getWay(id: 14)?.tags.toDictionary()
        XCTAssertEqual(tags, ["highway": "footway", "ext:ok": "y"], "Realm map keys cannot contain '.'")
    }

    func testSavingTheSameIdAgainUpdatesInPlace() {
        db.saveOSMElements([node(20, tags: ["a": "1"], version: 1)])
        db.saveOSMElements([node(20, tags: ["a": "2", "b": "3"], version: 2)])
        let stored = db.getNode(id: 20)
        XCTAssertEqual(stored?.version, 2)
        XCTAssertEqual(stored?.tags.toDictionary(), ["a": "2", "b": "3"])
        XCTAssertEqual(db.getNodes(NSPredicate(format: "id == 20")).count, 1)
    }

    func testAWayRecordsItsNodeIdsAndPolylineFromNodesInTheSameBatch() {
        db.saveOSMElements([node(30, lat: 10, lon: 20), node(31, lat: 12, lon: 24),
                            way(32, nodes: [30, 31, 999], tags: ["highway": "footway"])])
        let stored = db.getWay(id: 32)
        XCTAssertEqual(Array(stored?.nodes ?? List<Int64>()), [30, 31, 999])
        XCTAssertEqual(stored?.polyline.count, 2, "999 is not in the batch, so it has no coordinate")
        XCTAssertEqual(stored?.polyline.first?.latitude, 10)
        XCTAssertEqual(stored?.polyline.last?.longitude, 24)
    }

    func testPredicateQueriesFilterNodesAndWays() {
        seedMap("LongFormOSMElements")
        XCTAssertEqual(db.getNodes(NSPredicate(format: "tags.@count != 0")).count, 1, "only the kerb node carries tags")
        let sidewalks = db.getWays(NSPredicate(format: "tags.@count != 0"))
        XCTAssertEqual(sidewalks.count, 5)
        XCTAssertEqual(db.getWays(NSPredicate(format: "id == 409893")).first?.tags["footway"], "crossing")
    }

    func testStoredElementsConvertBackToParserElements() {
        db.saveOSMElements([node(40, lat: 3, lon: 4, tags: ["kerb": "raised"], version: 7),
                            way(41, nodes: [40], tags: ["highway": "footway"], version: 5)])
        let parsedNode = db.getNode(id: 40)?.asNode()
        XCTAssertEqual(parsedNode?.id, 40)
        XCTAssertEqual(parsedNode?.version, 7)
        XCTAssertEqual(parsedNode?.position.latitude, 3)
        XCTAssertEqual(parsedNode?.tags["kerb"], "raised")
        XCTAssertEqual(parsedNode?.timestampEdited, 1_700_000_000)

        let parsedWay = db.getWay(id: 41)?.asWay()
        XCTAssertEqual(parsedWay?.nodeIds, [40])
        XCTAssertEqual(parsedWay?.polyline.count, 1)
        XCTAssertEqual(parsedWay?.tags["highway"], "footway")
    }

    // MARK: Geometry

    func testCenterOfAWayIsTheMeanOfItsNodes() {
        db.saveOSMElements([node(50, lat: 10, lon: 20), node(51, lat: 14, lon: 28),
                            way(52, nodes: [50, 51], tags: ["highway": "footway"])])
        let center = db.getCenterForWay(id: 52)
        XCTAssertEqual(center?.latitude ?? 0, 12, accuracy: 1e-9)
        XCTAssertEqual(center?.longitude ?? 0, 24, accuracy: 1e-9)
    }

    func testCenterOfAFixtureWayLiesBetweenItsEndpoints() {
        seedMap("LongFormOSMElements")
        let stored = db.getWay(id: 121949)!
        let ends = stored.nodes.compactMap { self.db.getNode(id: Int($0)) }
        XCTAssertEqual(ends.count, 2)
        let center = db.getCenterForWay(id: 121949)!
        XCTAssertEqual(center.latitude, ends.map(\.latitude).reduce(0, +) / 2, accuracy: 1e-9)
        XCTAssertEqual(center.longitude, ends.map(\.longitude).reduce(0, +) / 2, accuracy: 1e-9)
    }

    func testCenterOfAnUnknownWayIsNilAndOfAWayWithoutKnownNodesIsTheOrigin() {
        XCTAssertNil(db.getCenterForWay(id: 777))
        db.saveOSMElements([way(53, nodes: [8001, 8002], tags: ["highway": "footway"])])
        let center = db.getCenterForWay(id: 53)
        XCTAssertEqual(center?.latitude, 0)
        XCTAssertEqual(center?.longitude, 0)
    }

    // MARK: Editing tags

    func testAddingNodeTagsReplacesTheSetAndDropsEmptyValues() {
        db.saveOSMElements([node(60, tags: ["old": "x", "keep": "k"], version: 1)])
        let stamp = Date(timeIntervalSince1970: 1_800_000_000)

        let updated = db.addNodeTags(id: 60, tags: ["keep": "k2", "cleared": "", "new": "n"], version: 2, timestamp: stamp)

        XCTAssertEqual(updated?.tags.toDictionary(), ["keep": "k2", "new": "n"])
        XCTAssertEqual(db.getNode(id: 60)?.version, 2)
        XCTAssertEqual(db.getNode(id: 60)?.timestamp, stamp)
    }

    func testAddingWayTagsMirrorsTheNodeBehaviour() {
        db.saveOSMElements([way(61, nodes: [], tags: ["highway": "footway", "old": "x"], version: 1)])
        let original = db.getWay(id: 61)?.timestamp

        let updated = db.addWayTags(id: 61, tags: ["highway": "footway", "gone": ""], version: 4)

        XCTAssertEqual(updated?.tags.toDictionary(), ["highway": "footway"])
        XCTAssertEqual(db.getWay(id: 61)?.version, 4)
        XCTAssertEqual(db.getWay(id: 61)?.timestamp, original, "no timestamp given -> the stored one is kept")
    }

    func testEditingAnUnknownElementReturnsNil() {
        XCTAssertNil(db.addNodeTags(id: 9, tags: ["a": "b"], version: 1))
        XCTAssertNil(db.addWayTags(id: 9, tags: ["a": "b"], version: 1))
        XCTAssertNil(db.updateNodeVersion(nodeId: "9", version: 3))
        XCTAssertNil(db.updateWayVersion(wayId: "9", version: 3))
        XCTAssertNil(db.updateNodeVersion(nodeId: "not-a-number", version: 3))
    }

    func testVersionBumps() {
        db.saveOSMElements([node(62, tags: ["a": "b"]), way(63, nodes: [], tags: ["highway": "footway"])])
        XCTAssertEqual(db.updateNodeVersion(nodeId: "62", version: 9)?.version, 9)
        XCTAssertEqual(db.updateWayVersion(wayId: "63", version: 8)?.version, 8)
        XCTAssertEqual(db.getNode(id: 62)?.version, 9)
        XCTAssertEqual(db.getWay(id: 63)?.version, 8)
    }

    // MARK: Deleting

    func testDeletingElements() {
        db.saveOSMElements([node(70), way(71, nodes: [], tags: ["highway": "footway"])])
        db.deleteNode(id: 70)
        db.deleteWay(id: 71)
        XCTAssertNil(db.getNode(id: 70))
        XCTAssertNil(db.getWay(id: 71))
        db.deleteNode(id: 70)   // already gone: harmless
        db.deleteWay(id: 71)
    }

    func testClearingTheDatabaseRemovesEverything() {
        seedMap("LongFormOSMElements")
        db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "notes")
        db.upsertNoteDraft(id: "n", noteText: "x", imagePaths: [], coordinates: .init(latitude: 1, longitude: 1))
        db.upsertFeatureDraft(id: "f", presetName: "Bench", iconName: "i", tags: ["a": "b"], imagePaths: [], coordinates: .init(latitude: 1, longitude: 1))

        db.clearDB()

        XCTAssertEqual(db.getNodes(NSPredicate(value: true)).count, 0)
        XCTAssertEqual(db.getWays(NSPredicate(value: true)).count, 0)
        XCTAssertEqual(db.getChangesets().count, 0)
        XCTAssertEqual(db.pendingNoteDraftsCount(), 0)
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 0)
    }

    func testLegacyElementStorageSavesWaysWithTagsAndNodes() throws {
        let legacy = way(80, nodes: [1, 2], tags: ["highway": "footway", "name": "Main"], version: 3)
        db.saveElements([legacy])
        let realm = try Realm(configuration: RealmConfig.configuration)
        let stored = try XCTUnwrap(realm.objects(RealmOPElement.self).first)
        XCTAssertEqual(stored.id, 80)
        XCTAssertEqual(stored.tags.count, 2)
        XCTAssertEqual(Array(stored.nodes), [1, 2])
    }
}

// MARK: - Changesets (the offline answer queue)

final class DatabaseConnectorChangesetTests: AppTestCase {

    private let db = DatabaseConnector.shared

    @discardableResult
    private func makeWayChangeset(id: Int = 121949, tags: [String: String] = ["ext:surface": "concrete"],
                                  originalTags: [String: String] = ["ext:surface": "asphalt", "highway": "footway"],
                                  version: Int = 1, pendingImage: (String, String)? = nil) -> StoredChangeset {
        db.createChangeset(id: id, questType: "Sidewalks", type: .way, originalTags: originalTags, tags: tags, version: version,
                           iconName: "sidewalk_surface", nodes: List<Int64>(), pendingImagePath: pendingImage?.0, pendingImageTagKey: pendingImage?.1)!
    }

    func testANewChangesetIsPendingWithItsTagsAndOriginals() {
        let changeset = makeWayChangeset()
        XCTAssertEqual(changeset.elementId, 121949)
        XCTAssertEqual(changeset.elementType, .way)
        XCTAssertEqual(changeset.questType, "Sidewalks")
        XCTAssertEqual(changeset.iconName, "sidewalk_surface")
        XCTAssertEqual(changeset.tags.toDictionary(), ["ext:surface": "concrete"])
        XCTAssertEqual(changeset.originalTags["ext:surface"], "asphalt")
        XCTAssertEqual(changeset.changesetId, -1)
        XCTAssertEqual(changeset.updatedVersion, -1)
        XCTAssertFalse(changeset.isCreatedElement)
        XCTAssertFalse(changeset.isUndoCompleted)
        XCTAssertGreaterThan(Double(changeset.timestamp) ?? 0, 0)
    }

    func testAChangesetCanCarryAPointAndANodeList() {
        let nodes = List<Int64>(); nodes.append(objectsIn: [5, 6])
        let changeset = db.createChangeset(id: 1, questType: "Kerbs", type: .node, originalTags: [:], tags: ["kerb": "raised"], version: 2,
                                           iconName: "kerb", point: CLLocationCoordinate2D(latitude: 17.4, longitude: 78.3), nodes: nodes)!
        XCTAssertEqual(changeset.point.latitude, 17.4)
        XCTAssertEqual(Array(changeset.nodes), [5, 6])
    }

    func testPendingVersusSyncedFiltering() {
        let pending = makeWayChangeset(id: 1)
        let done = makeWayChangeset(id: 2)
        _ = db.assignChangesetId(obj: done.id, changesetId: 900, updatedVersion: 4)

        XCTAssertEqual(db.getChangesets().map(\.id), [pending.id])
        XCTAssertEqual(db.getChangesets(synced: false).count, 1)
        XCTAssertEqual(db.getChangesets(synced: true).map(\.id), [done.id])
        XCTAssertEqual(db.getChangeset(for: done.id)?.changesetId, 900)
        XCTAssertEqual(db.getChangeset(for: done.id)?.updatedVersion, 4)
        XCTAssertNil(db.getChangeset(for: "nope"))
    }

    func testFilteringChangesetsByElementType() {
        makeWayChangeset(id: 1)
        _ = db.createChangeset(id: 2, questType: "Kerbs", type: .node, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "k")
        XCTAssertEqual(db.getChangesets(synced: false, element: .way).map(\.elementId), [1])
        XCTAssertEqual(db.getChangesets(synced: false, element: .node).map(\.elementId), [2])
        XCTAssertTrue(db.getChangesets(synced: true, element: .way).isEmpty)
    }

    func testAssigningAnIdToAnUnknownChangesetReturnsNil() {
        XCTAssertNil(db.assignChangesetId(obj: "missing", changesetId: 1, updatedVersion: 1))
        XCTAssertNil(db.updateChangesetWithUndoResultSuccess(obj: "missing"))
    }

    func testRecordingASuccessfulUndo() {
        let changeset = makeWayChangeset()
        _ = db.assignChangesetId(obj: changeset.id, changesetId: 0, updatedVersion: 2)
        let updated = db.updateChangesetWithUndoResultSuccess(obj: changeset.id)
        XCTAssertEqual(updated?.isUndoCompleted, true)
        XCTAssertNotNil(updated?.undoOn)
    }

    func testDeletingAnElementsChangesets() {
        makeWayChangeset(id: 5)
        makeWayChangeset(id: 5, tags: ["x": "y"])
        makeWayChangeset(id: 6)
        db.deleteChangesets(elementId: 5)
        XCTAssertEqual(db.getChangesets().map(\.elementId), [6])
        db.deleteChangesets(elementId: 12345)   // nothing to delete: harmless
        XCTAssertEqual(db.getChangesets().count, 1)
    }

    func testAChangesetForANewlyCreatedElementIsBornSyncedAndUndoable() {
        let created = db.createChangesetForNewElement(id: 9001, questType: "Bench", tags: ["amenity": "bench"], version: 1,
                                                      iconName: "preset_temaki_bench", point: CLLocationCoordinate2D(latitude: 1, longitude: 2))!
        XCTAssertTrue(created.isCreatedElement)
        XCTAssertEqual(created.elementType, .node)
        XCTAssertEqual(created.changesetId, 0, "the 'synced, undoable' sentinel MapUndoManager looks for")
        XCTAssertEqual(created.updatedVersion, 1)
        XCTAssertEqual(created.originalTags.count, 0)
        XCTAssertEqual(created.tags["amenity"], "bench")
        XCTAssertTrue(db.getChangesets().isEmpty, "a create must never land in the pending-edit queue")
        XCTAssertEqual(db.getChangesets(synced: true).count, 1)
    }

    // MARK: Pending-answer queue snapshots

    func testPendingSnapshotsListOnlyUnsyncedAnswersOldestFirst() throws {
        let first = makeWayChangeset(id: 1)
        Thread.sleep(forTimeInterval: 0.01)   // timestamps are second-fractions as strings
        let second = makeWayChangeset(id: 2)
        let synced = makeWayChangeset(id: 3)
        _ = db.assignChangesetId(obj: synced.id, changesetId: 0, updatedVersion: 3)

        let pending = db.pendingChangesets()

        XCTAssertEqual(pending.map(\.id), [first.id, second.id])
        let snapshot = try XCTUnwrap(pending.first)
        XCTAssertEqual(snapshot.elementId, 1)
        XCTAssertEqual(snapshot.elementType, .way)
        XCTAssertEqual(snapshot.questType, "Sidewalks")
        XCTAssertEqual(snapshot.tags, ["ext:surface": "concrete"])
        XCTAssertEqual(snapshot.originalTags["ext:surface"], "asphalt")
        XCTAssertEqual(snapshot.retryCount, 0)
    }

    func testSnapshotsMergeOriginalTagsUnderTheAnswersForTheUploadPayload() {
        let snapshot = db.getChangeset(for: makeWayChangeset().id).map { _ in db.pendingChangesets().first! }!
        let way = snapshot.asOSMWay(tags: ["ext:surface": "gravel", "width": "40"])
        XCTAssertEqual(way.tags["ext:surface"], "gravel", "the answer wins over the original")
        XCTAssertEqual(way.tags["highway"], "footway", "untouched originals are preserved")
        XCTAssertEqual(way.tags["width"], "40")
        XCTAssertEqual(way.id, 121949)
        XCTAssertEqual(way.changeset, -1)

        let node = snapshot.asOSMNode(tags: ["a": "b"])
        XCTAssertEqual(node.tags["a"], "b")
        XCTAssertEqual(node.id, 121949)
    }

    func testStoredChangesetsBuildPayloadElementsForSyncAndUndo() {
        let changeset = makeWayChangeset(version: 3)
        _ = db.assignChangesetId(obj: changeset.id, changesetId: 0, updatedVersion: 4)

        let forSync = changeset.asOSMWay()
        XCTAssertEqual(forSync.tags["ext:surface"], "concrete")
        XCTAssertEqual(forSync.version, 3)

        let forUndo = changeset.asOSMWay(isUndo: true)
        XCTAssertEqual(forUndo.tags["ext:surface"], "asphalt", "undo restores the original tags")
        XCTAssertEqual(forUndo.version, 4, "undo is submitted against the version the edit produced")

        let nodeChangeset = db.createChangeset(id: 5, questType: "Kerbs", type: .node, originalTags: ["kerb": "flush"], tags: ["kerb": "raised"],
                                               version: 2, iconName: "k", point: CLLocationCoordinate2D(latitude: 1, longitude: 2))!
        XCTAssertEqual(nodeChangeset.asOSMNode().tags["kerb"], "raised")
        XCTAssertEqual(nodeChangeset.asOSMNode(isUndo: true).tags["kerb"], "flush")
        XCTAssertEqual(nodeChangeset.asOSMNode().lat, 1)
    }

    func testAttachingAnUploadedPhotoURLClearsThePendingPhoto() {
        let changeset = makeWayChangeset(pendingImage: ("/tmp/photo.jpg", "ext:kartaview_url"))
        XCTAssertEqual(changeset.pendingImagePath, "/tmp/photo.jpg")
        XCTAssertEqual(db.pendingChangesets().first?.pendingImageTagKey, "ext:kartaview_url")

        db.attachUploadedPhotoURL(id: changeset.id, tagKey: "ext:kartaview_url", url: "https://cdn/x.jpg")

        let stored = db.getChangeset(for: changeset.id)
        XCTAssertEqual(stored?.tags["ext:kartaview_url"], "https://cdn/x.jpg")
        XCTAssertNil(stored?.pendingImagePath)
        XCTAssertNil(stored?.pendingImageTagKey)
    }

    func testFailedAttemptsAreCountedAndKeepTheAnswerQueued() {
        let changeset = makeWayChangeset()
        db.markChangesetFailed(id: changeset.id, error: "offline")
        db.markChangesetFailed(id: changeset.id, error: "still offline")
        let stored = db.getChangeset(for: changeset.id)
        XCTAssertEqual(stored?.retryCount, 2)
        XCTAssertEqual(stored?.lastError, "still offline")
        XCTAssertEqual(db.pendingChangesets().first?.retryCount, 2)
        db.markChangesetFailed(id: "missing", error: "ignored")   // unknown id: harmless
    }

    func testAPhotoIsOnlyConsideredStuckAfterThreeFailures() {
        let changeset = makeWayChangeset(id: 77, pendingImage: ("/tmp/p.jpg", "ext:kartaview_url"))
        XCTAssertNil(db.stuckPhotoChangeset(elementId: 77))
        db.markChangesetFailed(id: changeset.id, error: "1")
        db.markChangesetFailed(id: changeset.id, error: "2")
        XCTAssertNil(db.stuckPhotoChangeset(elementId: 77))
        db.markChangesetFailed(id: changeset.id, error: "3")
        XCTAssertEqual(db.stuckPhotoChangeset(elementId: 77)?.id, changeset.id)
        XCTAssertNil(db.stuckPhotoChangeset(elementId: 78), "a different element")
    }

    func testFailuresWithoutAPhotoNeverCountAsAStuckPhoto() {
        let changeset = makeWayChangeset(id: 79)
        for _ in 0..<5 { db.markChangesetFailed(id: changeset.id, error: "x") }
        XCTAssertNil(db.stuckPhotoChangeset(elementId: 79))
    }

    func testSkippingThePhotoReturnsItsPathAndLetsTheTagsSync() {
        let changeset = makeWayChangeset(pendingImage: ("/tmp/skip.jpg", "ext:kartaview_url"))
        XCTAssertEqual(db.skipPendingPhoto(id: changeset.id), "/tmp/skip.jpg")
        XCTAssertNil(db.getChangeset(for: changeset.id)?.pendingImagePath)
        XCTAssertNil(db.skipPendingPhoto(id: changeset.id), "nothing left to skip")
        XCTAssertNil(db.skipPendingPhoto(id: "missing"))
    }
}

// MARK: - Offline drafts (notes and features)

final class DatabaseConnectorDraftTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private let here = CLLocationCoordinate2D(latitude: 17.4385, longitude: 78.361)

    func testNoteDraftsRoundTripAndKeepInsertionOrder() {
        db.upsertNoteDraft(id: "a", noteText: "first", imagePaths: ["/p/1.jpg", "/p/2.jpg"], coordinates: here)
        Thread.sleep(forTimeInterval: 0.01)
        db.upsertNoteDraft(id: "b", noteText: "second", imagePaths: [], coordinates: here)

        let pending = db.pendingNoteDrafts()
        XCTAssertEqual(pending.map(\.id), ["a", "b"])
        XCTAssertEqual(pending[0].noteText, "first")
        XCTAssertEqual(pending[0].imagePaths, ["/p/1.jpg", "/p/2.jpg"])
        XCTAssertEqual(pending[0].coordinates.latitude, 17.4385)
        XCTAssertEqual(db.pendingNoteDraftsCount(), 2)
        XCTAssertEqual(db.noteDraftImagePaths(id: "a"), ["/p/1.jpg", "/p/2.jpg"])
        XCTAssertEqual(db.noteDraftImagePaths(id: "missing"), [])
    }

    func testUpsertingAnExistingNoteDraftOverwritesIt() {
        db.upsertNoteDraft(id: "a", noteText: "v1", imagePaths: ["/p/1.jpg"], coordinates: here)
        db.upsertNoteDraft(id: "a", noteText: "v2", imagePaths: [], coordinates: here)
        XCTAssertEqual(db.pendingNoteDraftsCount(), 1)
        XCTAssertEqual(db.pendingNoteDrafts().first?.noteText, "v2")
        XCTAssertEqual(db.noteDraftImagePaths(id: "a"), [])
    }

    func testFailedNoteAttemptsAreRecordedAndTheDraftSurvives() throws {
        db.upsertNoteDraft(id: "a", noteText: "x", imagePaths: [], coordinates: here)
        db.markNoteDraftFailed(id: "a", error: "boom")
        db.markNoteDraftFailed(id: "a", error: "boom again")
        let realm = try Realm(configuration: RealmConfig.configuration)
        let stored = try XCTUnwrap(realm.object(ofType: StoredNoteDraft.self, forPrimaryKey: "a"))
        XCTAssertEqual(stored.retryCount, 2)
        XCTAssertEqual(stored.lastError, "boom again")
        db.markNoteDraftFailed(id: "missing", error: "ignored")
    }

    func testDeletingANoteDraft() {
        db.upsertNoteDraft(id: "a", noteText: "x", imagePaths: [], coordinates: here)
        db.deleteNoteDraft(id: "a")
        db.deleteNoteDraft(id: "a")   // already gone: harmless
        XCTAssertEqual(db.pendingNoteDraftsCount(), 0)
    }

    func testFeatureDraftsRoundTripWithTheirTags() {
        db.upsertFeatureDraft(id: "f1", presetName: "Bench", iconName: "preset_temaki_bench",
                              tags: ["amenity": "bench", "ext:notes": "rusty"], imagePaths: ["/p/b.jpg"], coordinates: here)
        let pending = db.pendingFeatureDrafts()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending[0].presetName, "Bench")
        XCTAssertEqual(pending[0].iconName, "preset_temaki_bench")
        XCTAssertEqual(pending[0].tags, ["amenity": "bench", "ext:notes": "rusty"])
        XCTAssertEqual(pending[0].imagePaths, ["/p/b.jpg"])
        XCTAssertEqual(pending[0].coordinates.longitude, 78.361)
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 1)
        XCTAssertEqual(db.featureDraftImagePaths(id: "f1"), ["/p/b.jpg"])
        XCTAssertEqual(db.featureDraftImagePaths(id: "nope"), [])
    }

    func testFeatureDraftRetryBookkeepingAndDeletion() throws {
        db.upsertFeatureDraft(id: "f1", presetName: "Bench", iconName: "i", tags: [:], imagePaths: [], coordinates: here)
        db.markFeatureDraftFailed(id: "f1", error: "offline")
        let realm = try Realm(configuration: RealmConfig.configuration)
        let stored = try XCTUnwrap(realm.object(ofType: StoredFeatureDraft.self, forPrimaryKey: "f1"))
        XCTAssertEqual(stored.retryCount, 1)
        XCTAssertEqual(stored.lastError, "offline")
        db.markFeatureDraftFailed(id: "missing", error: "ignored")

        db.deleteFeatureDraft(id: "f1")
        db.deleteFeatureDraft(id: "f1")
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 0)
    }

    func testUpsertingAFeatureDraftOverwritesTheEarlierAttempt() {
        db.upsertFeatureDraft(id: "f1", presetName: "Bench", iconName: "i", tags: ["a": "1"], imagePaths: [], coordinates: here)
        db.upsertFeatureDraft(id: "f1", presetName: "Bench", iconName: "i", tags: ["a": "2"], imagePaths: [], coordinates: here)
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 1)
        XCTAssertEqual(db.pendingFeatureDrafts().first?.tags["a"], "2")
    }
}
