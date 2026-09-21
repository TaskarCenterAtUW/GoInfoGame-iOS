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
