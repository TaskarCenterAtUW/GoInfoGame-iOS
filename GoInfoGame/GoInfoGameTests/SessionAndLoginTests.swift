//
//  SessionAndLoginTests.swift
//  GoInfoGameTests
//
//  KeychainManager, SessionManager, TokenRefresher, the login view models, biometrics,
//  the user-profile view model and the small Utilities. Network traffic is answered by
//  MockHTTP using the UI tests' LoginSuccess / LoginFailure / LoginServerError /
//  UserProfilePlaceholder fixtures.
//

import XCTest
import LocalAuthentication
@testable import GoInfoGame

// MARK: - KeychainManager

final class KeychainManagerTests: AppTestCase {

    func testSaveLoadDeleteRoundTrip() {
        XCTAssertNil(KeychainManager.load(key: "k"))
        XCTAssertTrue(KeychainManager.save(key: "k", data: "v1"))
        XCTAssertEqual(KeychainManager.load(key: "k"), "v1")
        XCTAssertTrue(KeychainManager.save(key: "k", data: "v2"), "saving again overwrites")
        XCTAssertEqual(KeychainManager.load(key: "k"), "v2")
        XCTAssertTrue(KeychainManager.delete(key: "k"))
        XCTAssertNil(KeychainManager.load(key: "k"))
        XCTAssertTrue(KeychainManager.delete(key: "k"), "deleting something absent is not an error")
    }

    func testKeysAreIndependent() {
        _ = KeychainManager.save(key: "a", data: "1")
        _ = KeychainManager.save(key: "b", data: "2")
        _ = KeychainManager.delete(key: "a")
        XCTAssertNil(KeychainManager.load(key: "a"))
        XCTAssertEqual(KeychainManager.load(key: "b"), "2")
    }

    func testAccessTokenKeyName() {
        XCTAssertEqual(KeychainManager.Keys.accessToken.rawValue, "accessToken")
    }

    func testNamespacedKeysAreIsolatedPerEnvironment() {
        XCTAssertEqual(KeychainManager.Key.username.namespaced(for: .staging), "username_stage")
        XCTAssertEqual(KeychainManager.Key.password.namespaced(for: .production), "password_prod")

        _ = KeychainManager.save(.username, value: "dev-user", for: .development)
        _ = KeychainManager.save(.username, value: "prod-user", for: .production)
        XCTAssertEqual(KeychainManager.load(.username, for: .development), "dev-user")
        XCTAssertEqual(KeychainManager.load(.username, for: .production), "prod-user")
        XCTAssertNil(KeychainManager.load(.username, for: .staging))
        XCTAssertNil(KeychainManager.load(.password, for: .development), "username and password are separate slots")

        XCTAssertTrue(KeychainManager.delete(.username, for: .development))
        XCTAssertNil(KeychainManager.load(.username, for: .development))
        XCTAssertEqual(KeychainManager.load(.username, for: .production), "prod-user")
    }

    /// The tests above run against the UserDefaults stand-in (an unsigned test binary has no
    /// keychain entitlement). This one deliberately exercises the real SecItem* branches; if
    /// the entitlement is missing the add fails and nothing may then be readable back.
    func testRealKeychainPathBehavesConsistently() {
        UITestRuntime.forceRealKeychain = true
        addTeardownBlock { UITestRuntime.forceRealKeychain = false; _ = KeychainManager.delete(key: "unit-test-real") }

        let saved = KeychainManager.save(key: "unit-test-real", data: "secret")
        let loaded = KeychainManager.load(key: "unit-test-real")
        if saved {
            XCTAssertEqual(loaded, "secret")
            XCTAssertTrue(KeychainManager.delete(key: "unit-test-real"))
            XCTAssertNil(KeychainManager.load(key: "unit-test-real"))
        } else {
            XCTAssertNil(loaded, "a failed save must not leave a readable value behind")
        }
        XCTAssertNil(KeychainManager.load(key: "unit-test-never-saved"))
    }
}

