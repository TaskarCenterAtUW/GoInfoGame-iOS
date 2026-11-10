//
//  SubmissionManagerTests.swift
//  GoInfoGameTests
//
//  The three offline-first submission queues - quest answers (QuestSubmissionManager), notes
//  (NotesSubmissionManager) and Add Feature (FeatureSubmissionManager) - plus Panoramax photo
//  uploads and the on-disk image stores. Each queue persists first, then drains in the
//  background and reports through MapViewPublisher.dismissSheet, so these tests drive a
//  submission and wait on those same events. Elements and server responses come from the UI
//  tests' fixtures (LongFormOSMElements.json, WorkspaceDetailsWithQuests.json, ...).
//

import XCTest
import CoreLocation
import RealmSwift
import osmapi
import osmparser
@testable import GoInfoGame

// MARK: - Panoramax photo upload

final class PanoramaxUploaderTests: AppTestCase {

    private let spot = CLLocationCoordinate2D(latitude: 47.6553, longitude: -122.3035)
    // ASCII stand-in for JPEG bytes, so the recorded multipart body stays readable as text.
    private let photo = Data("jpeg-bytes".utf8)

    private var uploader: PanoramaxUploader { PhotoUploadService.makePanoramaxUploader() }

    func testAnUploadReturnsTheHostedPhotoURL() async throws {
        MockServer.installPanoramax(.ok)
        let url = try await uploader.upload(imageData: photo, coordinate: spot)
        XCTAssertEqual(url, MockServer.panoramaxPhotoURL)
    }

