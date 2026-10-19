//
//  APIEndpointAndConfigTests.swift
//  GoInfoGameTests
//
//  Pure (no network) coverage of the request-building layer: APIError, APIEnvironment,
//  APIConfiguration, every APIEndpoint builder, JWTDecoder and ResponseManager.
//

import XCTest
import CoreLocation
@testable import GoInfoGame

final class APIErrorTests: XCTestCase {

    func testStatusCodeMapping() {
        XCTAssertEqual(APIError(statusCode: 400).errorDescription, APIError.badRequest.errorDescription)
        XCTAssertEqual(APIError(statusCode: 401).errorDescription, APIError.unauthorized.errorDescription)
        XCTAssertEqual(APIError(statusCode: 403).errorDescription, APIError.forbidden.errorDescription)
        XCTAssertEqual(APIError(statusCode: 409).errorDescription, APIError.conflict.errorDescription)
        XCTAssertEqual(APIError(statusCode: 410).errorDescription, APIError.deleted.errorDescription)
        XCTAssertEqual(APIError(statusCode: 500).errorDescription, APIError.serverError.errorDescription)
    }

    func testNotFoundUsesContextOrFallsBackToItem() {
        XCTAssertEqual(APIError(statusCode: 404, context: "Workspace").errorDescription, "Workspace could not be found.")
        XCTAssertEqual(APIError(statusCode: 404).errorDescription, "Item could not be found.")
    }

    func testUnknownStatusCarriesCodeAndLocalizedDescription() {
        let error = APIError(statusCode: 418)
        guard case .unknown(let code, let description) = error else { return XCTFail("Expected .unknown, got \(error)") }
        XCTAssertEqual(code, 418)
        XCTAssertEqual(description, HTTPURLResponse.localizedString(forStatusCode: 418))
        XCTAssertEqual(error.errorDescription, "Unexpected error: \(description)")
    }

    func testEveryCaseHasAUserFacingDescription() {
        let cases: [(APIError, String)] = [
            (.invalidURL, "Invalid URL."),
            (.noData, "No data returned from the server."),
            (.decodingFailed("boom"), "Failed to decode data: boom"),
            (.custom("hello"), "hello"),
            (.noNetworkConnection, "No network connection."),
            (.badRequest, "Bad Request: The request was invalid."),
            (.unauthorized, "Unauthorized: Please log in again."),
            (.forbidden, "Forbidden: You don’t have permission."),
            (.conflict, "Conflict: The data has changed on the server."),
            (.serverError, "Internal server error. Please try again later."),
            (.deleted, "Deleted: The element is deleted from the server.")
        ]
        for (error, expected) in cases {
            XCTAssertEqual(error.errorDescription, expected)
            XCTAssertEqual(error.localizedDescription, expected)
        }
        let wrapped = APIError.requestFailed(URLError(.timedOut))
        XCTAssertTrue(wrapped.errorDescription?.hasPrefix("Request failed:") == true)
    }
}

final class APIEnvironmentTests: XCTestCase {

    func testRawValuesAndAllCases() {
        XCTAssertEqual(APIEnvironment.development.rawValue, "dev")
        XCTAssertEqual(APIEnvironment.staging.rawValue, "stage")
        XCTAssertEqual(APIEnvironment.production.rawValue, "prod")
        XCTAssertEqual(APIEnvironment.allCases.count, 3)
        XCTAssertEqual(APIEnvironment(rawValue: "stage"), .staging)
        XCTAssertNil(APIEnvironment(rawValue: "qa"))
    }

    func testDisplayStrings() {
        XCTAssertEqual(APIEnvironment.development.displayString(), "Development")
        XCTAssertEqual(APIEnvironment.staging.displayString(), "Staging")
        XCTAssertEqual(APIEnvironment.production.displayString(), "Production")
    }

    func testEveryEnvironmentHasWellFormedBaseURLs() {
        for env in APIEnvironment.allCases {
            let urls = [env.workspaceBaseURL, env.loginBaseURL, env.osmBaseURL, env.userProfileBaseURL,
                        env.kartaViewBaseURL, env.kartaViewV2BaseURL]
            for string in urls {
                let url = URL(string: string)
                XCTAssertNotNil(url, "\(env) has a malformed base URL: \(string)")
                XCTAssertEqual(url?.scheme, "https", "\(env) base URL is not https: \(string)")
            }
        }
    }