// MARK: - SessionManager

final class SessionManagerTests: AppTestCase {

    private let session = SessionManager.shared

    private func login(_ user: String = "tester@example.com", _ password: String = "pw", env: APIEnvironment = .production) -> (Bool, String) {
        let exp = expectation(description: "login")
        var outcome = (false, "")
        session.performLogin(username: user, password: password, environment: env) { ok, message in
            outcome = (ok, message)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        return outcome
    }

    func testSuccessfulLoginStoresTokensAndTimestamps() throws {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        let before = Date().timeIntervalSince1970

        let (ok, message) = login("tester@example.com", "s3cret")

        XCTAssertTrue(ok)
        XCTAssertEqual(message, "")
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), fixtureAccessToken)
        XCTAssertNotNil(KeychainManager.load(key: "refreshToken"))
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "accessToken_expire_in"), 86400)
        XCTAssertGreaterThanOrEqual(UserDefaults.standard.double(forKey: "accessToken_Generate"), before)
        XCTAssertTrue(session.isLoginSuccessful)
        XCTAssertFalse(session.hasLoginFailed)
        XCTAssertEqual(session.lastLoginPassword, "s3cret")
    }

    func testLoginPostsCredentialsAsJSON() throws {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        _ = login("tester@example.com", "s3cret")

        let sent = try XCTUnwrap(MockHTTP.requests(path: "/api/v1/authenticate").first)
        let json = try JSONSerialization.jsonObject(with: try XCTUnwrap(sent.body)) as? [String: String]
        XCTAssertEqual(json?["username"], "tester@example.com")
        XCTAssertEqual(json?["password"], "s3cret")
        XCTAssertEqual(sent.header("Content-Type"), "application/json")
    }

    func testRejectedCredentialsReportInvalidCredentials() {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginFailure", status: 401))
        let (ok, message) = login()
        XCTAssertFalse(ok)
        XCTAssertEqual(message, L10n.Localizable.invalidCredentials)
        XCTAssertFalse(session.isLoginSuccessful)
        XCTAssertTrue(session.hasLoginFailed)
        XCTAssertNil(KeychainManager.load(key: "accessToken"))
    }

    func testServerErrorsAndOutagesAlsoFailTheLogin() {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginServerError", status: 500))
        XCTAssertFalse(login().0)

        MockHTTP.reset()
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .offline)
        XCTAssertFalse(login().0)
        XCTAssertNil(KeychainManager.load(key: "accessToken"))
    }

    func testAFailedLoginAfterASuccessfulOneFlipsTheFlags() {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        XCTAssertTrue(login().0)
        MockHTTP.reset()
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginFailure", status: 401))
        XCTAssertFalse(login().0)
        XCTAssertFalse(session.isLoginSuccessful)
        XCTAssertTrue(session.hasLoginFailed)
    }

    func testUsernameComesFromTheCurrentEnvironmentsKeychainSlot() {
        APIConfiguration.shared.environment = .staging
        XCTAssertNil(session.username)
        _ = KeychainManager.save(.username, value: "stage-user", for: .staging)
        _ = KeychainManager.save(.username, value: "prod-user", for: .production)
        XCTAssertEqual(session.username, "stage-user")
        APIConfiguration.shared.environment = .production
        XCTAssertEqual(session.username, "prod-user")
    }

    // MARK: Biometric bookkeeping

    func testBiometricFlagsAreStoredPerEnvironment() {
        XCTAssertFalse(session.isBiometricEnabled(for: .production))
        session.setBiometricEnabled(true, for: .production)
        XCTAssertTrue(session.isBiometricEnabled(for: .production))
        XCTAssertFalse(session.isBiometricEnabled(for: .development))

        XCTAssertFalse(session.hasDeclinedBiometric(for: .staging))
        session.setDeclinedBiometric(true, for: .staging)
        XCTAssertTrue(session.hasDeclinedBiometric(for: .staging))
        XCTAssertFalse(session.hasDeclinedBiometric(for: .production))
        session.setDeclinedBiometric(false, for: .staging)
        XCTAssertFalse(session.hasDeclinedBiometric(for: .staging))
    }

    func testSavingBiometricCredentialsNeedsALastPasswordAndAUsername() {
        // No password captured yet -> nothing is saved.
        session.savePasswordForBiometric(for: .production)
        XCTAssertNil(KeychainManager.load(.password, for: .production))
        XCTAssertFalse(session.isBiometricEnabled(for: .production))

        // Password but no username -> still nothing.
        session.lastLoginPassword = "pw"
        session.savePasswordForBiometric(for: .production)
        XCTAssertNil(KeychainManager.load(.password, for: .production))

        // Both -> saved and enabled.
        APIConfiguration.shared.environment = .production
        _ = KeychainManager.save(.username, value: "tester", for: .production)
        session.savePasswordForBiometric(for: .production)
        XCTAssertEqual(KeychainManager.load(.password, for: .production), "pw")
        XCTAssertEqual(KeychainManager.load(.username, for: .production), "tester")
        XCTAssertTrue(session.isBiometricEnabled(for: .production))
    }

    func testBiometricLoginAvailabilityNeedsCredentialsAndTheEnabledFlag() {
        XCTAssertFalse(session.canUseBiometricLogin(for: .production))
        _ = KeychainManager.save(.username, value: "u", for: .production)
        XCTAssertFalse(session.canUseBiometricLogin(for: .production))
        _ = KeychainManager.save(.password, value: "p", for: .production)
        XCTAssertFalse(session.canUseBiometricLogin(for: .production), "credentials alone are not enough")
        session.setBiometricEnabled(true, for: .production)
        XCTAssertTrue(session.canUseBiometricLogin(for: .production))
        XCTAssertFalse(session.canUseBiometricLogin(for: .development), "another environment has nothing stored")
    }

    func testLogoutClearsOnlyTheLastPasswordByDefault() {
        session.lastLoginPassword = "pw"
        _ = KeychainManager.save(.password, value: "p", for: .production)
        session.setBiometricEnabled(true, for: .production)

        session.logout(environment: .production)

        XCTAssertNil(session.lastLoginPassword)
        XCTAssertEqual(KeychainManager.load(.password, for: .production), "p")
        XCTAssertTrue(session.isBiometricEnabled(for: .production))
    }

    func testLogoutCanAlsoRemoveTheBiometricCredentials() {
        session.lastLoginPassword = "pw"
        _ = KeychainManager.save(.password, value: "p", for: .production)
        session.setBiometricEnabled(true, for: .production)

        session.logout(environment: .production, clearBiometricCreds: true)

        XCTAssertNil(session.lastLoginPassword)
        XCTAssertNil(KeychainManager.load(.password, for: .production))
        XCTAssertFalse(session.isBiometricEnabled(for: .production))
    }

    func testBiometricLoginWithoutStoredCredentialsFailsFast() {
        let exp = expectation(description: "bio")
        var outcome = (true, "")
        session.loginWithBiometrics(for: .production) { ok, message in outcome = (ok, message); exp.fulfill() }
        wait(for: [exp], timeout: 2)
        XCTAssertFalse(outcome.0)
        XCTAssertEqual(outcome.1, "Missing credentials for biometric login")
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testBiometricLoginReplaysTheStoredCredentials() throws {
        _ = KeychainManager.save(.username, value: "stored-user", for: .production)
        _ = KeychainManager.save(.password, value: "stored-pw", for: .production)
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))

        let exp = expectation(description: "bio")
        var ok = false
        session.loginWithBiometrics(for: .production) { success, _ in ok = success; exp.fulfill() }
        wait(for: [exp], timeout: 5)

        XCTAssertTrue(ok)
        let sent = try XCTUnwrap(MockHTTP.requests(path: "/api/v1/authenticate").first)
        let json = try JSONSerialization.jsonObject(with: try XCTUnwrap(sent.body)) as? [String: String]
        XCTAssertEqual(json?["username"], "stored-user")
        XCTAssertEqual(json?["password"], "stored-pw")
    }
}