    func testTheUploadSetHoldsOnePhotoThatIsNeverSplitOrDeduplicated() async throws {
        MockServer.installPanoramax(.ok)
        _ = try await uploader.upload(imageData: photo, coordinate: spot)

        let create = try XCTUnwrap(MockHTTP.requests(path: "/api/upload_sets", method: "POST").first)
        XCTAssertEqual(create.header("Authorization"), "Bearer \(MockServer.panoramaxToken)")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: try XCTUnwrap(create.body)) as? [String: Any])
        XCTAssertEqual(json["estimated_nb_files"] as? Int, 1)
        XCTAssertEqual(json["no_split"] as? Bool, true)
        XCTAssertEqual(json["no_deduplication"] as? Bool, true)
        XCTAssertEqual(json["visibility"] as? String, "anyone")
    }

    func testThePhotoIsSentWithItsLocationAndCaptureTime() async throws {
        MockServer.installPanoramax(.ok)
        let capturedAt = Date(timeIntervalSince1970: 1_793_000_000)
        _ = try await uploader.upload(imageData: photo, coordinate: spot, capturedAt: capturedAt)

        let file = try XCTUnwrap(MockHTTP.requests(path: MockServer.panoramaxFilesPath, method: "POST").first)
        XCTAssertEqual(file.header("Authorization"), "Bearer \(MockServer.panoramaxToken)")
        let body = file.bodyString
        XCTAssertTrue(body.contains("name=\"override_latitude\"\r\n\r\n47.6553\r\n"))
        XCTAssertTrue(body.contains("name=\"override_longitude\"\r\n\r\n-122.3035\r\n"))
        XCTAssertTrue(body.contains("name=\"override_capture_time\"\r\n\r\n\(ISO8601DateFormatter().string(from: capturedAt))\r\n"))
        XCTAssertTrue(body.contains("Content-Type: image/jpeg\r\n\r\njpeg-bytes\r\n"))
        XCTAssertFalse(body.contains("name=\"semantics\""), "no semantics field without context")
    }

    func testThePhotoCarriesItsContextAsSemantics() async throws {
        MockServer.installPanoramax(.ok)
        let context = PhotoUploadContext(workspaceId: "222", elementId: "way/121949", question: "What is the surface?",
                                         questId: 7)
        _ = try await uploader.upload(imageData: photo, coordinate: spot, semantics: context.semantics)

        let file = try XCTUnwrap(MockHTTP.requests(path: MockServer.panoramaxFilesPath, method: "POST").first)
        let body = file.bodyString
        let marker = "name=\"semantics\"\r\n\r\n"
        let start = try XCTUnwrap(body.range(of: marker)).upperBound
        // "\r\n" is one Character in Swift, so find the end by range, not by Character.
        let end = try XCTUnwrap(body.range(of: "\r\n", range: start..<body.endIndex)).lowerBound
        let json = String(body[start..<end])
        let tags = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: String]])
        XCTAssertEqual(tags, [
            ["key": "workspace_id", "value": "222"],
            ["key": "element_id", "value": "way/121949"],
            ["key": "quest_id", "value": "7"],
            ["key": "question", "value": "What is the surface?"]
        ])
    }

    func testEmptyContextFieldsAreLeftOutOfTheSemantics() {
        let context = PhotoUploadContext(workspaceId: "222", elementId: "", question: "  ")
        XCTAssertEqual(context.semantics, [["key": "workspace_id", "value": "222"]])
    }

    func testARejectedPhotoThrowsTheReasonEvenThoughTheStatusIs202() async {
        MockServer.installPanoramax(.rejected)
        do {
            _ = try await uploader.upload(imageData: photo, coordinate: spot)
            XCTFail("a rejected photo must not return a URL")
        } catch {
            XCTAssertEqual(error as? PanoramaxError, .rejected("No GPS coordinates"))
        }
    }

    func testAnInvalidTokenThrowsTheServerMessageAndUploadsNothing() async {
        MockServer.installPanoramax(.unauthorized)
        do {
            _ = try await uploader.upload(imageData: photo, coordinate: spot)
            XCTFail("an unauthorized upload must fail")
        } catch {
            XCTAssertEqual(error as? PanoramaxError, .server(status: 401, message: "Token not valid"))
        }
        XCTAssertTrue(MockHTTP.requests(path: MockServer.panoramaxFilesPath).isEmpty)
    }

    func testAMissingTokenFailsWithoutAnyRequest() async {
        MockServer.installPanoramax(.ok)
        do {
            _ = try await PanoramaxUploader(baseURL: MockServer.panoramaxBaseURL, token: "").upload(imageData: photo, coordinate: spot)
            XCTFail("an upload without a token must fail")
        } catch {
            XCTAssertEqual(error as? PanoramaxError, .missingToken)
        }
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testTheServiceSendsPhotosToPanoramax() async throws {
        MockServer.installPanoramax(.ok)
        let url = try await PhotoUploadService.upload(makeImage(), coordinate: spot)

        XCTAssertEqual(url, MockServer.panoramaxPhotoURL)
        let file = try XCTUnwrap(MockHTTP.requests(path: MockServer.panoramaxFilesPath).first)
        XCTAssertTrue(file.header("Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
    }
}

// MARK: - On-disk image stores

final class ImageStorageTests: AppTestCase {

    private func exercise(save: (UIImage) throws -> String, load: (String) -> UIImage?, delete: ([String]) -> Void) throws {
        let path = try save(makeImage(.blue, side: 16))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        XCTAssertTrue(path.hasSuffix(".jpg"))
        XCTAssertEqual(load(path)?.size.width, 16)

        let other = try save(makeImage())
        XCTAssertNotEqual(path, other, "every save gets its own file")

        delete([path, other, "/nonexistent/file.jpg"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: other))
        XCTAssertNil(load(path))
    }

    func testQuestImages() throws {
        try exercise(save: QuestImageStorage.shared.save, load: QuestImageStorage.shared.load(path:), delete: QuestImageStorage.shared.delete(paths:))
    }

    func testNoteImages() throws {
        try exercise(save: NoteImageStorage.shared.save, load: NoteImageStorage.shared.load(path:), delete: NoteImageStorage.shared.delete(paths:))
    }

    func testFeatureImages() throws {
        try exercise(save: FeatureImageStorage.shared.save, load: FeatureImageStorage.shared.load(path:), delete: FeatureImageStorage.shared.delete(paths:))
    }

    func testAnImageWithNoPixelDataCannotBeSaved() {
        XCTAssertThrowsError(try QuestImageStorage.shared.save(UIImage()))
        XCTAssertThrowsError(try NoteImageStorage.shared.save(UIImage()))
        XCTAssertThrowsError(try FeatureImageStorage.shared.save(UIImage()))
    }

    func testFileStorageRoundTripsTheLongFormDefinition() throws {
        let workspace = try JSONDecoder().decode(Workspace.self, from: MockHTTP.fixture("WorkspaceDetailsWithQuests"))
        let elements = try XCTUnwrap(workspace.longFormQuest?.elements)
        try FileStorageManager.shared.save(questModels: elements, to: "unit-test-quests")
        let loaded = try XCTUnwrap(FileStorageManager.shared.load(from: "unit-test-quests"))
        XCTAssertEqual(loaded.map(\.elementType), ["Sidewalks", "Crossings", "Kerbs"])
        XCTAssertEqual(loaded.first?.quests.count, elements.first?.quests.count)

        try FileStorageManager.shared.delete(fileName: "unit-test-quests")
        XCTAssertNil(try FileStorageManager.shared.load(from: "unit-test-quests"))
        XCTAssertNoThrow(try FileStorageManager.shared.delete(fileName: "unit-test-quests"), "deleting a missing file is not an error")
    }
}

// MARK: - Quest answers (QuestSubmissionManager)

final class QuestSubmissionManagerTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private var events: SheetEvents!

    override func setUp() {
        super.setUp()
        signIn(workspaceID: "222")
        seedMap("LongFormOSMElements")
        MockServer.installChangesets()
        MockServer.installLatestElements()
        events = recordSheetEvents()
    }

    private func submitSidewalk(tags: [String: String] = ["ext:surface": "concrete"], image: UIImage? = nil, imageTagKey: String? = nil,
                                imageQuestion: String? = nil, imageQuestId: Int? = nil) {
        QuestSubmissionManager.submit(id: 121949, questType: "Sidewalks", tags: tags, type: .way, iconName: "sidewalk_surface",
                                      capturedImage: image, imageTagKey: imageTagKey, imageQuestion: imageQuestion, imageQuestId: imageQuestId)
    }

    private func waitForDrain(_ message: String = "queue never finished draining") {
        waitUntil(timeout: 10, message) { events.contains("synced") }
    }

    func testAnAnswerIsPersistedThenSyncedAndAnnounced() {
        submitSidewalk()
        waitForDrain()

        XCTAssertEqual(Array(events.names.prefix(2)), ["syncBackground", "syncing"])
        XCTAssertTrue(events.names.contains("answerSynced"))
        XCTAssertEqual(events.names.last, "synced")

        let synced = db.getChangesets(synced: true)
        XCTAssertEqual(synced.count, 1)
        XCTAssertEqual(synced.first?.elementId, 121949)
        XCTAssertEqual(synced.first?.tags["ext:surface"], "concrete")
        XCTAssertEqual(synced.first?.originalTags["footway"], "sidewalk", "the way's tags at answer time are kept for undo")
        XCTAssertEqual(synced.first?.updatedVersion, 2)
        XCTAssertEqual(db.getWay(id: 121949)?.tags["ext:surface"], "concrete", "the local cache reflects the sync")
        XCTAssertTrue(db.getChangesets().isEmpty)
    }

    func testANodeAnswerFollowsTheSamePath() {
        QuestSubmissionManager.submit(id: 900101, questType: "Kerbs", tags: ["kerb": "flush"], type: .node, iconName: "kerb",
                                      capturedImage: nil, imageTagKey: nil)
        waitForDrain()
        let synced = db.getChangesets(synced: true, element: .node)
        XCTAssertEqual(synced.count, 1)
        XCTAssertEqual(synced.first?.point.latitude ?? 0, db.getNode(id: 900101)?.latitude ?? -1, accuracy: 1e-9)
        XCTAssertEqual(db.getNode(id: 900101)?.tags["kerb"], "flush")
    }

    func testAnAnswerForAnUnknownElementIsDroppedSilently() {
        QuestSubmissionManager.submit(id: 31337, questType: "Sidewalks", tags: ["a": "b"], type: .way, iconName: "i", capturedImage: nil, imageTagKey: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertTrue(events.names.isEmpty)
        XCTAssertTrue(db.getChangesets().isEmpty)
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testAnAnswerSubmittedOfflineStaysQueuedAndRetriesLater() {
        MockHTTP.reset()
        MockServer.installChangesets(createFails: true)
        MockServer.installLatestElements()
        submitSidewalk()
        waitForDrain()

        let pending = db.getChangesets()
        XCTAssertEqual(pending.count, 1, "still queued")
        XCTAssertEqual(pending.first?.retryCount, 1)
        XCTAssertNotNil(pending.first?.lastError)
        XCTAssertFalse(events.contains("answerSynced"))

        // Connectivity returns; the sync button / app foreground resumes the queue.
        MockHTTP.reset()
        MockServer.installChangesets()
        MockServer.installLatestElements()
        QuestSubmissionManager.resumePendingUploads()
        waitUntil(timeout: 10, "the queued answer was never retried") { events.contains("answerSynced") }
        waitUntil(timeout: 10, "the retried answer was never cleared from the queue") { db.getChangesets().isEmpty }
        XCTAssertTrue(db.getChangesets().isEmpty)
    }

    func testResumingAnEmptyQueueDoesNothing() async {
        await QuestSubmissionManager.resumePendingUploadsAsync()
        QuestSubmissionManager.resumePendingUploads()
        XCTAssertTrue(events.names.isEmpty)
    }

    func testResumingDrainsTheQueueAndAwaitsCompletion() async {
        db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: ["footway": "sidewalk", "highway": "footway"],
                           tags: ["ext:surface": "gravel"], version: 1, iconName: "i")
        await QuestSubmissionManager.resumePendingUploadsAsync()
        XCTAssertEqual(db.getChangesets(synced: true).count, 1)
        XCTAssertEqual(events.names, ["syncing", "answerSynced", "synced"])
    }

    func testADeclinedConflictCountsAsAFailedAttemptAndStaysQueued() {
        MockHTTP.reset()
        MockServer.installChangesets(upload: .conflict(times: 1))
        MockServer.installLatestElements()
        MapViewPublisher.shared.conflictDetected.sink { $0.resolve(.cancelled) }.store(in: &cancellables)
        submitSidewalk()
        waitForDrain()
        let pending = db.getChangesets()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.lastError, "Submission failed. Please try again.")
    }

    func testSeveralAnswersSubmittedTogetherAreAllDrained() {
        // A multi-select answer fires one submit per element in a tight loop.
        QuestSubmissionManager.submit(id: 121949, questType: "Sidewalks", tags: ["ext:surface": "concrete"], type: .way, iconName: "i", capturedImage: nil, imageTagKey: nil)
        QuestSubmissionManager.submit(id: 409776, questType: "Sidewalks", tags: ["ext:surface": "gravel"], type: .way, iconName: "i", capturedImage: nil, imageTagKey: nil)
        QuestSubmissionManager.submit(id: 409893, questType: "Crossings", tags: ["crossing:markings": "yes"], type: .way, iconName: "i", capturedImage: nil, imageTagKey: nil)
        waitUntil(timeout: 15, "not every answer synced") { db.getChangesets(synced: true).count == 3 }
        XCTAssertTrue(db.getChangesets().isEmpty)
    }

    // MARK: Photos

    func testAnAttachedPhotoIsUploadedFirstAndItsURLBecomesATag() throws {
        MockServer.installPanoramax(.ok)
        submitSidewalk(image: makeImage(), imageTagKey: PhotoTag.streetImages)
        waitUntil(timeout: 15, "the answer never synced") { events.contains("answerSynced") }

        let synced = try XCTUnwrap(db.getChangesets(synced: true).first)
        XCTAssertEqual(synced.tags[PhotoTag.streetImages], MockServer.panoramaxPhotoURL)
        XCTAssertNil(synced.pendingImagePath)
        let upload = try XCTUnwrap(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).first)
        XCTAssertTrue(upload.bodyString.contains(MockServer.panoramaxPhotoURL), "the photo URL is part of the uploaded tags")
    }

    func testAPhotoThatFailsToUploadKeepsTheAnswerQueuedAndWarnsTheUser() throws {
        MockServer.installPanoramax(.unauthorized)
        submitSidewalk(image: makeImage(), imageTagKey: PhotoTag.streetImages)
        waitForDrain()

        let pending = try XCTUnwrap(db.getChangesets().first)
        XCTAssertNotNil(pending.pendingImagePath, "the photo is kept for the retry")
        XCTAssertEqual(pending.retryCount, 1)
        XCTAssertTrue(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).isEmpty, "tags are not synced without their photo")
        guard case .questPhotoUploadFailed(let name, let message)? = events.events.first(where: { SheetEvents.name($0) == "questPhotoUploadFailed" }) else {
            return XCTFail("the user was never told about the failed photo")
        }
        XCTAssertEqual(name, "Sidewalks")
        XCTAssertEqual(message, "Panoramax error 401: Token not valid")
    }

    func testAPhotoQueuedUnderTheKartaviewTagByAnOlderVersionGoesToStreetImages() throws {
        MockServer.installPanoramax(.ok)
        submitSidewalk(image: makeImage(), imageTagKey: PhotoTag.kartaview)
        waitUntil(timeout: 15, "the answer never synced") { events.contains("answerSynced") }

        let synced = try XCTUnwrap(db.getChangesets(synced: true).first)
        XCTAssertEqual(synced.tags[PhotoTag.streetImages], MockServer.panoramaxPhotoURL)
        XCTAssertNil(synced.tags[PhotoTag.kartaview])
    }

    func testThePhotoCarriesItsQuestContextAndIsPlacedOnTheWay() throws {
        MockServer.installPanoramax(.ok)
        submitSidewalk(image: makeImage(), imageTagKey: PhotoTag.streetImages, imageQuestion: "What is the surface?",
                       imageQuestId: 7)
        waitUntil(timeout: 15, "the answer never synced") { events.contains("answerSynced") }

        let synced = try XCTUnwrap(db.getChangesets(synced: true).first)
        XCTAssertEqual(synced.tags[PhotoTag.streetImages], MockServer.panoramaxPhotoURL)
        XCTAssertNil(synced.tags[PhotoTag.kartaview])
        let semantics = try XCTUnwrap(MockHTTP.requests(path: MockServer.panoramaxFilesPath).first).bodyString
        for expected in [#""key":"workspace_id","value":"222""#, #""key":"element_id","value":"way/121949""#, #""key":"quest_id","value":"7""#,
                         #""key":"question","value":"What is the surface?""#] {
            XCTAssertTrue(semantics.contains(expected), "semantics missing \(expected)")
        }
        XCTAssertFalse(semantics.contains("user_email"), "the user's email is never sent")

        // A way's photo is placed at its first node.
        let firstNodeId = try XCTUnwrap(db.getWay(id: 121949)?.nodes.first)
        let firstNode = try XCTUnwrap(db.getNode(id: Int(firstNodeId)))
        let file = try XCTUnwrap(MockHTTP.requests(path: MockServer.panoramaxFilesPath).first)
        XCTAssertTrue(file.bodyString.contains("name=\"override_latitude\"\r\n\r\n\(firstNode.latitude)\r\n"))
        XCTAssertTrue(file.bodyString.contains("name=\"override_longitude\"\r\n\r\n\(firstNode.longitude)\r\n"))
    }

    func testAPhotoFileThatWentMissingIsRecordedAsAFailure() throws {
        MockServer.installPanoramax(.ok)
        let id = db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: ["footway": "sidewalk", "highway": "footway"],
                                    tags: ["ext:surface": "concrete"], version: 1, iconName: "i",
                                    pendingImagePath: "/nonexistent/photo.jpg", pendingImageTagKey: PhotoTag.streetImages)!.id
        QuestSubmissionManager.resumePendingUploads()
        waitForDrain()
        XCTAssertEqual(db.getChangeset(for: id)?.lastError, "Saved photo could not be read")
        XCTAssertTrue(MockHTTP.requests(path: "/api/upload_sets").isEmpty)
    }

    func testSkippingAStuckPhotoSyncsJustTheTagsAndRemovesTheFile() throws {
        let path = try QuestImageStorage.shared.save(makeImage())
        let id = db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: ["footway": "sidewalk", "highway": "footway"],
                                    tags: ["ext:surface": "concrete"], version: 1, iconName: "i",
                                    pendingImagePath: path, pendingImageTagKey: PhotoTag.streetImages)!.id

        QuestSubmissionManager.skipPendingPhoto(changesetId: id)
        waitUntil(timeout: 10, "the tags never synced after skipping the photo") { events.contains("answerSynced") }
        // The event is announced before the new version is necessarily visible to this thread's Realm.
        waitUntil(timeout: 10, "the synced version was never stored") { db.getChangeset(for: id)?.updatedVersion == 2 }

        XCTAssertFalse(FileManager.default.fileExists(atPath: path), "the abandoned photo file is deleted")
        XCTAssertEqual(db.getChangeset(for: id)?.updatedVersion, 2)
        XCTAssertTrue(MockHTTP.requests(path: "/api/upload_sets").isEmpty, "no upload is attempted")
    }
}

