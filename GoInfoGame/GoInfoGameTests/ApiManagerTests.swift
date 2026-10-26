//
//  ApiManagerTests.swift
//  GoInfoGameTests
//
//  ApiManager.performRequest end to end against MockHTTP: URL building per SetupType,
//  header/body handling, status-code mapping, JSON vs plain-text decoding, the 401
//  refresh-and-retry path and multipart uploads. Response bodies come from the same JSON
//  fixtures the UI tests serve.
//

import XCTest
import CoreLocation
@testable import GoInfoGame

final class ApiManagerTests: AppTestCase {

    // MARK: Helpers

    @discardableResult
    private func perform<T: Decodable>(_ endpoint: APIEndpoint, setup: SetupType = .osm, as model: T.Type,
                                       useJSON: Bool = true, timeout: TimeInterval = 5,
                                       file: StaticString = #filePath, line: UInt = #line) -> Result<T, APIError> {
        let exp = expectation(description: "request")
        var outcome: Result<T, APIError>?
        ApiManager.shared.performRequest(to: endpoint, setupType: setup, modelType: model, useJSON: useJSON) { result in
            outcome = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: timeout)
        guard let outcome else {
            XCTFail("request never completed", file: file, line: line)
            return .failure(.custom("never completed"))
        }
        return outcome
    }

    private func get(_ path: String, headers: [String: String]? = nil) -> APIEndpoint {
        APIEndpoint(path: path, method: "GET", body: nil, headers: headers, formData: nil)
    }

    private func errorOf<T>(_ result: Result<T, APIError>, file: StaticString = #filePath, line: UInt = #line) -> APIError? {
        if case .failure(let error) = result { return error }
        XCTFail("expected failure, got success", file: file, line: line)
        return nil
    }

    private func customMessage(_ error: APIError?) -> String? {
        if case .custom(let message)? = error { return message }
        return nil
    }

    // MARK: URL building

    func testEverySetupTypeTargetsItsOwnBaseURL() {
        APIConfiguration.shared.environment = .staging
        MockHTTP.stubAll(.json("{}"))
        let expected: [(SetupType, String)] = [
            (.workspace, APIEnvironment.staging.workspaceBaseURL),
            (.login, APIEnvironment.staging.loginBaseURL),
            (.osm, APIEnvironment.staging.osmBaseURL),
            (.userProfile, APIEnvironment.staging.userProfileBaseURL),
            (.kartaview, APIEnvironment.staging.kartaViewBaseURL),
            (.kartaviewV2, APIEnvironment.staging.kartaViewV2BaseURL)
        ]
        for (setup, base) in expected {
            MockHTTP.reset()
            MockHTTP.stubAll(.json("{}"))
            perform(get("/probe"), setup: setup, as: [String: String].self)
            XCTAssertEqual(MockHTTP.requests.first?.url.absoluteString, base + "/probe", "wrong URL for \(setup)")
        }
    }

    // MARK: Request construction

    func testSendsMethodBodyAndEndpointHeaders() {
        MockHTTP.stub("POST", path: "/prod/api/0.6/echo", reply: .json("{}"))
        let body = Data("payload".utf8)
        let endpoint = APIEndpoint(path: "/echo", method: "POST", body: body, headers: ["X-Workspace": "222", "Content-Type": "application/xml"], formData: nil)
        perform(endpoint, as: [String: String].self)

        let sent = MockHTTP.requests(path: "/prod/api/0.6/echo").first
        XCTAssertEqual(sent?.method, "POST")
        XCTAssertEqual(sent?.bodyString, "payload")
        XCTAssertEqual(sent?.header("X-Workspace"), "222")
        XCTAssertEqual(sent?.header("Content-Type"), "application/xml")
    }

    func testAttachesTheStoredAccessTokenAsBearerAuthorization() {
        signIn()
        MockHTTP.stubAll(.json("{}"))
        perform(get("/who"), as: [String: String].self)
        XCTAssertEqual(MockHTTP.requests.first?.header("Authorization"), "Bearer \(fixtureAccessToken)")
    }

    func testOmitsAuthorizationWhenSignedOut() {
        MockHTTP.stubAll(.json("{}"))
        perform(get("/who"), as: [String: String].self)
        XCTAssertNil(MockHTTP.requests.first?.header("Authorization"))
    }