// MARK: - TokenRefresher

final class TokenRefresherTests: AppTestCase {

    private func refreshReply(_ access: String = "n.e.w", refresh: String = "r.e.f") -> MockHTTP.Reply {
        .json(#"{"access_token":"\#(access)","expires_in":1800,"refresh_expires_in":3600,"refresh_token":"\#(refresh)"}"#)
    }

    private func refresh(_ token: String? = nil) -> (Bool, Error?) {
        let exp = expectation(description: "refresh")
        var outcome: (Bool, Error?) = (false, nil)
        TokenRefresher.shared.refreshToken(refreshToken: token) { ok, error in outcome = (ok, error); exp.fulfill() }
        wait(for: [exp], timeout: 5)
        return outcome
    }

    func testSuccessReplacesBothTokensAndRestartsTheExpiryClock() {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply())
        let before = Date().timeIntervalSince1970

        let (ok, error) = refresh()

        XCTAssertTrue(ok)
        XCTAssertNil(error)
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), "n.e.w")
        XCTAssertEqual(KeychainManager.load(key: "refreshToken"), "r.e.f")
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "accessToken_expire_in"), 1800)
        XCTAssertGreaterThanOrEqual(UserDefaults.standard.double(forKey: "accessToken_Generate"), before)
    }

    func testTheStoredRefreshTokenIsSentAsAHeader() throws {
        signIn()
        let stored = try XCTUnwrap(KeychainManager.load(key: "refreshToken"))
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply())
        _ = refresh()
        let sent = try XCTUnwrap(MockHTTP.requests(pathRegex: "refresh-token$").first)
        XCTAssertEqual(sent.header("refresh_token"), stored)
        XCTAssertTrue(sent.body?.isEmpty ?? true, "the token moved from the body to a header")
    }

    func testAnExplicitTokenWinsOverTheStoredOne() throws {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply())
        _ = refresh("explicit-token")
        XCTAssertEqual(MockHTTP.requests(pathRegex: "refresh-token$").first?.header("refresh_token"), "explicit-token")
    }

    func testRejectionLeavesTheStoredTokensUntouched() {
        signIn()
        let access = KeychainManager.load(key: "accessToken")
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .status(401))

        let (ok, error) = refresh()

        XCTAssertFalse(ok)
        XCTAssertNotNil(error)
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), access)
    }

    func testOutagesAreReportedAsFailures() {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .offline)
        let (ok, error) = refresh()
        XCTAssertFalse(ok)
        guard case .noNetworkConnection? = error as? APIError else { return XCTFail("got \(String(describing: error))") }
    }

    func testAsyncWrapperReportsTheOutcome() async {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply())
        let refreshed = await TokenRefresher.shared.refreshTokenAsync()
        XCTAssertTrue(refreshed)

        MockHTTP.reset()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .status(500))
        let failed = await TokenRefresher.shared.refreshTokenAsync()
        XCTAssertFalse(failed)
    }

    func testOverlappingRefreshesAllCompleteWithTheSameOutcome() {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply().delayed(0.2))
        // Completions arrive on background queues, and a refresh that overlaps another may be
        // reported both directly and through the shared waiter list - so count, don't order.
        let lock = NSLock()
        var results: [Bool] = []
        let done = expectation(description: "both callers answered")
        done.expectedFulfillmentCount = 2
        done.assertForOverFulfill = false
        let record: (Bool, Error?) -> Void = { ok, _ in
            lock.lock(); results.append(ok); lock.unlock()
            done.fulfill()
        }
        TokenRefresher.shared.refreshToken(completion: record)
        TokenRefresher.shared.refreshToken(completion: record)
        wait(for: [done], timeout: 5)
        lock.lock(); defer { lock.unlock() }
        XCTAssertGreaterThanOrEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0 })
    }
}