// MARK: - Notes (NotesSubmissionManager / NotesViewModel)

final class NotesSubmissionManagerTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private let here = CLLocationCoordinate2D(latitude: 17.4385, longitude: 78.361)
    private var events: SheetEvents!

    override func setUp() {
        super.setUp()
        signIn(workspaceID: "222")
        events = recordSheetEvents()
    }

    private func waitForDrain() { waitUntil(timeout: 12, "notes queue never finished") { events.contains("notesSyncFinished") } }

    func testATextNoteIsQueuedSubmittedAndRemoved() throws {
        MockServer.installNotes()
        NotesSubmissionManager.submit(NoteDraft(noteText: "Broken kerb ramp", images: [], coordinates: here))
        waitForDrain()

        XCTAssertEqual(events.names, ["notesQueueUpdated", "notesSyncing", "noteSubmitted", "notesSyncFinished"])
        XCTAssertEqual(db.pendingNoteDraftsCount(), 0)
        let sent = try XCTUnwrap(MockHTTP.requests(path: "\(MockServer.osm)/notes.json").first)
        let json = try JSONSerialization.jsonObject(with: try XCTUnwrap(sent.body)) as? [String: Any]
        XCTAssertEqual(json?["text"] as? String, "Broken kerb ramp")
        XCTAssertEqual(json?["lat"] as? Double, 17.4385)
        XCTAssertEqual(json?["lon"] as? Double, 78.361)
        XCTAssertEqual(sent.header("X-Workspace"), "222")
        XCTAssertEqual(sent.header("Authorization"), "Bearer \(fixtureAccessToken)")
    }

    func testAPhotoIsUploadedAndItsLinkAppendedToTheNote() throws {
        MockServer.installNotes()
        MockServer.installPanoramax(.ok)
        NotesSubmissionManager.submit(NoteDraft(noteText: "See photo", images: [makeImage()], coordinates: here))
        waitForDrain()

        XCTAssertTrue(events.contains("noteSubmitted"))
        let sent = try XCTUnwrap(MockHTTP.requests(path: "\(MockServer.osm)/notes.json").first)
        let text = (try JSONSerialization.jsonObject(with: try XCTUnwrap(sent.body)) as? [String: Any])?["text"] as? String
        XCTAssertEqual(text, "See photo\n\n\(MockServer.panoramaxPhotoURL)")
    }

    func testANoteSubmittedOfflineStaysQueuedUntilTheNextAttempt() {
        MockServer.installNotes(success: false)
        NotesSubmissionManager.submit(NoteDraft(noteText: "later", images: [], coordinates: here))
        waitForDrain()
        XCTAssertEqual(db.pendingNoteDraftsCount(), 1)
        XCTAssertFalse(events.contains("noteSubmitted"))

        MockHTTP.reset()
        MockServer.installNotes()
        NotesSubmissionManager.resumePendingUploads()
        waitUntil(timeout: 10, "the queued note was never retried") { events.contains("noteSubmitted") }
        XCTAssertEqual(db.pendingNoteDraftsCount(), 0)
    }

    func testAPhotoFailureKeepsTheNoteQueuedWithAReadableError() throws {
        MockServer.installNotes()
        MockServer.installPanoramax(.unauthorized)
        NotesSubmissionManager.submit(NoteDraft(noteText: "photo fails", images: [makeImage()], coordinates: here))
        waitForDrain()

        XCTAssertEqual(db.pendingNoteDraftsCount(), 1)
        XCTAssertTrue(MockHTTP.requests(path: "\(MockServer.osm)/notes.json").isEmpty, "the note is not sent without its photo")
        let realm = try Realm(configuration: RealmConfig.configuration)
        let draft = try XCTUnwrap(realm.objects(StoredNoteDraft.self).first)
        XCTAssertEqual(draft.lastError, "Failed to upload photo 1 to Panoramax: Panoramax error 401: Token not valid")
        NoteImageStorage.shared.delete(paths: Array(draft.imagePaths))
    }

    func testARejectedPhotoKeepsTheNoteQueued() throws {
        MockServer.installNotes()
        MockServer.installPanoramax(.rejected)
        NotesSubmissionManager.submit(NoteDraft(noteText: "photo rejected", images: [makeImage()], coordinates: here))
        waitForDrain()

        XCTAssertEqual(db.pendingNoteDraftsCount(), 1)
        XCTAssertTrue(MockHTTP.requests(path: "\(MockServer.osm)/notes.json").isEmpty, "the note is not sent without its photo")
        let realm = try Realm(configuration: RealmConfig.configuration)
        let draft = try XCTUnwrap(realm.objects(StoredNoteDraft.self).first)
        XCTAssertEqual(draft.lastError, "Failed to upload photo 1 to Panoramax: Panoramax rejected the photo: No GPS coordinates")
        NoteImageStorage.shared.delete(paths: Array(draft.imagePaths))
    }

    func testResubmittingADraftReplacesItsEarlierPhotos() throws {
        MockServer.installNotes(success: false)
        let draft = NoteDraft(noteText: "v1", images: [makeImage()], coordinates: here)
        NotesSubmissionManager.submit(draft)
        waitForDrain()
        let firstPaths = db.noteDraftImagePaths(id: draft.id)
        XCTAssertEqual(firstPaths.count, 1)

        events = recordSheetEvents()
        NotesSubmissionManager.submit(NoteDraft(id: draft.id, noteText: "v2", images: [], coordinates: here))
        waitForDrain()

        XCTAssertEqual(db.pendingNoteDraftsCount(), 1, "same id -> still one draft")
        XCTAssertEqual(db.pendingNoteDrafts().first?.noteText, "v2")
        XCTAssertFalse(FileManager.default.fileExists(atPath: firstPaths[0]), "the superseded photo is deleted")
    }

    func testResumingWithNothingQueuedIsSilent() {
        NotesSubmissionManager.resumePendingUploads()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertTrue(events.names.isEmpty)
    }

    // MARK: NotesViewModel

    func testCreatingANoteReturnsTrueOnSuccess() async throws {
        MockServer.installNotes()
        let model = NotesViewModel()
        let ok = try await model.createNote(note: "hello", lat: 1, long: 2)
        XCTAssertTrue(ok)
        let isLoading = await MainActor.run { model.isLoading }
        XCTAssertFalse(isLoading)
    }

    func testCreatingANoteRequiresAWorkspaceAndAToken() async {
        _ = KeychainManager.delete(key: "workspaceID")
        do { _ = try await NotesViewModel().createNote(note: "x", lat: 0, long: 0); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).localizedDescription, "Workspace Error")
        }
        signIn(workspaceID: "222")
        _ = KeychainManager.delete(key: "accessToken")
        do { _ = try await NotesViewModel().createNote(note: "x", lat: 0, long: 0); XCTFail("expected an error") } catch {
            XCTAssertEqual((error as NSError).localizedDescription, "No Access Token found")
        }
    }

    func testCreatingANoteSurfacesServerErrors() async {
        MockServer.installNotes(success: false)
        do { _ = try await NotesViewModel().createNote(note: "x", lat: 0, long: 0); XCTFail("expected an error") } catch {
            guard case APIError.noNetworkConnection = error else { return XCTFail("got \(error)") }
        }
    }
}