    func testKartaViewRequestsNeverCarryTheAppToken() {
        signIn()
        for setup in [SetupType.kartaview, .kartaviewV2] {
            MockHTTP.reset()
            MockHTTP.stubAll(.json("{}"))
            perform(get("/probe"), setup: setup, as: [String: String].self)
            XCTAssertNil(MockHTTP.requests.first?.header("Authorization"), "the app's login token was sent to \(setup)")
        }
    }

    func testEndpointHeadersOverrideTheStoredToken() {
        signIn()
        MockHTTP.stubAll(.json("{}"))
        perform(get("/who", headers: ["Authorization": "Bearer explicit"]), as: [String: String].self)
        XCTAssertEqual(MockHTTP.requests.first?.header("Authorization"), "Bearer explicit")
    }

    func testPlainRequestsGetASixtySecondTimeout() {
        MockHTTP.stubAll(.json("{}"))
        perform(get("/t"), as: [String: String].self)
        XCTAssertEqual(MockHTTP.requests.first?.request.timeoutInterval, 60)
    }

    func testMultipartFormDataIsEncodedWithBoundaryTextAndFileParts() throws {
        MockHTTP.stubAll(.json("{}"))
        let form: [[String: Any]] = [
            ["key": "access_token", "value": "abc", "type": "text"],
            ["key": "photo", "src": Data([0xFF, 0xD8, 0xFF]), "filename": "pic.jpeg", "contentType": "image/jpeg", "type": "file"],
            ["key": "defaults", "src": Data([1, 2])],
            ["value": "no key is skipped"],
            ["key": "unsupported", "value": 12345]
        ]
        let endpoint = APIEndpoint(path: "/photo/", method: "POST", body: nil, headers: nil, formData: form)
        perform(endpoint, setup: .kartaview, as: [String: String].self)

        let sent = try XCTUnwrap(MockHTTP.requests.first)
        let contentType = try XCTUnwrap(sent.header("Content-Type"))
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary=Boundary-"))
        XCTAssertEqual(sent.request.timeoutInterval, 120, "multipart uploads get a longer idle timeout, but never an infinite one")

        let body = try XCTUnwrap(sent.body)
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(text.contains("name=\"access_token\"\r\n\r\nabc\r\n"))
        XCTAssertTrue(text.contains("name=\"photo\"; filename=\"pic.jpeg\"\r\nContent-Type: image/jpeg"))
        XCTAssertTrue(text.contains("name=\"defaults\"; filename=\"image.jpeg\"\r\nContent-Type: application/octet-stream"))
        XCTAssertFalse(text.contains("no key is skipped"))
        XCTAssertFalse(text.contains("unsupported"), "an unsupported value type is dropped, not sent")
        XCTAssertNotNil(body.range(of: Data([0xFF, 0xD8, 0xFF])), "the raw file bytes must be embedded")
        let boundary = contentType.replacingOccurrences(of: "multipart/form-data; boundary=", with: "")
        XCTAssertTrue(text.hasSuffix("--\(boundary)--\r\n"), "the form must end with the closing boundary")
    }

    // MARK: Success decoding (shared fixtures)

    func testDecodesWorkspaceListFixture() throws {
        MockHTTP.stub("GET", path: "/api/v1/workspaces/mine", reply: .fixture("WorkspacesSingle"))
        let endpoint = APIEndpoint.fetchWorkspaceList(CLLocationCoordinate2D(latitude: 17.4385, longitude: 78.361), 20000, true, "tok")
        let workspaces = try perform(endpoint, setup: .workspace, as: [Workspace].self).get()
        XCTAssertEqual(workspaces.count, 1)
        XCTAssertEqual(workspaces.first?.id, 222)
        XCTAssertEqual(workspaces.first?.title, "Copy from Stage Kondapur Dataset")
    }

    func testDecodesLoginFixtureIntoTokens() throws {
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        let response = try perform(.login(Data("{}".utf8)), setup: .login, as: PosmLoginSuccessResponse.self).get()
        XCTAssertEqual(response.expiresIn, 86400)
        XCTAssertEqual(response.refreshExpiresIn, 172800)
        XCTAssertEqual(JWTDecoder.subject(fromToken: response.accessToken), "uitest-user-0001")
    }