// MARK: - PosmLoginViewModel

final class PosmLoginViewModelTests: AppTestCase {

    private var model: PosmLoginViewModel!

    override func setUp() {
        super.setUp()
        model = PosmLoginViewModel()
    }

    private var loggedInFlag: Bool { UserDefaults.standard.bool(forKey: "loggedIn") }

    func testNoCredentialsIsRejectedLocally() {
        model.performLogin(for: .production)
        XCTAssertEqual(model.errorMessage, "Enter username and password")
        XCTAssertTrue(model.shouldShowValidationAlert)
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testMissingPasswordOrUsernameIsReportedSpecifically() {
        model.username = "someone"
        model.performLogin(for: .production)
        XCTAssertEqual(model.errorMessage, "Password is required.")

        model.shouldShowValidationAlert = false
        model.username = ""
        model.password = "pw"
        model.performLogin(for: .production)
        XCTAssertEqual(model.errorMessage, "Username is required.")
        XCTAssertTrue(model.shouldShowValidationAlert)
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testSuccessfulLoginSignsTheUserInAndRemembersTheUsername() {
        // Declining the biometric opt-in keeps this deterministic whether or not the
        // machine running the tests has Face ID enrolled.
        SessionManager.shared.setDeclinedBiometric(true, for: .production)
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        model.username = "tester@example.com"
        model.password = "pw"

        model.performLogin(for: .production)
        XCTAssertTrue(model.isLoading, "the spinner shows while the request is in flight")
        waitUntil("login did not finish") { model.isLoginSuccess }

        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.hasLoginFailed)
        XCTAssertFalse(model.showBiometricPrompt)
        XCTAssertTrue(loggedInFlag)
        XCTAssertEqual(KeychainManager.load(.username, for: .production), "tester@example.com")
    }

    func testRejectedCredentialsFlagTheFailure() {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginFailure", status: 401))
        model.username = "tester@example.com"
        model.password = "wrong"

        model.performLogin(for: .production)
        waitUntil("login did not fail") { model.hasLoginFailed }

        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.isLoginSuccess)
        XCTAssertFalse(loggedInFlag)
        XCTAssertNil(KeychainManager.load(.username, for: .production))
    }