// MARK: - Add Feature (FeatureSubmissionManager)

final class FeatureSubmissionManagerTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private let here = CLLocationCoordinate2D(latitude: 17.4385, longitude: 78.361)
    private var events: SheetEvents!

    override func setUp() {
        super.setUp()
        signIn(workspaceID: "222")
        loadQuestsSync()
        MockServer.installChangesets(changesetID: 900, upload: .nodeCreated(id: 555, version: 1))
        events = recordSheetEvents()
    }

    private func waitForDrain() { waitUntil(timeout: 12, "feature queue never finished") { events.contains("featuresSyncFinished") } }

    private func bench(image: UIImage? = nil, notes: String? = nil) -> FeatureDraft {
        var tags = ["amenity": "bench"]
        if let notes { tags["ext:notes"] = notes }
        return FeatureDraft(presetName: "Bench", iconName: "preset_temaki_bench", tags: tags, images: image.map { [$0] } ?? [], coordinates: here)
    }

    func testAFeatureIsCreatedPersistedAndMadeUndoable() throws {
        FeatureSubmissionManager.submit(bench(notes: "rusty"))
        waitForDrain()

        XCTAssertEqual(Array(events.names.prefix(2)), ["featuresQueueUpdated", "featuresSyncing"])
        XCTAssertEqual(events.names.last, "featuresSyncFinished")
        guard case .featureSubmitted(let preset, let quest)? = events.events.first(where: { SheetEvents.name($0) == "featureSubmitted" }) else {
            return XCTFail("no confirmation was published")
        }
        XCTAssertEqual(preset, "Bench")
        XCTAssertNil(quest, "a bench satisfies none of this workspace's quest queries, so no pin is added")

        XCTAssertEqual(db.pendingFeatureDraftsCount(), 0)
        let node = try XCTUnwrap(db.getNode(id: 555))
        XCTAssertEqual(node.tags["amenity"], "bench")
        XCTAssertEqual(node.tags["ext:notes"], "rusty")
        XCTAssertEqual(node.version, 1)
        XCTAssertEqual(node.latitude, 17.4385)

        let undoable = try XCTUnwrap(db.getChangesets(synced: true).first)
        XCTAssertTrue(undoable.isCreatedElement)
        XCTAssertEqual(undoable.elementId, 555)
        XCTAssertEqual(undoable.questType, "Bench")
        XCTAssertEqual(undoable.iconName, "preset_temaki_bench")
        XCTAssertEqual(MapUndoManager.shared.getUndoItems().first?.isCreatedElement, true)
    }

    func testAFeatureThatSatisfiesAQuestQueryAlsoGetsAQuestPin() throws {
        let kerb = FeatureDraft(presetName: "Kerb", iconName: "kerb", tags: ["barrier": "kerb"], images: [], coordinates: here)
        FeatureSubmissionManager.submit(kerb)
        waitForDrain()

        guard case .featureSubmitted(_, let unit?)? = events.events.first(where: { SheetEvents.name($0) == "featureSubmitted" }) else {
            return XCTFail("expected a quest pin for a kerb node")
        }
        XCTAssertEqual(unit.id, 555)
        XCTAssertEqual(unit.coordinateInfo.latitude, 17.4385, accuracy: 1e-6)
        XCTAssertEqual((unit.displayUnit.parent as? LongElementQuest)?.elementType, "Kerbs")
    }

    func testThePresetTagsAndNoteAreWhatIsUploaded() throws {
        FeatureSubmissionManager.submit(bench(notes: "needs paint"))
        waitForDrain()
        let upload = try XCTUnwrap(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).first)
        XCTAssertTrue(upload.bodyString.contains("<create>"))
        XCTAssertTrue(upload.bodyString.contains(#"<tag k="amenity" v="bench"/>"#))
        XCTAssertTrue(upload.bodyString.contains(#"<tag k="ext:notes" v="needs paint"/>"#))
    }

    func testPhotosAreUploadedAndNumberedIntoTheTags() throws {
        MockServer.installPanoramax(.ok)
        FeatureSubmissionManager.submit(bench(image: makeImage()))
        waitForDrain()
        XCTAssertEqual(db.getNode(id: 555)?.tags["ext:image_url1"], MockServer.panoramaxPhotoURL)
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 0)
    }

    func testAFeatureCreatedOfflineStaysQueuedAndIsRetriedLater() {
        MockHTTP.reset()
        MockServer.installChangesets(createFails: true)
        FeatureSubmissionManager.submit(bench())
        waitForDrain()
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 1)
        XCTAssertNil(db.getNode(id: 555))
        XCTAssertFalse(events.contains("featureSubmitted"), "a failed attempt is never surfaced")

        MockHTTP.reset()
        MockServer.installChangesets(changesetID: 900, upload: .nodeCreated(id: 555, version: 1))
        events = recordSheetEvents()
        FeatureSubmissionManager.resumePendingUploads()
        waitUntil(timeout: 10, "the queued feature was never retried") { events.contains("featureSubmitted") }
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 0)
        XCTAssertNotNil(db.getNode(id: 555))
    }

    func testAPhotoFailureKeepsTheFeatureQueuedForRetry() throws {
        MockServer.installPanoramax(.unauthorized)
        FeatureSubmissionManager.submit(bench(image: makeImage()))
        waitForDrain()
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 1)
        XCTAssertTrue(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).isEmpty)
        let realm = try Realm(configuration: RealmConfig.configuration)
        let draft = try XCTUnwrap(realm.objects(StoredFeatureDraft.self).first)
        XCTAssertEqual(draft.lastError, "Failed to upload photo 1 to Panoramax: Panoramax error 401: Token not valid")
        FeatureImageStorage.shared.delete(paths: Array(draft.imagePaths))
    }

    func testResumingWithNothingQueuedIsSilent() {
        events = recordSheetEvents()
        FeatureSubmissionManager.resumePendingUploads()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertTrue(events.names.isEmpty)
    }
}