    func testBaseURLsAreSpecificToTheEnvironment() {
        XCTAssertTrue(APIEnvironment.development.workspaceBaseURL.contains("workspaces-dev"))
        XCTAssertTrue(APIEnvironment.staging.workspaceBaseURL.contains("workspaces-stage"))
        XCTAssertFalse(APIEnvironment.production.workspaceBaseURL.contains("-dev"))
        XCTAssertTrue(APIEnvironment.development.loginBaseURL.contains("-dev"))
        XCTAssertTrue(APIEnvironment.staging.loginBaseURL.contains("-stage"))
        XCTAssertTrue(APIEnvironment.development.osmBaseURL.hasSuffix("/dev/api/0.6"))
        XCTAssertTrue(APIEnvironment.staging.osmBaseURL.hasSuffix("/stage/api/0.6"))
        XCTAssertTrue(APIEnvironment.production.osmBaseURL.hasSuffix("/prod/api/0.6"))
        XCTAssertTrue(APIEnvironment.development.userProfileBaseURL.contains("-dev"))
        XCTAssertTrue(APIEnvironment.staging.userProfileBaseURL.contains("-stage"))
        XCTAssertTrue(APIEnvironment.production.userProfileBaseURL.contains("-prod"))
        XCTAssertTrue(APIEnvironment.production.kartaViewV2BaseURL.hasSuffix("/2.0"))
        XCTAssertTrue(APIEnvironment.production.kartaViewBaseURL.hasSuffix("/1.0"))
    }
}

final class APIConfigurationTests: AppTestCase {

    func testEnvironmentDefaultsToProduction() {
        XCTAssertEqual(APIConfiguration.shared.environment, .production)
    }

    func testEnvironmentPersistsAcrossReads() {
        APIConfiguration.shared.environment = .staging
        XCTAssertEqual(APIConfiguration.shared.environment, .staging)
        XCTAssertEqual(UserDefaults.standard.string(forKey: APIConfiguration.environmentKey), "stage")
    }

    func testCorruptedStoredEnvironmentFallsBackToProduction() {
        UserDefaults.standard.set("not-an-environment", forKey: APIConfiguration.environmentKey)
        XCTAssertEqual(APIConfiguration.shared.environment, .production)
    }

    func testURLsAreBuiltFromTheCurrentEnvironmentAndEndpointPath() {
        APIConfiguration.shared.environment = .development
        let endpoint = APIEndpoint(path: "/ping", method: "GET", body: nil, headers: nil, formData: nil)
        let config = APIConfiguration.shared
        XCTAssertEqual(config.workspaceUrl(for: endpoint)?.absoluteString, APIEnvironment.development.workspaceBaseURL + "/ping")
        XCTAssertEqual(config.loginUrl(for: endpoint)?.absoluteString, APIEnvironment.development.loginBaseURL + "/ping")
        XCTAssertEqual(config.osmUrl(for: endpoint)?.absoluteString, APIEnvironment.development.osmBaseURL + "/ping")
        XCTAssertEqual(config.userProfileUrl(for: endpoint)?.absoluteString, APIEnvironment.development.userProfileBaseURL + "/ping")
        XCTAssertEqual(config.kartaViewUrl(for: endpoint)?.absoluteString, APIEnvironment.development.kartaViewBaseURL + "/ping")
        XCTAssertEqual(config.kartaViewV2Url(for: endpoint)?.absoluteString, APIEnvironment.development.kartaViewV2BaseURL + "/ping")
    }

    func testSwitchingEnvironmentChangesSubsequentURLs() {
        let endpoint = APIEndpoint(path: "/x", method: "GET", body: nil, headers: nil, formData: nil)
        APIConfiguration.shared.environment = .staging
        XCTAssertTrue(APIConfiguration.shared.loginUrl(for: endpoint)!.absoluteString.contains("-stage"))
        APIConfiguration.shared.environment = .production
        XCTAssertFalse(APIConfiguration.shared.loginUrl(for: endpoint)!.absoluteString.contains("-stage"))
    }
}

final class APIEndpointTests: XCTestCase {

    private func bodyJSON(_ endpoint: APIEndpoint) -> [String: Any]? {
        endpoint.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    }