    func testDecodesIso8601DatesInResponses() throws {
        struct Stamped: Decodable { let at: Date }
        MockHTTP.stubAll(.json(#"{"at":"2026-09-02T11:55:52Z"}"#))
        let stamped = try perform(get("/d"), as: Stamped.self).get()
        XCTAssertEqual(stamped.at.timeIntervalSince1970, 1_788_350_152, accuracy: 1)
    }

    // MARK: Status-code mapping

    func testClientErrorsBecomeAGenericCustomError() {
        for status in [400, 403, 404, 422] {
            MockHTTP.reset()
            MockHTTP.stubAll(.statusWithBody(status, "nope"))
            let message = customMessage(errorOf(perform(get("/c"), as: [String: String].self)))
            XCTAssertEqual(message, "Client Error. Please try again later.", "status \(status)")
        }
    }

    func testServerErrorsBecomeAGenericCustomError() {
        for status in [500, 502, 503] {
            MockHTTP.reset()
            MockHTTP.stubAll(.statusWithBody(status, "oops"))
            let message = customMessage(errorOf(perform(get("/s"), as: [String: String].self)))
            XCTAssertEqual(message, "Internal server error. Please try again later.", "status \(status)")
        }
    }

    func testConflictOnANonJSONRequestIsReportedAsConflict() {
        // changeset upload (useJSON: false) - the signal DatasyncManager's conflict path relies on.
        MockHTTP.stubAll(.statusWithBody(409, "Version mismatch"))
        let result = perform(get("/changeset/1/upload"), as: String.self, useJSON: false)
        guard case .conflict? = errorOf(result) else { return XCTFail("Expected .conflict, got \(result)") }
    }

    func testGoneOnADotJSONResourceIsReportedAsDeleted() {
        MockHTTP.stub("GET", path: "/prod/api/0.6/way/9.json", reply: .statusWithBody(410, "gone"))
        let result = perform(get("/way/9.json"), as: [String: String].self)
        guard case .deleted? = errorOf(result) else { return XCTFail("Expected .deleted, got \(result)") }
    }

    func testGoneOnANonJSONRequestMapsThroughTheStatusCodeInitialiser() {
        MockHTTP.stubAll(.statusWithBody(410, "gone"))
        let result = perform(get("/changeset/1/upload"), as: String.self, useJSON: false)
        guard case .deleted? = errorOf(result) else { return XCTFail("Expected .deleted, got \(result)") }
    }

    func testUnexpectedSuccessStatusOnANonJSONRequestIsAnUnknownError() {
        MockHTTP.stubAll(.statusWithBody(204, "x"))
        let result = perform(get("/x"), as: String.self, useJSON: false)
        guard case .unknown(let code, _)? = errorOf(result) else { return XCTFail("Expected .unknown, got \(result)") }
        XCTAssertEqual(code, 204)
    }

    // MARK: Transport failures

    func testNotConnectedBecomesNoNetworkConnection() {
        MockHTTP.stubAll(.offline)
        let result = perform(get("/n"), as: [String: String].self)
        guard case .noNetworkConnection? = errorOf(result) else { return XCTFail("Expected .noNetworkConnection, got \(result)") }
    }

    func testOtherTransportErrorsBecomeACustomFailureMessage() {
        MockHTTP.stubAll(.failure(URLError(.timedOut)))
        let message = customMessage(errorOf(perform(get("/n"), as: [String: String].self)))
        XCTAssertTrue(message?.hasPrefix("Request failed with error:") == true, "got \(String(describing: message))")
    }

    // MARK: Bodies

    func testEmptyBodyIsSuccessForBoolModelsAndAnErrorOtherwise() {
        MockHTTP.stubAll(.json(Data(), status: 200))
        XCTAssertEqual(try? perform(get("/close"), as: Bool.self).get(), true)

        let message = customMessage(errorOf(perform(get("/close"), as: [String: String].self)))
        XCTAssertEqual(message, "Unexpected empty response")
    }

    func testUndecodableJSONLeaksTheRawBodyOnlyOutsideProduction() {
        MockHTTP.stubAll(.json("<html>not json</html>"))

        APIConfiguration.shared.environment = .development
        XCTAssertEqual(customMessage(errorOf(perform(get("/j"), as: [String: String].self))), "Not a valid JSON <html>not json</html>")

        APIConfiguration.shared.environment = .staging
        XCTAssertEqual(customMessage(errorOf(perform(get("/j"), as: [String: String].self))), "Not a valid JSON <html>not json</html>")

        APIConfiguration.shared.environment = .production
        XCTAssertEqual(customMessage(errorOf(perform(get("/j"), as: [String: String].self))),
                       "Not able to process the response at this moment. Please try again later.")
    }

    func testUndecodableNonUTF8BodyReportsEmptyJSON() {
        MockHTTP.stubAll(.json(Data([0xFF, 0xFE, 0xFD])))
        XCTAssertEqual(customMessage(errorOf(perform(get("/j"), as: [String: String].self))), "Empty JSON")
    }

    func testNonJSONRequestsReturnTheRawBodyString() throws {
        MockHTTP.stubAll(.text("<diffResult/>"))
        XCTAssertEqual(try perform(get("/changeset/1/upload"), as: String.self, useJSON: false).get(), "<diffResult/>")
    }

    // MARK: 401 -> refresh token -> retry

    private func refreshReply(access: String = "new.access.token", refresh: String = "new.refresh.token") -> MockHTTP.Reply {
        .json(#"{"access_token":"\#(access)","expires_in":3600,"refresh_expires_in":7200,"refresh_token":"\#(refresh)"}"#)
    }

    func testAnExpiredTokenIsRefreshedAndTheOriginalRequestRetriedWithTheNewToken() throws {
        signIn()
        let originalRefreshToken = KeychainManager.load(key: "refreshToken")
        var calls = 0
        MockHTTP.stub("GET", path: "/prod/api/0.6/secure.json") { recorded in
            calls += 1
            return recorded.header("Authorization") == "Bearer new.access.token" ? .json(#"{"ok":"yes"}"#) : .status(401)
        }
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply())

        let endpoint = get("/secure.json", headers: ["Authorization": "Bearer stale", "Content-Type": "application/json"])
        let value = try perform(endpoint, as: [String: String].self).get()

        XCTAssertEqual(value["ok"], "yes")
        XCTAssertEqual(calls, 2, "original request + exactly one retry")
        XCTAssertEqual(MockHTTP.requests(pathRegex: "refresh-token$").count, 1)
        XCTAssertEqual(MockHTTP.requests(pathRegex: "refresh-token$").first?.header("refresh_token"), originalRefreshToken,
                       "the stored refresh token must be what is sent")
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), "new.access.token")
        XCTAssertEqual(KeychainManager.load(key: "refreshToken"), "new.refresh.token")
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "accessToken_expire_in"), 3600)
    }

    func testAKartaView401FailsWithoutRefreshingTheAppToken() {
        signIn()
        MockHTTP.stubAll(.status(401))
        let result = perform(get("/sequence/"), setup: .kartaview, as: [String: String].self)
        XCTAssertEqual(customMessage(errorOf(result)), "Client Error. Please try again later.")
        XCTAssertTrue(MockHTTP.requests(pathRegex: "refresh-token$").isEmpty,
                      "refreshing the app token can't fix a KartaView 401 — it used to loop forever")
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), fixtureAccessToken, "the session is untouched")
    }

    func testARequestStillGetting401AfterARefreshFailsInsteadOfRefreshingAgain() {
        signIn()
        var calls = 0
        MockHTTP.stub("GET", path: "/prod/api/0.6/secure.json") { _ in
            calls += 1
            return .status(401)
        }
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: refreshReply())

        let result = perform(get("/secure.json"), as: [String: String].self)

        XCTAssertEqual(customMessage(errorOf(result)), "Client Error. Please try again later.")
        XCTAssertEqual(calls, 2, "original request + exactly one retry")
        XCTAssertEqual(MockHTTP.requests(pathRegex: "refresh-token$").count, 1)
    }

    func testRefreshAndAuthenticateEndpointsAreNeverRetriedOn401() {
        MockHTTP.stubAll(.status(401))
        let login = perform(APIEndpoint.login(Data("{}".utf8)), setup: .login, as: PosmLoginSuccessResponse.self)
        XCTAssertEqual(customMessage(errorOf(login)), "Client Error. Please try again later.")
        XCTAssertTrue(MockHTTP.requests(pathRegex: "refresh-token$").isEmpty, "a failed login must not trigger a token refresh")
    }

    func testAFailedRefreshEndsTheSessionAndReportsTheFailure() {
        signIn()
        MockHTTP.stub("GET", path: "/prod/api/0.6/secure.json", reply: .status(401))
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .status(401))

        let sessionExpired = XCTNSNotificationExpectation(name: Notification.Name("SessionExpired"))
        sessionExpired.isInverted = UIApplication.window() == nil   // only posted when a window exists to host the login screen

        let result = perform(get("/secure.json"), as: [String: String].self)

        XCTAssertEqual(customMessage(errorOf(result)), "Token refresh failed")
        waitUntil(timeout: 3, "session was not cleared") { KeychainManager.load(key: "accessToken") == nil }
        XCTAssertNil(KeychainManager.load(key: "refreshToken"))
        wait(for: [sessionExpired], timeout: sessionExpired.isInverted ? 0.5 : 4)
    }
}