final class PhotoTagTests: XCTestCase {

    func testStreetImagesWinsOverTheOlderKartaviewTag() {
        let tags = [PhotoTag.kartaview: "https://kv/old.jpg", PhotoTag.streetImages: "https://pnx/new.jpg"]
        XCTAssertEqual(PhotoTag.existingURL(in: tags), "https://pnx/new.jpg")
    }

    func testAKartaviewOnlyPhotoIsStillFound() {
        XCTAssertEqual(PhotoTag.existingURL(in: [PhotoTag.kartaview: "https://kv/old.jpg"]), "https://kv/old.jpg")
    }

    func testEmptyValuesCountAsNoPhoto() {
        let tags = [PhotoTag.streetImages: "", PhotoTag.kartaview: ""]
        XCTAssertNil(PhotoTag.existingURL(in: tags))
        XCTAssertTrue(PhotoTag.keysWithPhoto(in: tags).isEmpty)
    }

    func testTheTagNamesMatchWhatOtherToolsRead() {
        XCTAssertEqual(PhotoTag.streetImages, "ext:street_images")
        XCTAssertEqual(PhotoTag.kartaview, "ext:kartaview_url")
    }
}

final class PhotoThumbnailTests: XCTestCase {

    func testAPanoramaxPhotoUsesItsThumbnail() {
        let hd = "https://pnx.test/api/pictures/c0ffee00-1111-4222-8333-444455556666/hd.jpg"
        XCTAssertEqual(PhotoTag.thumbnailURL(for: hd), "https://pnx.test/api/pictures/c0ffee00-1111-4222-8333-444455556666/thumb.jpg")
    }

