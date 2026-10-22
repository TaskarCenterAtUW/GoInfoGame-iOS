//
//  MockServer.swift
//  GoInfoGameTests
//
//  Composable "server" scenarios on top of MockHTTP, built from the same fixtures the UI
//  tests' scenarios use (GoInfoGame/DebugSupport/UITestStubs.swift): the workspace list and
//  details, map.json, the per-element freshness fetch, and the changeset create / upload /
//  close lifecycle that every quest submission and feature creation runs through.
//

import Foundation
import XCTest
import osmapi
@testable import GoInfoGame

enum MockServer {

    // MARK: Paths (production environment, the default)

    static let osm = "/prod/api/0.6"
    static let changesetCreate = "\(osm)/changeset/create"
    static let changesetUploadRegex = #"^/prod/api/0\.6/changeset/\d+/upload$"#
    static let changesetCloseRegex = #"^/prod/api/0\.6/changeset/\d+/close$"#
    static let mapJSON = "\(osm)/map.json"

    // MARK: Workspaces

    static func installWorkspaces(list: String = "WorkspacesSingle",
                                  details: String = "WorkspaceDetailsWithQuests",
                                  profile: String? = "UserProfilePlaceholder") {
        MockHTTP.stub("GET", path: "/api/v1/workspaces/mine", reply: .fixture(list))
        MockHTTP.stub("GET", pathRegex: #"^/api/v1/workspaces/\d+$"#, reply: .fixture(details))
        MockHTTP.stub("GET", pathRegex: "project-group-roles/", reply: .fixture("EmptyList"))
        if let profile { MockHTTP.stub("GET", pathRegex: "user-profile$", reply: .fixture(profile)) }
    }

    // MARK: OSM data

    static func installMapData(fixture: String = "LongFormOSMElements") {
        MockHTTP.stub("GET", path: mapJSON, reply: .fixture(fixture))
    }

    /// `GET /way/{id}.json` and `GET /node/{id}.json`: answers from `latest` (keyed by id, see
    /// LongFormLatestElements.json) and otherwise echoes that element out of `map` - exactly how
    /// UITestStubs.stubLatestElementFetch behaves.
    static func installLatestElements(map: String = "LongFormOSMElements", latest: String? = "LongFormLatestElements") {
        let mapJSON = MockHTTP.fixtureJSON(map) as? [String: Any] ?? [:]
        let mapElements = mapJSON["elements"] as? [[String: Any]] ?? []
        let latestJSON = latest.flatMap { MockHTTP.fixtureJSON($0) as? [String: Any] } ?? [:]

        func respond(kind: String, request: MockHTTP.Recorded) -> MockHTTP.Reply {
            let id = request.url.lastPathComponent.replacingOccurrences(of: ".json", with: "")
            if let byKind = latestJSON[kind] as? [String: Any], let body = byKind[id],
               let data = try? JSONSerialization.data(withJSONObject: body) {
                return .json(data)
            }
            if let element = mapElements.first(where: { "\($0["id"] ?? "")" == id && $0["type"] as? String == kind }) {
                var wrapped = mapJSON
                wrapped["elements"] = [element]
                if let data = try? JSONSerialization.data(withJSONObject: wrapped) { return .json(data) }
            }
            return .failure(NSError(domain: "OSM", code: 404, userInfo: [NSLocalizedDescriptionKey: "\(kind) \(id) not found"]))
        }
        MockHTTP.stub("GET", pathRegex: #"^/prod/api/0\.6/way/\d+\.json$"#) { respond(kind: "way", request: $0) }
        MockHTTP.stub("GET", pathRegex: #"^/prod/api/0\.6/node/\d+\.json$"#) { respond(kind: "node", request: $0) }
    }

    // MARK: Changesets

    enum Upload {
        /// 200 with an empty diffResult - what a `<modify>` upload returns.
        case ok
        /// 200 with the `<node old_id="-1" new_id=… new_version=…/>` a `<create>` upload returns.
        case nodeCreated(id: Int, version: Int)
        /// 409 for the first `times` uploads, then 200.
        case conflict(times: Int)
        case alwaysConflict
        case gone
        case serverError
        case offline
    }

    static func installChangesets(changesetID: Int = 775, upload: Upload = .ok, createFails: Bool = false) {
        if createFails {
            MockHTTP.stub("PUT", path: changesetCreate, reply: .offline)
        } else {
            MockHTTP.stub("PUT", path: changesetCreate, reply: .json("\(changesetID)"))
        }
        MockHTTP.stub("PUT", pathRegex: changesetCloseRegex, reply: .json(Data()))

        var conflicts = 0
        MockHTTP.stub("POST", pathRegex: changesetUploadRegex) { _ in
            switch upload {
            case .ok:
                return .text("<diffResult />")
            case .nodeCreated(let id, let version):
                return .text(#"<diffResult><node old_id="-1" new_id="\#(id)" new_version="\#(version)"/></diffResult>"#)
            case .conflict(let times):
                if conflicts < times { conflicts += 1; return .statusWithBody(409, "Version mismatch") }
                return .text("<diffResult />")
            case .alwaysConflict:
                return .statusWithBody(409, "Version mismatch")
            case .gone:
                return .statusWithBody(410, "gone")
            case .serverError:
                return .statusWithBody(500, "boom")
            case .offline:
                return .offline
            }
        }
    }

    // MARK: Kartaview (photo uploads)

    static let kartaviewPhotoURL = "https://cdn.kartaview.org/pr:sharp/unit-test-photo-777001.jpg"

    enum Kartaview {
        case ok
        case createFails            // sequence creation rejected
        case createStatusNot200     // 200 HTTP but the API's own status says failure
        case uploadFails            // photo upload answers 500
        case uploadStatusNot200
        case finishFails            // "finished uploading" answers 500
        case finishStatusNot200
        case lookupWithoutURL       // the hosted-URL lookup never produces a URL
    }

    static func installKartaview(_ mode: Kartaview = .ok) {
        switch mode {
        case .createFails:        MockHTTP.stub("POST", path: "/1.0/sequence/", reply: .statusWithBody(500, "boom"))
        case .createStatusNot200: MockHTTP.stub("POST", path: "/1.0/sequence/", reply: .json(withHTTPStatus: 401, of: "KartaviewSequenceCreated"))
        default:                  MockHTTP.stub("POST", path: "/1.0/sequence/", reply: .fixture("KartaviewSequenceCreated"))
        }
        switch mode {
        case .uploadFails:        MockHTTP.stub("POST", path: "/1.0/photo/", reply: .statusWithBody(500, "boom"))
        case .uploadStatusNot200: MockHTTP.stub("POST", path: "/1.0/photo/", reply: .json(#"{"status":{"apiCode":660,"apiMessage":"no","httpCode":403,"httpMessage":"no"},"osv":{"photo":{"id":"1","sequenceId":"1","dateAdded":"d","sequenceIndex":"1","photoName":"p","lat":"0","lng":"0","path":"p"}}}"#))
        default:                  MockHTTP.stub("POST", path: "/1.0/photo/", reply: .fixture("KartaviewPhotoUploaded"))
        }
        switch mode {
        case .finishFails:        MockHTTP.stub("POST", path: "/1.0/sequence/finished-uploading/", reply: .statusWithBody(500, "boom"))
        case .finishStatusNot200: MockHTTP.stub("POST", path: "/1.0/sequence/finished-uploading/", reply: .fixture("KartaviewStatusFailure"))
        default:                  MockHTTP.stub("POST", path: "/1.0/sequence/finished-uploading/", reply: .fixture("KartaviewUploadFinished"))
        }
        if mode == .lookupWithoutURL {
            MockHTTP.stub("GET", pathRegex: #"^/2\.0/photo/\d+$"#, reply: .fixture("KartaviewPhotoLookupEmpty"))
        } else {
            MockHTTP.stub("GET", pathRegex: #"^/2\.0/photo/\d+$"#, reply: .fixture("KartaviewPhotoLookup"))
        }
    }

    // MARK: Notes

    static func installNotes(success: Bool = true) {
        if success {
            MockHTTP.stub("POST", path: "\(osm)/notes.json", reply: .text("{}", contentType: "application/json"))
        } else {
            MockHTTP.stub("POST", path: "\(osm)/notes.json", reply: .offline)
        }
    }
}

// MARK: - Seeding the local database from a fixture

extension AppTestCase {

    /// Decodes one of the shared OSM fixtures exactly like MapViewModel does and saves it into Realm.
    @discardableResult
    func seedMap(_ fixture: String = "LongFormOSMElements", file: StaticString = #filePath, line: UInt = #line) -> [OSMElement] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let response = try? decoder.decode(OSMMapDataResponse.self, from: MockHTTP.fixture(fixture)) else {
            XCTFail("Could not decode \(fixture).json", file: file, line: line)
            return []
        }
        let elements = Array(response.getOSMElements().values)
        DatabaseConnector.shared.saveOSMElements(elements)
        return elements
    }

    /// Same as `loadQuests`, for synchronous (main-thread) tests.
    @discardableResult
    func loadQuestsSync(from fixture: String = "WorkspaceDetailsWithQuests", file: StaticString = #filePath, line: UInt = #line) -> Workspace? {
        precondition(Thread.isMainThread, "loadQuestsSync must run on the main thread")
        MockServer.installWorkspaces(details: fixture)
        signIn()
        var workspace: Workspace?
        var finished = false
        guard #available(iOS 17.0, *) else { fatalError("tests run on a modern simulator") }
        MainActor.assumeIsolated {
            let model = InitialViewModel()
            model.fetchLongQuestsFor(workspaceId: "222") { ok, _, loaded in
                workspace = ok ? loaded : nil
                finished = true
                _ = model   // keep the model alive until the request completes
            }
        }
        waitUntil(timeout: 5, "quests did not load", file: file, line: line) { finished }
        if workspace == nil { XCTFail("Could not load quests from \(fixture)", file: file, line: line) }
        // MapView does this when it appears (MapView.swift: loadLongQuests(from: "longQuestJson")).
        QuestsRepository.shared.loadLongQuests(from: "longQuestJson")
        return workspace
    }

    /// Loads a workspace-details fixture into QuestsRepository the way the app does: through
    /// InitialViewModel.fetchLongQuestsFor (so the repository, the saved quest file and the
    /// workspace's overrideConflicts flag are all populated for real).
    @discardableResult
    @MainActor
    func loadQuests(from fixture: String = "WorkspaceDetailsWithQuests", file: StaticString = #filePath, line: UInt = #line) async -> Workspace? {
        MockServer.installWorkspaces(details: fixture)
        signIn()
        let model = InitialViewModel()
        let workspace: Workspace? = await withCheckedContinuation { continuation in
            model.fetchLongQuestsFor(workspaceId: "222") { ok, _, workspace in
                continuation.resume(returning: ok ? workspace : nil)
            }
        }
        if workspace == nil { XCTFail("Could not load quests from \(fixture)", file: file, line: line) }
        QuestsRepository.shared.loadLongQuests(from: "longQuestJson")
        return workspace
    }
}

extension MockHTTP.Reply {
    /// A copy of a Kartaview fixture whose embedded `status.httpCode` is changed - the API answers
    /// HTTP 200 and reports its own failure inside the body.
    static func json(withHTTPStatus code: Int, of fixture: String) -> MockHTTP.Reply {
        var object = (MockHTTP.fixtureJSON(fixture) as? [String: Any]) ?? [:]
        var status = (object["status"] as? [String: Any]) ?? [:]
        status["httpCode"] = code
        object["status"] = status
        return .json((try? JSONSerialization.data(withJSONObject: object)) ?? Data())
    }
}
