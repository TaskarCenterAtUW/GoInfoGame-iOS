//
//  UITestStubs.swift
//  GoInfoGame
//
//  Network stubbing and state reset for XCUITest runs.
//
//  Why this lives in the APP target rather than in GoInfoGameUITests: a UI test bundle
//  runs in its own Runner process and drives the app over XPC, so it shares no memory
//  with it. OHHTTPStubs installs itself by calling `+[NSURLProtocol registerClass:]`,
//  which mutates a registry belonging to the calling process - stubs registered from the
//  Runner therefore never touch the app's URLSession, and the app silently keeps hitting
//  the real network. The stubs have to be registered here, inside the process that
//  actually makes the requests, and the test selects which ones via launch environment.
//
//  Unit tests (GoInfoGameTests) do NOT need this: they are injected into the app process
//  via TEST_HOST, so they can register stubs directly.
//

#if DEBUG

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import RealmSwift

enum UITestStubs {



    // MARK: - State reset

    /// Clears everything that would otherwise leak from one UI test into the next.
    ///
    /// Must run before SceneDelegate reads `loggedIn` to choose a root view, which is why
    /// it is called from `didFinishLaunchingWithOptions`. Without it a test that logs in
    /// successfully leaves `loggedIn = true` behind and every later test launches straight
    /// into InitialView instead of the login screen.
    static func resetStateIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains(UITestScenario.resetStateArgument) else { return }

        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }

        // The local Realm element database is not part of UserDefaults/Keychain and is
        // never touched by anything above or below this line - it survives across every
        // app relaunch on the same simulator, including between separate UI test runs.
        // A fixture that reuses element ids also used elsewhere (LongForm's fixtures
        // deliberately reuse ids from the Map suite's own MapOSMElements.json, to keep
        // both suites' pins in the same real-world area) can then collide with whatever
        // that id's row already held from an earlier run, producing pins/tags that don't
        // match either fixture. Safe to call unconditionally here (unlike
        // AppDelegate's own commented-out call to this) because this whole function is
        // itself gated on the UI-test-only launch argument and #if DEBUG below - it never
        // runs for a real user. realm.deleteAll() (not deleting the underlying file) is
        // the correct way to clear it: AppDelegate already opens a Realm instance at this
        // configuration earlier in launch (to force schema computation ahead of a
        // race-prone concurrent access - see its own comment), and deleting the file out
        // from under an already-open instance in the same process would not reliably work.
        DatabaseConnector.shared.clearDB()

        // The Keychain is not part of the app container and survives even a full
        // uninstall of the simulator app, so it has to be cleared by hand.
        _ = KeychainManager.delete(key: "accessToken")
        _ = KeychainManager.delete(key: "refreshToken")
        for environment in APIEnvironment.allCases {
            _ = KeychainManager.delete(.username, for: environment)
            _ = KeychainManager.delete(.password, for: environment)
        }

        // Whether Face ID is offered after a successful login depends on the simulator's
        // enrollment state, which differs between machines and would make the post-login
        // assertions flaky. Recording the opt-in as already declined keeps that branch out
        // of the way; the biometric flow deserves its own scenario rather than showing up
        // uninvited in every other test.
        for environment in APIEnvironment.allCases {
            SessionManager.shared.setDeclinedBiometric(true, for: environment)
        }

        NSLog("[UITestStubs] Reset UserDefaults and Keychain state")
    }

    // MARK: - Stub installation

    /// Installs stubs for the scenario named in the launch environment, if any.
    ///
    /// Call this as early as possible in launch (AppDelegate) - `ApiManager.shared` is a
    /// lazily-created singleton, so anything that fires a request before this runs would
    /// escape to the real network.
    static func installIfNeeded() {
        guard let scenario = ProcessInfo.processInfo.environment[UITestScenario.environmentKey] else { return }

        HTTPStubs.removeAllStubs()

        // NSLog rather than print: print goes to stdout, which is not captured in the
        // simulator's unified log, so those lines never reach the CI report.
        HTTPStubs.onStubActivation { request, descriptor, _ in
            NSLog("[UITestStubs] %@ -> %@",
                  request.url?.absoluteString ?? "?",
                  descriptor.name ?? "unnamed")
        }

        // Registered FIRST on purpose. HTTPStubs matches in reverse registration order
        // (see `firstStubPassingTestForRequest:`, which walks `reverseObjectEnumerator`),
        // so this is the LAST thing consulted and only answers requests no specific stub
        // claimed. Without it an unmatched request escapes to the real network and the
        // test quietly stops being hermetic.
        installCatchAll()

        // Third-party SDK traffic the app fires on every launch regardless of scenario.
        // Stubbed rather than left to the catch-all so the logs stay readable and nothing
        // spends time retrying.
        installLaunchTimeStubs()

        switch scenario {
        case UITestScenario.loginInvalidCredentials:
            stubLogin(fixture: "LoginFailure", status: 401)
        case UITestScenario.loginSuccess:
            stubLogin(fixture: "LoginSuccess", status: 200)
            stubWorkspacesList(fixture: "EmptyList")
            stubProjectGroupRoles(fixture: "EmptyList")
        case UITestScenario.loginServerError:
            stubLogin(fixture: "LoginServerError", status: 500)
        case UITestScenario.loginNetworkDown:
            stub(condition: isLoginRequest()) { _ in
                HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain,
                                                 code: URLError.notConnectedToInternet.rawValue))
            }.name = "login -> network down"
        case UITestScenario.loginSlowResponse:
            // A stubbed response normally returns instantly, so a loading spinner appears
            // and disappears faster than XCUITest can observe it. Delaying the response
            // makes that state assertable.
            stub(condition: isLoginRequest()) { _ in
                response(fixture: "LoginFailure", status: 401).responseTime(4.0)
            }.name = "login -> 401 after 4s"
        case UITestScenario.loginBiometricAvailable:
            stubLogin(fixture: "LoginFailure", status: 401)
            seedBiometricLoginAvailable()

        case UITestScenario.workspacesWithData:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfilePlaceholder")
        case UITestScenario.workspacesEmpty:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "EmptyList")
            stubProjectGroupRoles(fixture: "EmptyList")
        case UITestScenario.workspacesServerError:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesServerError", status: 500)
            stubProjectGroupRoles(fixture: "EmptyList")
        case UITestScenario.workspacesNetworkDown:
            seedLoggedInAndLandOnWorkspaces()
            stub(condition: isWorkspacesListRequest()) { _ in
                HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain,
                                                 code: URLError.notConnectedToInternet.rawValue))
            }.name = "workspaces/mine -> network down"
            stubProjectGroupRoles(fixture: "EmptyList")
        case UITestScenario.workspacesSingleAutoRedirect:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesSingle")
            stubProjectGroupRoles(fixture: "EmptyList")
            stub(condition: isMethodGET() && pathMatches(#"^/api/v1/workspaces/\d+$"#)) { _ in
                response(fixture: "WorkspaceDetailsSingle", status: 200)
            }.name = "GET /workspaces/{id} -> WorkspaceDetailsSingle"

        case UITestScenario.profileFetchError:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfileServerError", status: 500)

        case UITestScenario.mapWithQuestClusters:
            // No workspaceID seeding needed: WorkspacesSingle.json has exactly 1
            // eligible workspace and WorkspaceDetailsWithQuests.json has a genuinely
            // populated longFormQuestDef, so WorkspacesListView's real auto-redirect path
            // fires on its own - it calls fetchLongQuestsFor for real, which is what
            // saves "workspaceID" to Keychain on success (the same call path
            // workspacesSingleAutoRedirect already exercises successfully, just with a
            // fixture that resolves to a fallback instead of a redirect).
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesSingle")
            stubProjectGroupRoles(fixture: "EmptyList")
            // Map's profile button opens the Profile screen, which fetches this on appear.
            stubUserProfile(fixture: "UserProfilePlaceholder")
            stub(condition: isMethodGET() && pathMatches(#"^/api/v1/workspaces/\d+$"#)) { _ in
                response(fixture: "WorkspaceDetailsWithQuests", status: 200)
            }.name = "GET /workspaces/{id} -> WorkspaceDetailsWithQuests"
            // fetchOSMElements() -> setupType: .osm -> APIConfiguration.osmUrl, which for
            // the default .production environment (nothing here switches it) resolves to
            // ".../prod/api/0.6" + "/map.json" - matches the path the app's own
            // (currently dead, #if DEBUG && false-gated) legacy stub block in
            // ApiManager.swift already used for this exact endpoint.
            stub(condition: isMethodGET() && isPath("/prod/api/0.6/map.json")) { _ in
                response(fixture: "MapOSMElements", status: 200)
            }.name = "GET /map.json -> MapOSMElements"

        case UITestScenario.workspacesPickRowToMap:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfilePlaceholder")
            stubWorkspaceDetails(fixture: "WorkspaceDetailsWithQuests")
            stubOSMMapData()
        case UITestScenario.workspacesPickRowDetailsError:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubWorkspaceDetails(fixture: "WorkspacesServerError", status: 500)
        case UITestScenario.sessionExpiredOnWorkspaceDetails:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubWorkspaceDetails(fixture: "LoginFailure", status: 401)
            // ApiManager retries a 401 exactly once via TokenRefresher; failing that
            // request too is what makes the session count as expired.
            stub(condition: isMethodPOST() && pathEndsWith("refresh-token")) { _ in
                response(fixture: "LoginFailure", status: 401)
            }.name = "POST /refresh-token -> 401"
        case UITestScenario.loginBiometricPrompt:
            // resetStateIfNeeded() marks biometrics declined for every environment so
            // the prompt never shows up uninvited; this scenario is the one that wants it.
            SessionManager.shared.setDeclinedBiometric(false, for: .production)
            stubLogin(fixture: "LoginSuccess", status: 200)
            stubWorkspacesList(fixture: "EmptyList")
            stubProjectGroupRoles(fixture: "EmptyList")

        case UITestScenario.longFormOnline:
            installQuestFormBaseline(mapFixture: "LongFormOSMElements")
            stubLatestElementFetch(mapFixture: "LongFormOSMElements", latestFixture: "LongFormLatestElements")
            stubChangesetCreate()
            stubChangesetUpload()
            stubChangesetClose()
            stubSubmitNote()

        case UITestScenario.longFormNetworkDown:
            installQuestFormBaseline(mapFixture: "LongFormOSMElements")
            // The freshness fetch and every submission step fail - map data itself
            // (already stubbed by installQuestFormBaseline) is unaffected, so the pins
            // are still there to tap.
            stubOSMConnectivityFailure(pathMatches(#"^/prod/api/0\.6/(way|node)/\d+\.json$"#), name: "fetch latest element")
            stubOSMConnectivityFailure(isMethodPUT() && isPath("/prod/api/0.6/changeset/create"), name: "changeset create")
            stubOSMConnectivityFailure(isMethodPOST() && isPath("/prod/api/0.6/notes.json"), name: "submit note")

        case UITestScenario.longFormNetworkRecovers:
            installQuestFormBaseline(mapFixture: "LongFormOSMElements")
            stubLatestElementFetch(mapFixture: "LongFormOSMElements", latestFixture: "LongFormLatestElements")
            // Only the FIRST changeset/create attempt fails - QuestSubmissionManager's
            // offline queue leaves the answer pending after that, and a later retry
            // (sync button, or another submit) must succeed.
            var hasFailedOnce = false
            stub(condition: isMethodPUT() && isPath("/prod/api/0.6/changeset/create")) { _ in
                if !hasFailedOnce {
                    hasFailedOnce = true
                    return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain,
                                                             code: URLError.notConnectedToInternet.rawValue))
                }
                return HTTPStubsResponse(data: Data("775".utf8), statusCode: 200,
                                         headers: ["Content-Type": "application/json"])
            }.name = "changeset create -> fails once, then succeeds"
            stubChangesetUpload()
            stubChangesetClose()

        case UITestScenario.accessibilityModeOnline:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElements")
            // No freshness-fetch override needed: every element here carries only blank
            // Sidewalks tags, so echoing the map data back (stubLatestElementFetch's own
            // fallback when latestFixture is nil) is already the correct response.
            stubLatestElementFetch(mapFixture: "AccessibilityModeOSMElements", latestFixture: nil)
            stubChangesetCreate()
            stubChangesetUpload()
            stubChangesetClose()

        case UITestScenario.accessibilityModeNetworkDown:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElements")
            // The nearest-quest list itself never calls the network (it reads
            // mapViewModel.items, already populated by the map load above) - this
            // scenario exists to prove exactly that: the list still populates even
            // though every OSM API call after the map load fails.
            stubOSMConnectivityFailure(pathMatches(#"^/prod/api/0\.6/(way|node)/\d+\.json$"#), name: "fetch latest element")
            stubOSMConnectivityFailure(isMethodPUT() && isPath("/prod/api/0.6/changeset/create"), name: "changeset create")

        case UITestScenario.accessibilityModeNoNearbyQuests:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElementsFar")

        case UITestScenario.undoEditsOnline:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElements")
            seedUndoableChangesets()
            stubChangesetCreate()
            stubChangesetUpload()
            stubChangesetClose()

        case UITestScenario.undoEditsNetworkDown:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElements")
            seedUndoableChangesets()
            stubOSMConnectivityFailure(isMethodPUT() && isPath("/prod/api/0.6/changeset/create"), name: "changeset create")

        case UITestScenario.manageQuestsOnline:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElements")
            seedHiddenQuests()

        case UITestScenario.mapWithNoImageryOptions:
            installQuestFormBaseline(mapFixture: "AccessibilityModeOSMElements", workspaceDetailsFixture: "WorkspaceDetailsNoImagery")

        case UITestScenario.longFormConflict:
            installQuestFormBaseline(mapFixture: "LongFormOSMElements")
            stubLatestElementFetch(mapFixture: "LongFormOSMElements", latestFixture: "LongFormLatestElements")
            stubChangesetCreate()
            var hasConflictedOnce = false
            stub(condition: isMethodPOST() && pathMatches(#"^/prod/api/0\.6/changeset/\d+/upload$"#)) { _ in
                if !hasConflictedOnce {
                    hasConflictedOnce = true
                    return HTTPStubsResponse(data: Data("Version mismatch".utf8), statusCode: 409, headers: nil)
                }
                return HTTPStubsResponse(data: Data("<diffResult />".utf8), statusCode: 200, headers: ["Content-Type": "text/xml"])
            }.name = "changeset upload -> 409 once, then succeeds"
            stubChangesetClose()

        case UITestScenario.profileBiometricPopupOnline:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfilePlaceholder")
            stubLogin(fixture: "LoginSuccess", status: 200)

        case UITestScenario.profileBiometricPopupWrongPassword:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfilePlaceholder")
            stubLogin(fixture: "LoginFailure", status: 401)

        case UITestScenario.profileBiometricPopupNetworkDown:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfilePlaceholder")
            stub(condition: isLoginRequest()) { _ in
                HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue))
            }.name = "login (password verification) -> network down"

        case UITestScenario.profileBiometricPopupSlowResponse:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "WorkspacesList")
            stubProjectGroupRoles(fixture: "ProjectGroupRoles")
            stubUserProfile(fixture: "UserProfilePlaceholder")
            stub(condition: isLoginRequest()) { _ in
                response(fixture: "LoginSuccess", status: 200).responseTime(4.0)
            }.name = "login (password verification) -> 200 after 4s"

        case UITestScenario.forceUpdateNone:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "EmptyList")
            stubProjectGroupRoles(fixture: "EmptyList")
            stubForceUpdate(fixture: "ForceUpdateNone")

        case UITestScenario.forceUpdateSoft:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "EmptyList")
            stubProjectGroupRoles(fixture: "EmptyList")
            stubForceUpdate(fixture: "ForceUpdateSoft")

        case UITestScenario.forceUpdateForce:
            seedLoggedInAndLandOnWorkspaces()
            stubWorkspacesList(fixture: "EmptyList")
            stubProjectGroupRoles(fixture: "EmptyList")
            stubForceUpdate(fixture: "ForceUpdateForce")

        case UITestScenario.addFeatureOnline:
            installQuestFormBaseline(mapFixture: "LongFormOSMElements")
            stubChangesetCreate()
            // Unlike stubChangesetUpload() (a plain `<diffResult />`, used by LongForm's
            // own way-update path), node creation requires the response to echo back a
            // `<node old_id="-1" new_id=... new_version=.../>` - CreateNodeDiffResult
            // Parser's own requirement (DatasyncManager.swift) for learning the server-
            // assigned id/version.
            stub(condition: isMethodPOST() && pathMatches(#"^/prod/api/0\.6/changeset/\d+/upload$"#)) { _ in
                HTTPStubsResponse(data: Data(#"<diffResult><node old_id="-1" new_id="900901" new_version="1"/></diffResult>"#.utf8),
                                  statusCode: 200, headers: ["Content-Type": "text/xml"])
            }.name = "POST /changeset/{id}/upload -> node created"
            stubChangesetClose()

        case UITestScenario.addFeatureNetworkDown:
            installQuestFormBaseline(mapFixture: "LongFormOSMElements")
            // Same failure point as longFormNetworkDown's own "changeset create" -
            // FeatureSubmissionManager has already persisted the draft (Realm + disk)
            // before this call, so nothing here affects whether the draft survives.
            stubOSMConnectivityFailure(isMethodPUT() && isPath("/prod/api/0.6/changeset/create"), name: "changeset create")

        default:
            NSLog("[UITestStubs] Unknown scenario '%@' - only the catch-all is installed.", scenario)
        }

        NSLog("[UITestStubs] Installed scenario '%@'", scenario)
    }

    // MARK: - Conditions

    private static func isLoginRequest() -> HTTPStubsTestBlock {
        // Matched on method AND full path: `isPath` compares against `URL.path`, which
        // always carries its leading slash, and without the method check a GET to the
        // same path would match too.
        isMethodPOST() && isPath("/api/v1/authenticate")
    }

    private static func isWorkspacesListRequest() -> HTTPStubsTestBlock {
        isMethodGET() && isPath("/api/v1/workspaces/mine")
    }

    // MARK: - Scenario pieces

    private static func stubLogin(fixture name: String, status: Int32) {
        stub(condition: isLoginRequest()) { _ in
            response(fixture: name, status: status)
        }.name = "POST /api/v1/authenticate -> \(status)"
    }

    /// The workspaces list InitialView fetches once location resolves.
    private static func stubWorkspacesList(fixture name: String, status: Int32 = 200) {
        stub(condition: isWorkspacesListRequest()) { _ in
            response(fixture: name, status: status)
        }.name = "GET /workspaces/mine -> \(name) (\(status))"
    }

    /// Names for the project-group filter dropdown. Non-fatal in the app if this fails or
    /// is empty - the dropdown just falls back to showing raw ids - so every scenario stubs
    /// it, even ones that don't care about the filter, to keep the app's own error logging
    /// quiet.
    private static func stubProjectGroupRoles(fixture name: String) {
        stub(condition: isMethodGET() && pathStartsWith("/api/v1/project-group-roles/")) { _ in
            response(fixture: name, status: 200)
        }.name = "GET /project-group-roles -> \(name)"
    }

    /// Fetched by UserProfileViewModel when UserProfileView appears. Only scenarios that
    /// actually navigate to the profile screen need this; everything else can leave it
    /// unstubbed and let the catch-all fail it loudly if that ever turns out to be wrong.
    private static func stubUserProfile(fixture name: String, status: Int32 = 200) {
        stub(condition: isMethodGET() && isPath("/api/v1/user-profile")) { _ in
            response(fixture: name, status: status)
        }.name = "GET /user-profile -> \(name) (\(status))"
    }

    /// `GET /workspaces/{id}` - the details InitialViewModel.fetchLongQuestsFor loads once a
    /// workspace row is tapped (or auto-selected).
    private static func stubWorkspaceDetails(fixture name: String, status: Int32 = 200) {
        stub(condition: isMethodGET() && pathMatches(#"^/api/v1/workspaces/\d+$"#)) { _ in
            response(fixture: name, status: status)
        }.name = "GET /workspaces/{id} -> \(name) (\(status))"
    }

    /// The OSM elements MapView fetches for the visible area - see the comment on
    /// mapWithQuestClusters for why this path is what it is.
    private static func stubOSMMapData(fixture name: String = "MapOSMElements") {
        stub(condition: isMethodGET() && isPath("/prod/api/0.6/map.json")) { _ in
            response(fixture: name, status: 200)
        }.name = "GET /map.json -> \(name)"
    }

    /// Shared setup for every scenario that lands on the Map with a real, populated
    /// longFormQuestDef and a chosen /map.json fixture - the longForm* scenarios
    /// (LongFormOSMElements.json, engineered around specific tags) and the
    /// accessibilityMode* scenarios (AccessibilityModeOSMElements.json, engineered
    /// around specific distances/bearings) both just need this same shape with a
    /// different map fixture. Callers add their own freshness-fetch/changeset stubs on
    /// top.
    private static func installQuestFormBaseline(mapFixture: String, workspaceDetailsFixture: String = "WorkspaceDetailsWithQuests") {
        seedLoggedInAndLandOnWorkspaces()
        stubWorkspacesList(fixture: "WorkspacesSingle")
        stubProjectGroupRoles(fixture: "EmptyList")
        stubUserProfile(fixture: "UserProfilePlaceholder")
        stub(condition: isMethodGET() && pathMatches(#"^/api/v1/workspaces/\d+$"#)) { _ in
            response(fixture: workspaceDetailsFixture, status: 200)
        }.name = "GET /workspaces/{id} -> \(workspaceDetailsFixture)"
        stubOSMMapData(fixture: mapFixture)
    }

    /// `GET /way/{id}.json` and `GET /node/{id}.json` - the freshness check
    /// `LongElementQuest.fetchLatestTagsIfNeeded()` runs when a pin is tapped. Answers
    /// from `latestFixture`, keyed by id, when given - see LongFormLatestElements.json's
    /// own "_note" for the shape. A request for an id with no entry there (or when
    /// `latestFixture` is nil - AccessibilityModeOSMElements' elements are all blank, so
    /// there is nothing an override would add) falls through to `mapFixture`'s own tags
    /// (a plausible real response: the element simply hasn't changed since map.json was
    /// fetched), not to the catch-all.
    private static func stubLatestElementFetch(mapFixture: String, latestFixture: String?) {
        var latest: [String: [String: Any]] = ["way": [:], "node": [:]]
        if let latestFixture {
            guard let url = Bundle.main.url(forResource: latestFixture, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let latestJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("[UITestStubs] Could not read %@.json", latestFixture)
                return
            }
            // Top-level also has a plain-String "_note" key, which is why this isn't cast
            // straight to [String: [String: Any]] - a top-level String value would fail
            // that cast for the whole file, not just that one key.
            latest = [
                "way": latestJSON["way"] as? [String: Any] ?? [:],
                "node": latestJSON["node"] as? [String: Any] ?? [:],
            ]
        }
        guard let mapURL = Bundle.main.url(forResource: mapFixture, withExtension: "json"),
              let mapData = try? Data(contentsOf: mapURL),
              let mapJSON = try? JSONSerialization.jsonObject(with: mapData) as? [String: Any],
              let mapElements = mapJSON["elements"] as? [[String: Any]] else {
            NSLog("[UITestStubs] Could not read %@.json", mapFixture)
            return
        }

        func respond(kind: String, id: String) -> HTTPStubsResponse {
            if let byId = latest[kind]?[id] as? [String: Any],
               let body = try? JSONSerialization.data(withJSONObject: byId) {
                return HTTPStubsResponse(data: body, statusCode: 200, headers: ["Content-Type": "application/json"])
            }
            if let element = mapElements.first(where: { "\($0["id"] ?? "")" == id && $0["type"] as? String == kind }) {
                // OSMWayResponse/OSMNodeResponse decode version/generator/copyright/
                // attribution/license as non-optional - reuse map.json's own values
                // for them rather than making them up.
                var wrapped = mapJSON
                wrapped["elements"] = [element]
                if let body = try? JSONSerialization.data(withJSONObject: wrapped) {
                    return HTTPStubsResponse(data: body, statusCode: 200, headers: ["Content-Type": "application/json"])
                }
            }
            return HTTPStubsResponse(error: NSError(domain: "OSM", code: 404,
                                                     userInfo: [NSLocalizedDescriptionKey: "\(kind) \(id) not found"]))
        }

        stub(condition: isMethodGET() && pathMatches(#"^/prod/api/0\.6/way/\d+\.json$"#)) { request in
            let id = request.url?.lastPathComponent.replacingOccurrences(of: ".json", with: "") ?? ""
            return respond(kind: "way", id: id)
        }.name = "GET /way/{id}.json -> LongFormLatestElements (or map data)"

        stub(condition: isMethodGET() && pathMatches(#"^/prod/api/0\.6/node/\d+\.json$"#)) { request in
            let id = request.url?.lastPathComponent.replacingOccurrences(of: ".json", with: "") ?? ""
            return respond(kind: "node", id: id)
        }.name = "GET /node/{id}.json -> LongFormLatestElements (or map data)"
    }

    /// `PUT /changeset/create` - the first step of every quest-answer submission.
    /// Response is decoded as a bare `Int` (the new changeset id).
    private static func stubChangesetCreate() {
        stub(condition: isMethodPUT() && isPath("/prod/api/0.6/changeset/create")) { _ in
            HTTPStubsResponse(data: Data("775".utf8), statusCode: 200, headers: ["Content-Type": "application/json"])
        }.name = "PUT /changeset/create -> 775"
    }

    /// `POST /changeset/{id}/upload` - decoded as a plain string (useJSON: false), so
    /// any 200 with a text body satisfies it; the app never parses this response.
    private static func stubChangesetUpload() {
        stub(condition: isMethodPOST() && pathMatches(#"^/prod/api/0\.6/changeset/\d+/upload$"#)) { _ in
            HTTPStubsResponse(data: Data("<diffResult />".utf8), statusCode: 200, headers: ["Content-Type": "text/xml"])
        }.name = "POST /changeset/{id}/upload -> 200"
    }

    /// `PUT /changeset/{id}/close` - decoded as `Bool`; an empty body is treated as
    /// success by ApiManager's own empty-response special case for `Bool`.
    private static func stubChangesetClose() {
        stub(condition: isMethodPUT() && pathMatches(#"^/prod/api/0\.6/changeset/\d+/close$"#)) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: ["Content-Type": "application/json"])
        }.name = "PUT /changeset/{id}/close -> 200 (empty)"
    }

    /// Writes two already-synced, undoable StoredChangeset rows directly to Realm, for
    /// the undoEdits* scenarios - see UITestScenario.undoEditsOnline's own comment for
    /// why this exists (the undo list is pure local data with no network fetch behind
    /// it; nothing else can seed one except driving a full LongForm answer-and-submit
    /// round trip first). Mirrors DatabaseConnector's own createChangeset/
    /// createChangesetForNewElement shape - in particular, changesetId = 0 is the
    /// sentinel MapUndoManager.getUndoItems() filters on for "synced and undoable"; the
    /// production default (-1, "not yet synced") would make these invisible to it.
    private static func seedUndoableChangesets() {
        let realm = try! Realm(configuration: RealmConfig.configuration)

        // A tag edit on an existing way - undoing it reverts ext:surface back to
        // "concrete" (the classification into "Modified" vs "Added" in the undo UI
        // comes from whether the key also exists in originalTags - see
        // QuestUndoManager.getUndoItems()).
        let modified = StoredChangeset()
        modified.elementId = 810301
        modified.elementType = .way
        modified.version = 1
        modified.updatedVersion = 1
        modified.changesetId = 0
        modified.questType = "Sidewalks"
        modified.iconName = "sidewalk"
        modified.timestamp = String(Date().timeIntervalSince1970)
        modified.originalTags.setValue("concrete", forKey: "ext:surface")
        modified.tags.setValue("asphalt", forKey: "ext:surface")

        // A feature created via Add Feature - undoing it deletes the element outright
        // (isCreatedElement), which is what makes the confirmation button read "Delete
        // Feature" instead of "Revert Changes". Backdated a full day so this row lands
        // under a separate date section header from `modified` in UndoEditsView's
        // grouped list.
        let created = StoredChangeset()
        created.elementId = 810302
        created.elementType = .node
        created.version = 1
        created.updatedVersion = 1
        created.changesetId = 0
        created.questType = "Kerbs"
        created.iconName = "sidewalk"
        created.timestamp = String(Date().addingTimeInterval(-90_000).timeIntervalSince1970)
        created.isCreatedElement = true
        created.tags.setValue("kerb", forKey: "barrier")
        created.tags.setValue("raised", forKey: "kerb")

        do {
            try realm.write {
                realm.add(modified)
                realm.add(created)
            }
        } catch {
            NSLog("[UITestStubs] Error seeding undo changesets: %@", "\(error)")
        }
    }

    /// `POST /notes.json` - Compose Note's own submission (LongForm.swift's
    /// submitNote() -> NotesViewModel.createNote(), modelType: String.self,
    /// useJSON: false - decoded as a plain string, same as stubChangesetUpload()'s own
    /// endpoint, so any 200 with a text body satisfies it). The failure case is covered
    /// by stubOSMConnectivityFailure directly (longFormNetworkDown), same as the
    /// freshness-fetch/changeset-create stubs already do, so this only ever needs to
    /// answer success.
    private static func stubSubmitNote() {
        stub(condition: isMethodPOST() && isPath("/prod/api/0.6/notes.json")) { _ in
            HTTPStubsResponse(data: Data("ok".utf8), statusCode: 200, headers: ["Content-Type": "text/plain"])
        }.name = "POST /notes.json -> 200"
    }

    /// `GET app-force-update.json` - ForceUpdateManager.checkForceUpdate() fetches this
    /// from a static file hosted on GitHub (Config.xcconfig's APP_FORCE_UPDATE_URL), not
    /// from this app's own API host like every other stub in this file - matched on path
    /// alone, same as the rest of this file's conditions.
    private static func stubForceUpdate(fixture name: String) {
        stub(condition: isMethodGET() && isPath("/TaskarCenterAtUW/asr-config/refs/heads/main/force-update/app-force-update.json")) { _ in
            response(fixture: name, status: 200)
        }.name = "GET app-force-update.json -> \(name)"
    }

    /// Writes 2 HiddenQuest rows directly to UserDefaults["hiddenElements"], for
    /// manageQuestsOnline - see that scenario's own comment for why (HiddenQuestManager
    /// has no network fetch behind it; nothing else can seed it except actually hiding a
    /// quest through a real Map/Accessibility Mode flow first). Matches
    /// HiddenQuestManager.saveHiddenQuests()'s own encoding exactly (a plain
    /// JSONEncoder-encoded [HiddenQuest]), so HiddenQuestManager.shared's lazy init -
    /// whenever something first touches it, well after this runs - reads it back
    /// exactly as if a real hide had happened. Two rows (not one) so "Unhide All" and
    /// "swipe-delete a single row" can be tested as genuinely different outcomes.
    private static func seedHiddenQuests() {
        let seeded = [
            HiddenQuest(id: 810401, name: "Sidewalks"),
            HiddenQuest(id: 810402, name: "Crossings"),
        ]
        guard let data = try? JSONEncoder().encode(seeded) else {
            NSLog("[UITestStubs] Error encoding seeded hidden quests")
            return
        }
        UserDefaults.standard.set(data, forKey: "hiddenElements")
    }

    /// A connectivity failure for whatever `condition` matches - used by
    /// longFormNetworkDown for both the freshness fetch and the first submission step.
    private static func stubOSMConnectivityFailure(_ condition: @escaping HTTPStubsTestBlock, name: String) {
        stub(condition: condition) { _ in
            HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue))
        }.name = "\(name) -> network down"
    }

    /// Makes the biometric login button render, by satisfying `SessionManager
    /// .canUseBiometricLogin(for:)` directly for `.production` - the screen's default
    /// `selectedEnvironment` - rather than through `resetStateIfNeeded()`'s usual
    /// force-declined state.
    ///
    /// Runs after `resetStateIfNeeded()` (which wipes this on purpose for every other
    /// scenario), so this has to re-seed rather than merely skip the wipe. Deliberately
    /// does NOT touch `BiometricAuthManager`/`LAContext` - the button's visibility
    /// condition only checks Keychain + this UserDefaults flag, not whether Face ID/Touch
    /// ID is actually enrolled, so a test can assert the button is present and tappable
    /// without depending on - or being able to control - the simulator's biometric
    /// enrollment state.
    private static func seedBiometricLoginAvailable() {
        let environment = APIEnvironment.production
        _ = KeychainManager.save(.username, value: "biometric-uitest@example.com", for: environment)
        _ = KeychainManager.save(.password, value: "uitest-password", for: environment)
        SessionManager.shared.setBiometricEnabled(true, for: environment)
    }

    /// Skips the login screen's own UI entirely for scenarios that are actually about a
    /// later screen (Workspaces): SceneDelegate picks InitialView vs PosmLoginView as the
    /// root purely from `@AppStorage("loggedIn")` at launch, so setting that (plus a valid-
    /// shaped accessToken, which fetchProjectGroupRoles needs to resolve a user id via
    /// JWTDecoder.subject(fromToken:)) lands the app straight on the Workspaces screen.
    /// Faster than re-driving the login form in every one of these tests, and keeps this
    /// suite from depending on the login screen's own UI at all.
    ///
    /// Does not set accessToken_Generate/accessToken_expire_in: AppDelegate
    /// .validateAccessToken() only schedules a refresh when accessToken_Generate is
    /// present, so leaving it unset (resetStateIfNeeded() already wiped it) keeps that
    /// timer out of the way rather than needing to be seeded to a "not expired yet" value.
    private static func seedLoggedInAndLandOnWorkspaces() {
        UserDefaults.standard.set(true, forKey: "loggedIn")
        // Same placeholder token as LoginSuccess.json (sub: "uitest-user-0001"), reused
        // directly rather than duplicated, so a change to one does not silently desync
        // from the other.
        guard let url = Bundle.main.url(forResource: "LoginSuccess", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            NSLog("[UITestStubs] Could not read access_token from LoginSuccess.json")
            return
        }
        if !KeychainManager.save(key: "accessToken", data: accessToken) {
            NSLog("[UITestStubs] Failed to save accessToken - see KeychainManager's own log line for the OSStatus")
        }

        // Also needed for the Profile screen specifically: UserProfileViewModel
        // .fetchUserProfile() guards on SessionManager.shared.username, which reads a
        // DIFFERENT, per-environment-namespaced Keychain key (KeychainManager.load
        // (.username, for:)) than the plain "accessToken" key saved above. Missing this
        // was found directly: fetchUserProfile()'s first guard silently returned without
        // ever firing the request, so the profile-screen stub above was registered but
        // never actually hit. `.production` matches PosmLoginView's default
        // selectedEnvironment, which is what APIConfiguration.shared.environment stays at
        // here since no scenario switches it.
        if !KeychainManager.save(.username, value: "test@email.com", for: .production) {
            NSLog("[UITestStubs] Failed to save the namespaced username Keychain key")
        }
    }

    private static func installLaunchTimeStubs() {
        stub(condition: isHost("firebase-settings.crashlytics.com")
                     || isHost("firebaselogging-pa.googleapis.com")
                     || isHost("firebaseinstallations.googleapis.com")
                     || isHost("app-analytics-services.com")
                     || isHost("app-measurement.com")) { _ in
            HTTPStubsResponse(data: Data("{}".utf8),
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        }.name = "firebase (no-op)"

        // Returning "no update required" keeps ForceUpdateManager from putting its
        // blocking sheet in front of whatever a test is trying to do.
        stub(condition: pathEndsWith("app-force-update.json")) { _ in
            response(fixture: "ForceUpdateNone", status: 200)
        }.name = "force-update -> none"
    }

    private static func installCatchAll() {
        stub(condition: { _ in true }) { request in
            let url = request.url?.absoluteString ?? "unknown"
            NSLog("[UITestStubs] UNSTUBBED REQUEST: %@", url)
            return HTTPStubsResponse(
                error: NSError(domain: "UITestStubs",
                               code: NSURLErrorResourceUnavailable,
                               userInfo: [NSLocalizedDescriptionKey: "Unstubbed request: \(url)"])
            )
        }.name = "catch-all (unstubbed)"
    }

    // MARK: - Helpers

    /// Builds a response from a JSON fixture in the app bundle.
    ///
    /// The fixture must be a member of the GoInfoGame target - this code runs in the app
    /// process, so `Bundle.main` here is GoInfoGame.app, not the test runner's bundle.
    /// (`OHPathForFile` is not used because it takes an `AnyClass` to locate the bundle,
    /// and this type is an enum.)
    private static func response(fixture name: String, status: Int32) -> HTTPStubsResponse {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            // Fail loudly rather than quietly serving an empty 200 that makes a test
            // fail somewhere far away from the actual cause.
            return HTTPStubsResponse(
                error: NSError(domain: "UITestStubs",
                               code: NSFileNoSuchFileError,
                               userInfo: [NSLocalizedDescriptionKey: "Missing fixture \(name).json in app bundle"])
            )
        }
        return HTTPStubsResponse(fileURL: url,
                                 statusCode: status,
                                 headers: ["Content-Type": "application/json"])
    }
}

#endif