    func testTheStandardSizeAlsoMapsToTheThumbnail() {
        XCTAssertEqual(PhotoTag.thumbnailURL(for: "http://localhost:5001/api/pictures/abc/sd.jpg"),
                       "http://localhost:5001/api/pictures/abc/thumb.jpg")
    }

    func testAPanoramaxInstanceUnderASubpathKeepsItsPrefix() {
        XCTAssertEqual(PhotoTag.thumbnailURL(for: "https://host/panoramax/api/pictures/abc/hd.jpg"),
                       "https://host/panoramax/api/pictures/abc/thumb.jpg")
    }

    func testOtherURLsAreLeftAlone() {
        for url in ["https://cdn.kartaview.org/pr:sharp/photo-777001.jpg",
                    "https://example.com/pictures/abc/hd.jpg",
                    "not a url at all"] {
            XCTAssertEqual(PhotoTag.thumbnailURL(for: url), url)
        }
    }
}

// MARK: - Photo heading (GPSImgDirection)

final class PhotoHeadingTests: AppTestCase {

    private let spot = CLLocationCoordinate2D(latitude: 47.6553, longitude: -122.3035)
    private let directionField = "override_Exif.GPSInfo.GPSImgDirection"
    private let directionRefField = "override_Exif.GPSInfo.GPSImgDirectionRef"

