//
//  SubmissionManagerTests.swift
//  GoInfoGameTests
//
//  The three offline-first submission queues - quest answers (QuestSubmissionManager), notes
//  (NotesSubmissionManager) and Add Feature (FeatureSubmissionManager) - plus Kartaview photo
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

// MARK: - Kartaview photo upload

final class KartaviewViewModelTests: AppTestCase {

    private func upload(_ model: KartaviewViewModel, timeout: TimeInterval = 8) -> (String, Bool) {
        let exp = expectation(description: "upload")
        var outcome = ("", false)
        model.createSequence { message, ok in outcome = (message, ok); exp.fulfill() }
        wait(for: [exp], timeout: timeout)
        return outcome
    }

    func testAFullUploadReturnsTheHostedPhotoURL() {
        MockServer.installKartaview(.ok)
        let model = KartaviewViewModel(capturedImage: makeImage())

        let (message, ok) = upload(model)

        XCTAssertTrue(ok)
        XCTAssertEqual(message, MockServer.kartaviewPhotoURL)
        XCTAssertEqual(model.sequenceId, "9001")
        XCTAssertEqual(MockHTTP.requests.map(\.path), ["/1.0/sequence/", "/1.0/photo/", "/1.0/sequence/finished-uploading/", "/2.0/photo/777001"],
                       "create sequence -> upload photo -> finish -> look the photo up by its own id")
    }