    func testLogin() {
        let payload = Data(#"{"username":"u","password":"p"}"#.utf8)
        let e = APIEndpoint.login(payload)
        XCTAssertEqual(e.path, "/authenticate")
        XCTAssertEqual(e.method, "POST")
        XCTAssertEqual(e.body, payload)
        XCTAssertEqual(e.headers?["Content-Type"], "application/json")
        XCTAssertNil(e.formData)
    }

    func testRefreshTokenSendsTokenAsHeaderWithNoBody() {
        // dev commit 01656f6d moved the refresh token from the body to a header.
        let e = APIEndpoint.refreshToken("tok-123")
        XCTAssertEqual(e.path, "/refresh-token")
        XCTAssertEqual(e.method, "POST")
        XCTAssertNil(e.body)
        XCTAssertEqual(e.headers?["refresh_token"], "tok-123")
        XCTAssertEqual(e.headers?["Content-Type"], "application/json")
    }

    func testFetchProjectGroupRoles() {
        let e = APIEndpoint.fetchProjectGroupRoles("user-1", "abc")
        XCTAssertEqual(e.path, "/project-group-roles/user-1?page_size=10000&page_no=1&sort_by=name")
        XCTAssertEqual(e.method, "GET")
        XCTAssertEqual(e.headers?["Authorization"], "Bearer abc")
    }

    func testFetchWorkspaceListRoundsCoordinatesTo7Digits() {
        let location = CLLocationCoordinate2D(latitude: 17.438512345678, longitude: 78.361098765432)
        let e = APIEndpoint.fetchWorkspaceList(location, 20000, true, "tok")
        XCTAssertEqual(e.method, "GET")
        XCTAssertEqual(e.path, "/workspaces/mine?lat=17.4385123&lon=78.3610988&radius=20000&gig_only=true")
        XCTAssertEqual(e.headers?["Authorization"], "Bearer tok")
    }

    func testFetchWorkspaceDetails() {
        let e = APIEndpoint.fetchWorkspaceDetails("222")
        XCTAssertEqual(e.path, "/workspaces/222")
        XCTAssertEqual(e.method, "GET")
        XCTAssertEqual(e.headers?["Content-Type"], "application/json")
    }

    func testFetchOSMElementsBuildsBBoxAndWorkspaceHeader() {
        let e = APIEndpoint.fetchOSMElements(78.3600000123, 17.4300000987, 78.3700, 17.4400, "222")
        XCTAssertEqual(e.path, "/map.json?bbox=78.36,17.4300001,78.37,17.44")
        XCTAssertEqual(e.method, "GET")
        XCTAssertEqual(e.headers?["X-Workspace"], "222")
    }

    func testChangesetEndpoints() {
        let xml = Data("<osm/>".utf8)

        let open = APIEndpoint.openChangesets("tok", "222", xml)
        XCTAssertEqual(open.path, "/changeset/create")
        XCTAssertEqual(open.method, "PUT")
        XCTAssertEqual(open.body, xml)
        XCTAssertEqual(open.headers?["Authorization"], "Bearer tok")
        XCTAssertEqual(open.headers?["X-Workspace"], "222")
        XCTAssertEqual(open.headers?["Content-Type"], "application/xml")

        let upload = APIEndpoint.uploadChangeset("tok", "775", "222", xml)
        XCTAssertEqual(upload.path, "/changeset/775/upload")
        XCTAssertEqual(upload.method, "POST")
        XCTAssertEqual(upload.body, xml)
        XCTAssertEqual(upload.headers?["X-Workspace"], "222")

        let close = APIEndpoint.closeChangeset("775", "222", "tok")
        XCTAssertEqual(close.path, "/changeset/775/close")
        XCTAssertEqual(close.method, "PUT")
        XCTAssertNil(close.body)
        XCTAssertEqual(close.headers?["Authorization"], "Bearer tok")
    }

    func testElementEndpoints() {
        let xml = Data("<osm/>".utf8)
        let update = APIEndpoint.updateWay("tok", "121949", xml)
        XCTAssertEqual(update.path, "/way/121949")
        XCTAssertEqual(update.method, "PUT")
        XCTAssertEqual(update.body, xml)

        let way = APIEndpoint.fetchLatestWay("222", "121949")
        XCTAssertEqual(way.path, "/way/121949.json")
        XCTAssertEqual(way.headers?["X-Workspace"], "222")

        let node = APIEndpoint.fetchLatestNode("222", "9001")
        XCTAssertEqual(node.path, "/node/9001.json")
        XCTAssertEqual(node.headers?["X-Workspace"], "222")
    }

    func testFetchUserProfile() {
        let e = APIEndpoint.fetchuserProfile("a@b.com", "tok")
        XCTAssertEqual(e.path, "/user-profile?user_name=a@b.com")
        XCTAssertEqual(e.method, "GET")
        XCTAssertEqual(e.headers?["Authorization"], "Bearer tok")
    }

    func testKartaviewEndpointsCarryFormDataAndNoHeaders() {
        let form: [[String: Any]] = [["key": "k", "value": "v", "type": "text"]]
        for (endpoint, path) in [(APIEndpoint.createKartaViewSequence(form), "/sequence/"),
                                 (APIEndpoint.uploadPhotoToKartaview(form), "/photo/"),
                                 (APIEndpoint.finshedUploadingToKartaview(form), "/sequence/finished-uploading/")] {
            XCTAssertEqual(endpoint.path, path)
            XCTAssertEqual(endpoint.method, "POST")
            XCTAssertNil(endpoint.body)
            XCTAssertNil(endpoint.headers)
            XCTAssertEqual(endpoint.formData?.count, 1)
        }
    }

    func testFetchPhotoUrlFromKartaviewPercentEncodesTheToken() {
        let e = APIEndpoint.fetchPhotoUrlFromKartaview("42", "a b&c")
        XCTAssertEqual(e.method, "GET")
        XCTAssertTrue(e.path.hasPrefix("/photo/42?access_token="))
        XCTAssertFalse(e.path.contains(" "), "spaces must be percent-encoded: \(e.path)")
        XCTAssertNil(e.formData)
    }

    func testSubmitNoteBuildsJSONBody() {
        let e = APIEndpoint.submitNote("hello", "tok", 17.5, 78.25, "222")
        XCTAssertEqual(e.path, "/notes.json")
        XCTAssertEqual(e.method, "POST")
        XCTAssertEqual(e.headers?["X-Workspace"], "222")
        XCTAssertEqual(e.headers?["Content-Type"], "application/json")
        let json = bodyJSON(e)
        XCTAssertEqual(json?["text"] as? String, "hello")
        XCTAssertEqual(json?["lat"] as? Double, 17.5)
        XCTAssertEqual(json?["lon"] as? Double, 78.25)
    }

    func testRoundedTo7Digits() {
        XCTAssertEqual(17.438512345.roundedTo7Digits(), 17.4385123)
        XCTAssertEqual((-122.123456789).roundedTo7Digits(), -122.1234568)
        XCTAssertEqual(5.0.roundedTo7Digits(), 5.0)
    }
}

final class JWTDecoderTests: XCTestCase {