    func testTheHeadingIsSentAsAWholeDegreeRationalFromTrueNorth() {
        XCTAssertEqual(PhotoHeading.overrideFields(for: 87.4), [directionField: "87/1", directionRefField: "T"])
        XCTAssertEqual(PhotoHeading.overrideFields(for: 359.7)[directionField], "0/1", "rounds up to north, never 360")
        XCTAssertEqual(PhotoHeading.overrideFields(for: 0)[directionField], "0/1")
        XCTAssertEqual(PhotoHeading.overrideFields(for: 450)[directionField], "90/1")
    }

    func testAnUnknownHeadingSendsNothing() {
        XCTAssertTrue(PhotoHeading.overrideFields(for: nil).isEmpty)
        XCTAssertTrue(PhotoHeading.overrideFields(for: -1).isEmpty, "Core Location's 'invalid' value")
        XCTAssertTrue(PhotoHeading.overrideFields(for: .nan).isEmpty)
    }

    func testTheHeadingSurvivesBeingQueuedOnDisk() throws {
        let image = makeImage()
        image.captureHeading = 123.5
        for (save, load, delete) in [
            (QuestImageStorage.shared.save, QuestImageStorage.shared.load, QuestImageStorage.shared.delete),
            (NoteImageStorage.shared.save, NoteImageStorage.shared.load, NoteImageStorage.shared.delete),
            (FeatureImageStorage.shared.save, FeatureImageStorage.shared.load, FeatureImageStorage.shared.delete)
        ] as [((UIImage) throws -> String, (String) -> UIImage?, ([String]) -> Void)] {
            let path = try save(image)
            let loaded = try XCTUnwrap(load(path))
            XCTAssertEqual(try XCTUnwrap(loaded.captureHeading), 123.5, accuracy: 0.01)
            XCTAssertEqual(loaded.size, image.size)
            delete([path])
        }
    }