    func testThePhotoIsSentAsMultipartWithTheSequenceAndCoordinates() throws {
        MockServer.installKartaview(.ok)
        let model = KartaviewViewModel(capturedImage: makeImage())
        _ = upload(model)

        let photoRequest = try XCTUnwrap(MockHTTP.requests(path: "/1.0/photo/").first)
        let body = try XCTUnwrap(photoRequest.body)
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(photoRequest.header("Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
        XCTAssertTrue(text.contains("name=\"sequenceId\"\r\n\r\n9001"))
        XCTAssertTrue(text.contains("name=\"sequenceIndex\"\r\n\r\n1"))
        XCTAssertTrue(text.contains("name=\"coordinate\"\r\n\r\n0.0, 0.0"), "no GPS fix in a test -> the 0.0 default")
        XCTAssertTrue(text.contains("name=\"photo\"; filename=\"osmlogo.jpeg\""))
        XCTAssertTrue(text.contains("name=\"headers\"\r\n\r\n0"))
        XCTAssertNotNil(body.range(of: Data([0xFF, 0xD8])), "the JPEG bytes are embedded")
    }

    func testEachStepsFailureIsReportedWithItsOwnMessage() {
        let cases: [(MockServer.Kartaview, String)] = [
            (.createStatusNot200, "Failed to create Kartaview sequence"),
            (.uploadStatusNot200, "Failed to upload photo to Kartaview"),
            (.finishStatusNot200, "Failed to finish Kartaview upload"),
            (.finishFails, "An error occured")
        ]
        for (mode, expected) in cases {
            MockHTTP.reset()
            MockServer.installKartaview(mode)
            let (message, ok) = upload(KartaviewViewModel(capturedImage: makeImage()))
            XCTAssertFalse(ok, "\(mode)")
            XCTAssertEqual(message, expected, "\(mode)")
        }
    }

    func testTransportFailuresCarryTheErrorDescription() {
        MockServer.installKartaview(.createFails)
        var (message, ok) = upload(KartaviewViewModel(capturedImage: makeImage()))
        XCTAssertFalse(ok)
        XCTAssertEqual(message, "Internal server error. Please try again later.")

        MockHTTP.reset()
        MockServer.installKartaview(.uploadFails)
        (message, ok) = upload(KartaviewViewModel(capturedImage: makeImage()))
        XCTAssertFalse(ok)
        XCTAssertEqual(message, "Internal server error. Please try again later.")
    }

    func testAMissingHostedURLIsAGenuineFailureAfterOneRetry() {
        MockServer.installKartaview(.lookupWithoutURL)
        let (message, ok) = upload(KartaviewViewModel(capturedImage: makeImage()), timeout: 12)
        XCTAssertFalse(ok)
        XCTAssertEqual(message, "Failed to retrieve photo URL")
        XCTAssertEqual(MockHTTP.requests(pathRegex: #"^/2\.0/photo/"#).count, 2, "one initial lookup plus one retry after a pause")
    }

    func testAnImageThatCannotBeEncodedIsRejectedBeforeAnyRequest() {
        let model = KartaviewViewModel(capturedImage: UIImage())
        XCTAssertNil(model.imageToData(image: UIImage()))
        let exp = expectation(description: "upload")
        var outcome = ("", true)
        model.uploadPhoto(sequenceId: "1") { outcome = ($0, $1); exp.fulfill() }
        wait(for: [exp], timeout: 2)
        XCTAssertEqual(outcome.0, "Failed to process the captured photo")
        XCTAssertFalse(outcome.1)
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testTheAsyncWrapperReturnsTheURLOrThrows() async throws {
        MockServer.installKartaview(.ok)
        let url = try await KartaviewViewModel(capturedImage: makeImage()).uploadAsync()
        XCTAssertEqual(url, MockServer.kartaviewPhotoURL)

        MockHTTP.reset()
        MockServer.installKartaview(.createStatusNot200)
        do {
            _ = try await KartaviewViewModel(capturedImage: makeImage()).uploadAsync()
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual((error as NSError).localizedDescription, "Failed to create Kartaview sequence")
        }
    }

    func testTheKartaviewModelsDecodeTheirFixtures() throws {
        let decoder = JSONDecoder()
        let sequence = try decoder.decode(SequenceModel.self, from: MockHTTP.fixture("KartaviewSequenceCreated"))
        XCTAssertEqual(sequence.osv.sequence.id, "9001")
        XCTAssertEqual(sequence.status.httpCode, 200)
        let photo = try decoder.decode(UploadPhotoModel.self, from: MockHTTP.fixture("KartaviewPhotoUploaded"))
        XCTAssertEqual(photo.osv.photo.sequenceID, "9001")
        let finished = try decoder.decode(FinishUploadingModel.self, from: MockHTTP.fixture("KartaviewUploadFinished"))
        XCTAssertEqual(finished.osv.sequenceID, "9001")
        let lookup = try decoder.decode(PhotoLookupResponse.self, from: MockHTTP.fixture("KartaviewPhotoLookup"))
        XCTAssertEqual(lookup.result?.data?.imageLthUrl, MockServer.kartaviewPhotoURL)
        XCTAssertNil(try decoder.decode(PhotoLookupResponse.self, from: MockHTTP.fixture("KartaviewPhotoLookupEmpty")).result?.data?.imageLthUrl)
    }

    func testJSONNullDecodesOnlyFromNull() throws {
        XCTAssertNoThrow(try JSONDecoder().decode([JSONNull?].self, from: Data("[null]".utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(JSONNull.self, from: Data("1".utf8)))
        XCTAssertEqual(JSONNull(), JSONNull())
        XCTAssertEqual(JSONNull().hashValue, 0)
        XCTAssertEqual(String(decoding: try JSONEncoder().encode([JSONNull()]), as: UTF8.self), "[null]")
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

    private func submitSidewalk(tags: [String: String] = ["ext:surface": "concrete"], image: UIImage? = nil, imageTagKey: String? = nil) {
        QuestSubmissionManager.submit(id: 121949, questType: "Sidewalks", tags: tags, type: .way, iconName: "sidewalk_surface",
                                      capturedImage: image, imageTagKey: imageTagKey)
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
        MockServer.installKartaview(.ok)
        submitSidewalk(image: makeImage(), imageTagKey: "ext:kartaview_url")
        waitUntil(timeout: 15, "the answer never synced") { events.contains("answerSynced") }

        let synced = try XCTUnwrap(db.getChangesets(synced: true).first)
        XCTAssertEqual(synced.tags["ext:kartaview_url"], MockServer.kartaviewPhotoURL)
        XCTAssertNil(synced.pendingImagePath)
        let upload = try XCTUnwrap(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).first)
        XCTAssertTrue(upload.bodyString.contains(MockServer.kartaviewPhotoURL), "the photo URL is part of the uploaded tags")
    }

    func testAPhotoThatFailsToUploadKeepsTheAnswerQueuedAndWarnsTheUser() throws {
        MockServer.installKartaview(.createStatusNot200)
        submitSidewalk(image: makeImage(), imageTagKey: "ext:kartaview_url")
        waitForDrain()

        let pending = try XCTUnwrap(db.getChangesets().first)
        XCTAssertNotNil(pending.pendingImagePath, "the photo is kept for the retry")
        XCTAssertEqual(pending.retryCount, 1)
        XCTAssertTrue(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).isEmpty, "tags are not synced without their photo")
        guard case .questPhotoUploadFailed(let name, let message)? = events.events.first(where: { SheetEvents.name($0) == "questPhotoUploadFailed" }) else {
            return XCTFail("the user was never told about the failed photo")
        }
        XCTAssertEqual(name, "Sidewalks")
        XCTAssertEqual(message, "Failed to create Kartaview sequence")
    }

    func testAPhotoFileThatWentMissingIsRecordedAsAFailure() throws {
        MockServer.installKartaview(.ok)
        let id = db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: ["footway": "sidewalk", "highway": "footway"],
                                    tags: ["ext:surface": "concrete"], version: 1, iconName: "i",
                                    pendingImagePath: "/nonexistent/photo.jpg", pendingImageTagKey: "ext:kartaview_url")!.id
        QuestSubmissionManager.resumePendingUploads()
        waitForDrain()
        XCTAssertEqual(db.getChangeset(for: id)?.lastError, "Saved photo could not be read")
        XCTAssertTrue(MockHTTP.requests(path: "/1.0/sequence/").isEmpty)
    }

    func testSkippingAStuckPhotoSyncsJustTheTagsAndRemovesTheFile() throws {
        let path = try QuestImageStorage.shared.save(makeImage())
        let id = db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: ["footway": "sidewalk", "highway": "footway"],
                                    tags: ["ext:surface": "concrete"], version: 1, iconName: "i",
                                    pendingImagePath: path, pendingImageTagKey: "ext:kartaview_url")!.id

        QuestSubmissionManager.skipPendingPhoto(changesetId: id)
        waitUntil(timeout: 10, "the tags never synced after skipping the photo") { events.contains("answerSynced") }
        // The event is announced before the new version is necessarily visible to this thread's Realm.
        waitUntil(timeout: 10, "the synced version was never stored") { db.getChangeset(for: id)?.updatedVersion == 2 }

        XCTAssertFalse(FileManager.default.fileExists(atPath: path), "the abandoned photo file is deleted")
        XCTAssertEqual(db.getChangeset(for: id)?.updatedVersion, 2)
        XCTAssertTrue(MockHTTP.requests(path: "/1.0/sequence/").isEmpty, "no upload is attempted")
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
        MockServer.installKartaview(.ok)
        NotesSubmissionManager.submit(NoteDraft(noteText: "See photo", images: [makeImage()], coordinates: here))
        waitForDrain()

        XCTAssertTrue(events.contains("noteSubmitted"))
        let sent = try XCTUnwrap(MockHTTP.requests(path: "\(MockServer.osm)/notes.json").first)
        let text = (try JSONSerialization.jsonObject(with: try XCTUnwrap(sent.body)) as? [String: Any])?["text"] as? String
        XCTAssertEqual(text, "See photo\n\n\(MockServer.kartaviewPhotoURL)")
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
        MockServer.installKartaview(.createStatusNot200)
        NotesSubmissionManager.submit(NoteDraft(noteText: "photo fails", images: [makeImage()], coordinates: here))
        waitForDrain()

        XCTAssertEqual(db.pendingNoteDraftsCount(), 1)
        XCTAssertTrue(MockHTTP.requests(path: "\(MockServer.osm)/notes.json").isEmpty, "the note is not sent without its photo")
        let realm = try Realm(configuration: RealmConfig.configuration)
        let draft = try XCTUnwrap(realm.objects(StoredNoteDraft.self).first)
        XCTAssertEqual(draft.lastError, "Failed to upload photo 1 to Kartaview: Failed to create Kartaview sequence")
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
        MockServer.installKartaview(.ok)
        FeatureSubmissionManager.submit(bench(image: makeImage()))
        waitForDrain()
        XCTAssertEqual(db.getNode(id: 555)?.tags["ext:image_url1"], MockServer.kartaviewPhotoURL)
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
        MockServer.installKartaview(.createStatusNot200)
        FeatureSubmissionManager.submit(bench(image: makeImage()))
        waitForDrain()
        XCTAssertEqual(db.pendingFeatureDraftsCount(), 1)
        XCTAssertTrue(MockHTTP.requests(pathRegex: MockServer.changesetUploadRegex).isEmpty)
        let realm = try Realm(configuration: RealmConfig.configuration)
        let draft = try XCTUnwrap(realm.objects(StoredFeatureDraft.self).first)
        XCTAssertEqual(draft.lastError, "Failed to upload photo 1 to Kartaview: Failed to create Kartaview sequence")
        FeatureImageStorage.shared.delete(paths: Array(draft.imagePaths))
    }

    func testResumingWithNothingQueuedIsSilent() {
        events = recordSheetEvents()
        FeatureSubmissionManager.resumePendingUploads()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertTrue(events.names.isEmpty)
    }
}