    func testTheBiometricOptInIsOfferedOnlyWhenAvailableAndNotDeclined() {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        model.username = "tester@example.com"
        model.password = "pw"

        model.performLogin(for: .production)
        // Either the prompt appears (biometrics enrolled) or login completes straight away.
        waitUntil("login did not settle") { model.showBiometricPrompt || model.isLoginSuccess }

        if BiometricAuthManager.canEvaluateBiometrics() {
            XCTAssertTrue(model.showBiometricPrompt)
            XCTAssertFalse(model.isLoginSuccess, "navigation waits for the user's answer to the prompt")
        } else {
            XCTAssertFalse(model.showBiometricPrompt)
            XCTAssertTrue(model.isLoginSuccess)
        }
    }

    func testEnableBiometricsDoesNothingBeforeALogin() {
        model.enableBiometrics(enable: false)
        XCTAssertFalse(model.isLoginSuccess)
        XCTAssertFalse(SessionManager.shared.hasDeclinedBiometric(for: .production))
    }

    func testDecliningBiometricsRecordsTheChoiceAndFinishesLogin() {
        SessionManager.shared.setDeclinedBiometric(true, for: .production)
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        model.username = "tester@example.com"
        model.password = "pw"
        model.performLogin(for: .production)
        waitUntil { model.isLoginSuccess }
        SessionManager.shared.setDeclinedBiometric(false, for: .production)
        model.isLoginSuccess = false

        model.enableBiometrics(enable: false)

        XCTAssertTrue(SessionManager.shared.hasDeclinedBiometric(for: .production))
        XCTAssertTrue(model.isLoginSuccess)
    }