    func testAPhotoWithoutAHeadingLoadsWithoutOne() throws {
        let path = try NoteImageStorage.shared.save(makeImage())
        XCTAssertNil(NoteImageStorage.shared.load(path: path)?.captureHeading)
        NoteImageStorage.shared.delete(paths: [path])
    }

    func testTheUploaderSendsTheHeadingOnlyWhenKnown() async throws {
        MockServer.installPanoramax(.ok)
        let uploader = PhotoUploadService.makePanoramaxUploader()
        _ = try await uploader.upload(imageData: Data("jpeg".utf8), coordinate: spot, heading: 271.6)
        _ = try await uploader.upload(imageData: Data("jpeg".utf8), coordinate: spot)

        let bodies = MockHTTP.requests(path: MockServer.panoramaxFilesPath, method: "POST").map(\.bodyString)
        XCTAssertEqual(bodies.count, 2)
        XCTAssertTrue(bodies[0].contains("name=\"\(directionField)\"\r\n\r\n272/1\r\n"))
        XCTAssertTrue(bodies[0].contains("name=\"\(directionRefField)\"\r\n\r\nT\r\n"))
        XCTAssertFalse(bodies[1].contains("GPSImgDirection"))
    }

    func testAQueuedNotePhotoUploadsWithTheHeadingItWasTakenAt() throws {
        signIn(workspaceID: "222")
        let events = recordSheetEvents()
        MockServer.installNotes()
        MockServer.installPanoramax(.ok)
        let image = makeImage()
        image.captureHeading = 45
        NotesSubmissionManager.submit(NoteDraft(noteText: "facing north-east", images: [image], coordinates: spot))
        waitUntil(timeout: 12, "the note never synced") { events.contains("noteSubmitted") }

        let body = try XCTUnwrap(MockHTTP.requests(path: MockServer.panoramaxFilesPath).first).bodyString
        XCTAssertTrue(body.contains("name=\"\(directionField)\"\r\n\r\n45/1\r\n"))
    }
}