    /// The UI tests' own LoginSuccess.json access token (sub "uitest-user-0001").
    private var fixtureToken: String {
        ((MockHTTP.fixtureJSON("LoginSuccess") as? [String: Any])?["access_token"] as? String) ?? ""
    }

    func testDecodesClaimsFromFixtureToken() {
        let claims = JWTDecoder.claims(fromToken: fixtureToken)
        XCTAssertEqual(claims?["sub"] as? String, "uitest-user-0001")
        XCTAssertEqual(claims?["email"] as? String, "test@email.com")
        XCTAssertEqual(claims?["preferred_username"] as? String, "test@email.com")
    }

    func testSubjectConvenience() {
        XCTAssertEqual(JWTDecoder.subject(fromToken: fixtureToken), "uitest-user-0001")
    }

    func testRejectsTokensThatAreNotThreeSegments() {
        XCTAssertNil(JWTDecoder.claims(fromToken: ""))
        XCTAssertNil(JWTDecoder.claims(fromToken: "only.two"))
        XCTAssertNil(JWTDecoder.claims(fromToken: "a.b.c.d"))
        XCTAssertNil(JWTDecoder.subject(fromToken: "nope"))
    }

    func testRejectsPayloadThatIsNotBase64() {
        XCTAssertNil(JWTDecoder.claims(fromToken: "h.!!!!.s"))
    }

    func testRejectsPayloadThatIsNotAJSONObject() {
        // base64url("[1,2]") - valid base64, valid JSON, but an array rather than an object.
        let payload = Data("[1,2]".utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        XCTAssertNil(JWTDecoder.claims(fromToken: "h.\(payload).s"))
        // base64url("not json")
        let junk = Data("not json".utf8).base64EncodedString().replacingOccurrences(of: "=", with: "")
        XCTAssertNil(JWTDecoder.claims(fromToken: "h.\(junk).s"))
    }

    func testHandlesBase64URLCharactersAndMissingPadding() {
        // A payload whose standard-base64 form contains '+' and '/' is only decodable if
        // the URL-safe '-' and '_' are mapped back and padding restored.
        let json = #"{"sub":"user-?>>","n":1}"#
        let standard = Data(json.utf8).base64EncodedString()
        let urlSafe = standard.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        XCTAssertEqual(JWTDecoder.subject(fromToken: "h.\(urlSafe).s"), "user-?>>")
    }

    func testTokenWithoutSubjectReturnsNilSubject() {
        let payload = Data(#"{"email":"x"}"#.utf8).base64EncodedString().replacingOccurrences(of: "=", with: "")
        XCTAssertNil(JWTDecoder.subject(fromToken: "h.\(payload).s"))
        XCTAssertNotNil(JWTDecoder.claims(fromToken: "h.\(payload).s"))
    }
}

final class ResponseManagerTests: XCTestCase {

    private struct Item: Decodable, Equatable { let id: Int; let name: String }

    func testDecodesValidJSON() {
        let exp = expectation(description: "decode")
        ResponseManager().decode(Data(#"{"id":1,"name":"a"}"#.utf8), type: Item.self) { result in
            XCTAssertEqual(try? result.get(), Item(id: 1, name: "a"))
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testReportsDecodingFailedForMismatchedJSON() {
        let exp = expectation(description: "decode")
        ResponseManager().decode(Data(#"{"id":"x"}"#.utf8), type: Item.self) { result in
            guard case .failure(let error) = result else { return XCTFail("Expected failure") }
            XCTAssertEqual(error as? NetworkError, .decodingFailed)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}