    func testRefreshTokenLoginSignsInAndStoresTheEmailFromTheJWT() {
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .fixture("LoginSuccess"))

        model.loginWithRefreshToken(refreshToken: "saved-refresh-token")
        XCTAssertTrue(model.isLoading)
        waitUntil("refresh login did not finish") { model.isLoginSuccess }

        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.hasLoginFailed)
        XCTAssertTrue(loggedInFlag)
        XCTAssertEqual(MockHTTP.requests(pathRegex: "refresh-token$").first?.header("refresh_token"), "saved-refresh-token")
        // "email" claim of the fixture's access token.
        XCTAssertEqual(KeychainManager.load(.username, for: APIConfiguration.shared.environment), "test@email.com")
    }

    func testRefreshTokenLoginFailureFlagsTheErrorAndShowsAMessage() {
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .status(401))

        model.loginWithRefreshToken(refreshToken: "expired")
        waitUntil("refresh login did not fail") { model.hasLoginFailed }

        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.isLoginSuccess)
        XCTAssertFalse(loggedInFlag)
        XCTAssertEqual(model.loginFailedMessage, L10n.Localizable.invalidCredentials)
    }
}

// MARK: - PasswordAuthenticationViewModel

@MainActor
final class PasswordAuthenticationViewModelTests: AppTestCase {

    func testAWrongPasswordIsReportedWithoutTouchingBiometrics() {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginFailure", status: 401))
        let model = PasswordAuthenticationViewModel()
        model.password = "wrong"

        let failed = expectation(description: "failure")
        var failureMessage: String?
        model.performBiometricEnrollment(username: "tester@example.com", environment: .production,
                                         onSuccess: { XCTFail("must not succeed") },
                                         onFailure: { failureMessage = $0; failed.fulfill() })
        XCTAssertTrue(model.isLoading)
        wait(for: [failed], timeout: 5)

        XCTAssertEqual(failureMessage, "Invalid username or password.")
        XCTAssertEqual(model.errorMessage, "Invalid username or password.")
        XCTAssertFalse(model.isLoading)
    }

    func testACorrectPasswordStillFailsCleanlyWhenBiometricsAreUnavailable() throws {
        try XCTSkipIf(BiometricAuthManager.canEvaluateBiometrics(), "this machine has biometrics enrolled; the real Face ID prompt would appear")
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        let model = PasswordAuthenticationViewModel()
        model.password = "right"

        let failed = expectation(description: "failure")
        var failureMessage: String?
        model.performBiometricEnrollment(username: "tester@example.com", environment: .production,
                                         onSuccess: { XCTFail("no biometrics, so no enrolment") },
                                         onFailure: { failureMessage = $0; failed.fulfill() })
        wait(for: [failed], timeout: 5)

        XCTAssertEqual(failureMessage, "An error occured. Please try again.")
        XCTAssertFalse(model.errorMessage.isEmpty, "the underlying biometric error is shown to the user")
        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(SessionManager.shared.isBiometricEnabled(for: .production), "nothing may be enabled when enrolment failed")
    }
}

// MARK: - BiometricAuthManager

final class BiometricAuthManagerTests: XCTestCase {

    func testLabelAndIconMatchTheDeviceBiometricType() {
        switch BiometricAuthManager.biometricType() {
        case .faceID:
            XCTAssertEqual(BiometricAuthManager.biometricLabelText(), "Login with Face ID")
            XCTAssertEqual(BiometricAuthManager.biometricIcon(), "faceid")
        case .touchID:
            XCTAssertEqual(BiometricAuthManager.biometricLabelText(), "Login with Touch ID")
            XCTAssertEqual(BiometricAuthManager.biometricIcon(), "lock")
        default:
            XCTAssertEqual(BiometricAuthManager.biometricLabelText(), "Login with Biometrics")
            XCTAssertEqual(BiometricAuthManager.biometricIcon(), "lock")
        }
    }

