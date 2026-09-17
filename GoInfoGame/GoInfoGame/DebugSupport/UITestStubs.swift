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
            stubPostLoginScreens()
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

    // MARK: - Scenario pieces

    private static func stubLogin(fixture name: String, status: Int32) {
        stub(condition: isLoginRequest()) { _ in
            response(fixture: name, status: status)
        }.name = "POST /api/v1/authenticate -> \(status)"
    }

    /// Everything InitialView asks for once login succeeds.
    ///
    /// Both return empty collections: the assertion after a successful login is that the
    /// app left the login screen, not that any particular workspace rendered, and an empty
    /// list keeps these fixtures from having to track the Workspace model.
    private static func stubPostLoginScreens() {
        stub(condition: isMethodGET() && isPath("/api/v1/workspaces/mine")) { _ in
            response(fixture: "EmptyList", status: 200)
        }.name = "GET /workspaces/mine -> []"

        stub(condition: isMethodGET() && pathStartsWith("/api/v1/project-group-roles/")) { _ in
            response(fixture: "EmptyList", status: 200)
        }.name = "GET /project-group-roles -> []"
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