    func testCanEvaluateMatchesTheSystemAnswerOutsideUITestScenarios() {
        XCTAssertEqual(BiometricAuthManager.canEvaluateBiometrics(),
                       LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil))
    }

    func testAuthenticateReportsUnavailableWhenNothingIsEnrolled() throws {
        try XCTSkipIf(BiometricAuthManager.canEvaluateBiometrics(), "biometrics are enrolled here; authenticating would raise a real prompt")
        let exp = expectation(description: "auth")
        var result: BiometricAuthManager.BiometricAuthResult?
        BiometricAuthManager.authenticate(reason: "test") { result = $0; exp.fulfill() }
        wait(for: [exp], timeout: 2)
        guard case .unavailable(let message)? = result else { return XCTFail("Expected .unavailable, got \(String(describing: result))") }
        XCTAssertFalse(message.isEmpty)
    }
}

// MARK: - User profile

final class UserProfileTests: AppTestCase {

    func testFullNameCombinesWhateverPartsExist() {
        XCTAssertEqual(TdeiUserProfile(id: nil, firstName: "Srikanth", lastName: "Voonna", email: nil).getFullName(), "Srikanth Voonna")
        XCTAssertEqual(TdeiUserProfile(id: nil, firstName: "Srikanth", lastName: nil, email: nil).getFullName(), "Srikanth")
        XCTAssertEqual(TdeiUserProfile(id: nil, firstName: nil, lastName: "Voonna", email: nil).getFullName(), "Voonna")
        XCTAssertEqual(TdeiUserProfile(id: nil, firstName: nil, lastName: nil, email: "x@y.z").getFullName(), "")
    }

    func testDecodesTheUserProfileFixture() throws {
        let profile = try JSONDecoder().decode(TdeiUserProfile.self, from: MockHTTP.fixture("UserProfilePlaceholder"))
        XCTAssertEqual(profile.firstName, "Srikanth")
        XCTAssertEqual(profile.lastName, "Voonna")
        XCTAssertEqual(profile.email, "prateekan6@gmail.com")
        XCTAssertEqual(profile.getFullName(), "Srikanth Voonna")
    }

    func testCacheStoresAndClears() {
        let profile = TdeiUserProfile(id: "1", firstName: "A", lastName: "B", email: "a@b.c")
        UserProfileCache.shared.cacheUserProfile(profile)
        XCTAssertEqual(UserProfileCache.shared.user?.id, "1")
        UserProfileCache.shared.clearUserProfile()
        XCTAssertNil(UserProfileCache.shared.user)
    }

    func testViewModelStartsFromTheCachedProfile() {
        UserProfileCache.shared.cacheUserProfile(TdeiUserProfile(id: "1", firstName: "Cached", lastName: "User", email: nil))
        let model = UserProfileViewModel()
        XCTAssertEqual(model.user?.firstName, "Cached")
        XCTAssertTrue(MockHTTP.requests.isEmpty, "a cached profile needs no request")
    }

    func testViewModelFetchesTheProfileWhenSignedInAndNothingIsCached() {
        signIn(username: "prateekan6@gmail.com")
        MockHTTP.stub("GET", pathRegex: "user-profile$", reply: .fixture("UserProfilePlaceholder"))

        let model = UserProfileViewModel()
        waitUntil("profile never loaded") { model.user != nil }

        XCTAssertEqual(model.user?.email, "prateekan6@gmail.com")
        XCTAssertEqual(UserProfileCache.shared.user?.firstName, "Srikanth", "a fetched profile is cached")
        let sent = MockHTTP.requests(pathRegex: "user-profile$").first
        XCTAssertEqual(sent?.url.query, "user_name=prateekan6@gmail.com")
        XCTAssertEqual(sent?.header("Authorization"), "Bearer \(fixtureAccessToken)")
    }

    func testViewModelDoesNotFetchWithoutAUsernameOrAToken() {
        let model = UserProfileViewModel()
        model.fetchUserProfile()
        XCTAssertNil(model.user)
        XCTAssertTrue(MockHTTP.requests.isEmpty)

        _ = KeychainManager.save(.username, value: "someone", for: .production)   // username but no token
        model.fetchUserProfile()
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testAFailedFetchLeavesTheProfileEmpty() {
        signIn()
        MockHTTP.stub("GET", pathRegex: "user-profile$", reply: .fixture("UserProfileServerError", status: 500))
        let model = UserProfileViewModel()
        waitUntil("request not sent") { !MockHTTP.requests(pathRegex: "user-profile$").isEmpty }
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertNil(model.user)
        XCTAssertNil(UserProfileCache.shared.user)
    }

    func testFullNameHelperOnTheViewModel() {
        let model = UserProfileViewModel()
        XCTAssertNil(model.userFullName())
        model.user = TdeiUserProfile(id: nil, firstName: "Ada", lastName: "Lovelace", email: nil)
        XCTAssertEqual(model.userFullName(), "Ada Lovelace")
        model.user = TdeiUserProfile(id: nil, firstName: "Ada", lastName: nil, email: nil)
        XCTAssertEqual(model.userFullName(), "Ada")
        model.user = TdeiUserProfile(id: nil, firstName: nil, lastName: "Lovelace", email: nil)
        XCTAssertEqual(model.userFullName(), "Lovelace")
        model.user = TdeiUserProfile(id: nil, firstName: nil, lastName: nil, email: "e@x")
        XCTAssertNil(model.userFullName())
    }
}

// MARK: - Utilities

final class UtilitiesTests: AppTestCase {

    func testClearAllDataEndsTheSession() {
        signIn()
        UserDefaults.standard.set(true, forKey: "loggedIn")
        UserProfileCache.shared.cacheUserProfile(TdeiUserProfile(id: "1", firstName: "A", lastName: "B", email: nil))

        Utilities.clearAllData()

        XCTAssertNil(KeychainManager.load(key: "accessToken"))
        XCTAssertNil(KeychainManager.load(key: "refreshToken"))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "loggedIn"))
        XCTAssertNil(UserProfileCache.shared.user)
        XCTAssertNil(UserDefaults.standard.object(forKey: APIConfiguration.environmentKey), "the chosen environment is forgotten")
        XCTAssertEqual(APIConfiguration.shared.environment, .production)
    }

    func testClearAllDataKeepsTheWorkspaceAndSavedUsername() {
        signIn(workspaceID: "222")
        Utilities.clearAllData()
        XCTAssertEqual(KeychainManager.load(key: "workspaceID"), "222")
        XCTAssertEqual(KeychainManager.load(.username, for: .production), "test@email.com")
    }

    func testCardinalDirectionsAcrossTheCompass() {
        let expected: [(Double, String)] = [
            (0, "North"), (10, "North"), (22.4, "North"), (45, "North East"), (90, "East"), (135, "South East"),
            (180, "South"), (225, "South West"), (270, "West"), (315, "Noth West"), (350, "North"), (359.9, "North")
        ]
        for (bearing, direction) in expected {
            XCTAssertEqual(Utilities.degreesToCardinalDirection(bearing: bearing), direction, "bearing \(bearing)")
        }
    }

    func testNavigationControllerLookupWalksChildrenAndTabs() {
        XCTAssertNil(NavigationUtil.findNavigationController(viewController: nil))
        XCTAssertNil(NavigationUtil.findNavigationController(viewController: UIViewController()))

        let nav = UINavigationController(rootViewController: UIViewController())
        XCTAssertTrue(NavigationUtil.findNavigationController(viewController: nav) === nav)

        let container = UIViewController()
        container.addChild(nav)
        XCTAssertTrue(NavigationUtil.findNavigationController(viewController: container) === nav, "found through a child")

        let tabs = UITabBarController()
        tabs.viewControllers = [nav]
        tabs.selectedIndex = 0
        XCTAssertTrue(NavigationUtil.findNavigationController(viewController: tabs) === nav, "found through the selected tab")
    }
}
