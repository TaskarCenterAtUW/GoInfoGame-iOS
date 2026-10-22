//
//  NetworkManagerTests.swift
//  GoInfoGameTests
//
//  NetworkManager / APIManager / NetworkMonitor (the protocol-based layer ForceUpdateManager
//  uses) and ForceUpdateManager itself. NetworkManager takes its collaborators by injection,
//  so most branches are driven with fakes; APIManager and the end-to-end force-update check
//  go through MockHTTP and the UI tests' ForceUpdate*.json fixtures.
//

import XCTest
import Combine
@testable import GoInfoGame

// MARK: - Fakes

private struct FakeRequest: APIRequest {
    var urlRequest: URLRequest?
    init(_ string: String? = "https://example.test/data.json") {
        urlRequest = string.flatMap { URL(string: $0) }.map { URLRequest(url: $0) }
    }
}

private struct FakeMonitor: NetworkMonitorHandler { var status: Bool }

/// Hands out queued results, one per call (the last one repeats).
private final class FakeAPIHandler: APIHandler {
    var futureResults: [Result<Data, Error>]
    var asyncResults: [Result<(Data, URLResponse), Error>]
    private(set) var calls = 0

    init(future: [Result<Data, Error>] = [], async asyncResults: [Result<(Data, URLResponse), Error>] = []) {
        self.futureResults = future
        self.asyncResults = asyncResults
    }

    func fetchData(from request: APIRequest) -> Future<Data, Error> {
        let result = futureResults[min(calls, futureResults.count - 1)]
        calls += 1
        return Future { promise in promise(result) }
    }

    func fetchData(from request: APIRequest) async throws -> (Data, URLResponse) {
        let result = asyncResults[min(calls, asyncResults.count - 1)]
        calls += 1
        return try result.get()
    }
}

private func http(_ status: Int, url: String = "https://example.test/data.json", body: String) -> Result<(Data, URLResponse), Error> {
    let response = HTTPURLResponse(url: URL(string: url)!, statusCode: status, httpVersion: nil, headerFields: nil)!
    return .success((Data(body.utf8), response))
}

private struct Payload: Decodable, Equatable { let code: Int?; let name: String }

// MARK: - NetworkManager (Combine Future API)

final class NetworkManagerFutureTests: AppTestCase {

    private func fetch(_ manager: NetworkManager, request: FakeRequest = FakeRequest(), timeout: TimeInterval = 5) -> Result<Payload, Error>? {
        let exp = expectation(description: "future")
        var outcome: Result<Payload, Error>?
        let future: Future<Payload, Error> = manager.fetchData(request: request)
        future.sink(receiveCompletion: { completion in
            if case .failure(let error) = completion { outcome = .failure(error); exp.fulfill() }
        }, receiveValue: { value in
            outcome = .success(value); exp.fulfill()
        }).store(in: &cancellables)
        wait(for: [exp], timeout: timeout)
        return outcome
    }

    func testFailsImmediatelyWithoutANetwork() {
        let manager = NetworkManager(apiHandler: FakeAPIHandler(future: [.success(Data())]), networkMonitor: FakeMonitor(status: false))
        guard case .failure(let error)? = fetch(manager) else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? NetworkError, .noNetwork)
    }

    func testDecodesASuccessfulResponse() {
        let handler = FakeAPIHandler(future: [.success(Data(#"{"code":200,"name":"ok"}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .success(let value)? = fetch(manager) else { return XCTFail("expected success") }
        XCTAssertEqual(value, Payload(code: 200, name: "ok"))
    }

    func testAResponseWithoutACodeFieldIsRejected() {
        let handler = FakeAPIHandler(future: [.success(Data(#"{"name":"no code"}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .failure(let error)? = fetch(manager) else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? NetworkError, .decodingFailed)
    }

    func testTransportErrorsFromTheHandlerPropagate() {
        let handler = FakeAPIHandler(future: [.failure(URLError(.badServerResponse))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .failure(let error)? = fetch(manager) else { return XCTFail("expected failure") }
        XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
    }

    func testDecodingErrorsFromTheResponseHandlerPropagate() {
        let handler = FakeAPIHandler(future: [.success(Data(#"{"code":200,"name":123}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .failure(let error)? = fetch(manager) else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? NetworkError, .decodingFailed)
    }

    func testA401CodeTriggersATokenRefreshAndAReFetch() {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .json(#"{"access_token":"a.b.c","expires_in":60,"refresh_expires_in":120,"refresh_token":"r.r.r"}"#))
        let handler = FakeAPIHandler(future: [.success(Data(#"{"code":401,"name":"expired"}"#.utf8)),
                                              .success(Data(#"{"code":200,"name":"fresh"}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .success(let value)? = fetch(manager) else { return XCTFail("expected success after refresh") }
        XCTAssertEqual(value.name, "fresh")
        XCTAssertEqual(handler.calls, 2)
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), "a.b.c")
    }

    func testAStringCodeOf401IsTreatedTheSameAsANumber() {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .json(#"{"access_token":"a.b.c","expires_in":60,"refresh_expires_in":120,"refresh_token":"r.r.r"}"#))
        let handler = FakeAPIHandler(future: [.success(Data(#"{"code":"401","name":"expired"}"#.utf8)),
                                              .success(Data(#"{"code":200,"name":"fresh"}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .success(let value)? = fetch(manager) else { return XCTFail("expected success after refresh") }
        XCTAssertEqual(value.name, "fresh")
    }

    func testA401CodeOnAnAuthenticateURLIsNotRefreshed() {
        let handler = FakeAPIHandler(future: [.success(Data(#"{"code":401,"name":"bad creds"}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .success(let value)? = fetch(manager, request: FakeRequest("https://example.test/api/v1/authenticate")) else {
            return XCTFail("expected the 401 body to be decoded as-is")
        }
        XCTAssertEqual(value.code, 401)
        XCTAssertTrue(MockHTTP.requests(pathRegex: "refresh-token$").isEmpty)
    }

    func testAFailedRefreshClearsTheSessionAndFails() {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .status(401))
        let handler = FakeAPIHandler(future: [.success(Data(#"{"code":401,"name":"expired"}"#.utf8))])
        let manager = NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: true))
        guard case .failure(let error)? = fetch(manager) else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? NetworkError, .badNetwrok)
        XCTAssertNil(KeychainManager.load(key: "accessToken"))
    }
}

// MARK: - NetworkManager (async API)

final class NetworkManagerAsyncTests: AppTestCase {

    private func manager(_ handler: FakeAPIHandler, online: Bool = true) -> NetworkManager {
        NetworkManager(apiHandler: handler, networkMonitor: FakeMonitor(status: online))
    }

    func testThrowsWithoutANetwork() async {
        do {
            let _: Payload = try await manager(FakeAPIHandler(async: [http(200, body: "{}")]), online: false).fetchData(request: FakeRequest())
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .noNetwork)
        }
    }

    func testDecodesASuccessfulResponse() async throws {
        let handler = FakeAPIHandler(async: [http(200, body: #"{"name":"ok"}"#)])
        let value: Payload = try await manager(handler).fetchData(request: FakeRequest())
        XCTAssertEqual(value.name, "ok")
    }

    func testMalformedBodiesSurfaceTheDecodingError() async {
        let handler = FakeAPIHandler(async: [http(200, body: #"{"name":5}"#)])
        do {
            let _: Payload = try await manager(handler).fetchData(request: FakeRequest())
            XCTFail("expected an error")
        } catch {
            XCTAssertTrue(error is DecodingError, "got \(error)")
        }
    }

    func testTransportErrorsPropagate() async {
        let handler = FakeAPIHandler(async: [.failure(URLError(.cannotConnectToHost))])
        do {
            let _: Payload = try await manager(handler).fetchData(request: FakeRequest())
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cannotConnectToHost)
        }
    }

    func testA401IsRefreshedAndRetried() async throws {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .json(#"{"access_token":"x.y.z","expires_in":60,"refresh_expires_in":120,"refresh_token":"r.r.r"}"#))
        let handler = FakeAPIHandler(async: [http(401, body: "{}"), http(200, body: #"{"name":"after refresh"}"#)])
        let value: Payload = try await manager(handler).fetchData(request: FakeRequest())
        XCTAssertEqual(value.name, "after refresh")
        XCTAssertEqual(handler.calls, 2)
        XCTAssertEqual(KeychainManager.load(key: "accessToken"), "x.y.z")
    }

    func testAFailedRefreshThrowsUnauthorized() async {
        signIn()
        MockHTTP.stub("POST", pathRegex: "refresh-token$", reply: .status(401))
        let handler = FakeAPIHandler(async: [http(401, body: "{}")])
        do {
            let _: Payload = try await manager(handler).fetchData(request: FakeRequest())
            XCTFail("expected an error")
        } catch {
            guard case APIError.unauthorized = error else { return XCTFail("Expected .unauthorized, got \(error)") }
        }
    }

    func testA401FromARefreshTokenURLIsNotRefreshedAgain() async {
        let handler = FakeAPIHandler(async: [http(401, url: "https://example.test/api/v1/refresh-token", body: "{}")])
        do {
            let _: Payload = try await manager(handler).fetchData(request: FakeRequest("https://example.test/api/v1/refresh-token"))
            XCTFail("expected a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError, "got \(error)")
            XCTAssertEqual(handler.calls, 1)
        }
    }
}

// MARK: - APIManager (the real URLSession-backed handler) & request defaults

final class APIManagerTests: AppTestCase {

    private func request(_ string: String = "https://example.test/ping") -> FakeRequest { FakeRequest(string) }

    func testFutureReturnsTheBodyOfA2xxResponse() {
        MockHTTP.stubAll(.json(#"{"ok":true}"#))
        let exp = expectation(description: "future")
        var received: Data?
        let api = APIManager()
        api.fetchData(from: request())
            .sink(receiveCompletion: { _ in }, receiveValue: { received = $0; exp.fulfill() })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 5)
        withExtendedLifetime(api) {}
        XCTAssertEqual(received.flatMap { String(data: $0, encoding: .utf8) }, #"{"ok":true}"#)
    }

    func testFutureTurnsANon2xxStatusIntoBadNetwork() {
        MockHTTP.stubAll(.statusWithBody(500, "boom"))
        let exp = expectation(description: "future")
        var failure: Error?
        let api = APIManager()
        api.fetchData(from: request())
            .sink(receiveCompletion: { if case .failure(let e) = $0 { failure = e; exp.fulfill() } }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 5)
        withExtendedLifetime(api) {}
        XCTAssertEqual(failure as? NetworkError, .badNetwrok)
    }

    func testFutureRejectsARequestWithoutAURL() {
        let exp = expectation(description: "future")
        var failure: Error?
        let api = APIManager()
        api.fetchData(from: FakeRequest(nil))
            .sink(receiveCompletion: { if case .failure(let e) = $0 { failure = e; exp.fulfill() } }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 5)
        withExtendedLifetime(api) {}
        XCTAssertEqual(failure as? NetworkError, .invalidURLRequest)
    }

    func testAsyncReturnsDataAndResponseEvenForErrorStatuses() async throws {
        MockHTTP.stubAll(.statusWithBody(404, "missing"))
        let (data, response) = try await APIManager().fetchData(from: request())
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "missing")
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 404)
    }

    func testAsyncRejectsARequestWithoutAURL() async {
        do {
            _ = try await APIManager().fetchData(from: FakeRequest(nil))
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .invalidURLRequest)
        }
    }

    func testDefaultValuesAddJSONContentTypeAndBearerTokenWhenSignedIn() {
        signIn()
        let url = URL(string: "https://example.test/x")!
        let stamped = FakeRequest().setDefaultValues(urlRequest: URLRequest(url: url))
        XCTAssertEqual(stamped.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(stamped.value(forHTTPHeaderField: "Authorization"), "Bearer \(fixtureAccessToken)")
    }

    func testDefaultValuesOmitTheTokenWhenSignedOut() {
        let stamped = FakeRequest().setDefaultValues(urlRequest: URLRequest(url: URL(string: "https://example.test/x")!))
        XCTAssertNil(stamped.value(forHTTPHeaderField: "Authorization"))
    }

    func testNetworkMonitorStartsOptimisticallyOnline() {
        XCTAssertTrue(NetworkMonitor().status)
    }
}

// MARK: - ForceUpdateManager

private final class FakeNetworkHandler: NetworkHandler {
    var body: Data
    var error: Error?
    init(body: Data = Data(), error: Error? = nil) { self.body = body; self.error = error }

    func fetchData<T: Decodable>(request: APIRequest) -> Future<T, Error> {
        Future { [self] promise in
            if let error { promise(.failure(error)); return }
            promise(Result { try JSONDecoder().decode(T.self, from: body) })
        }
    }
    func fetchData<T: Decodable>(request: APIRequest) async throws -> T {
        if let error { throw error }
        return try JSONDecoder().decode(T.self, from: body)
    }
}

final class ForceUpdateManagerTests: AppTestCase {

    private var runningVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0" }

    private func manager(fixture: String) -> ForceUpdateManager {
        ForceUpdateManager(networkHandler: FakeNetworkHandler(body: MockHTTP.fixture(fixture)))
    }

    private func checkOutcome(_ manager: ForceUpdateManager) async throws -> AppUpdateInfo {
        try await manager.checkForceUpdate()
        // validateForceUpdate publishes on the main queue.
        await waitMain()
        return manager.appUpdateInfo
    }

    private func waitMain() async {
        await withCheckedContinuation { c in DispatchQueue.main.async { c.resume() } }
    }

    func testStartsWithNoUpdate() {
        XCTAssertEqual(ForceUpdateManager(networkHandler: FakeNetworkHandler()).appUpdateInfo, .noUpdate)
    }

    func testNoUpdateFixtureRequiresNothingInEveryEnvironment() async throws {
        for env in APIEnvironment.allCases {
            APIConfiguration.shared.environment = env
            let outcome = try await checkOutcome(manager(fixture: "ForceUpdateNone"))
            XCTAssertEqual(outcome, .noUpdate, "env \(env)")
        }
    }

    func testSoftUpdateFixtureOffersAnOptionalUpdateInEveryEnvironment() async throws {
        for env in APIEnvironment.allCases {
            APIConfiguration.shared.environment = env
            let outcome = try await checkOutcome(manager(fixture: "ForceUpdateSoft"))
            XCTAssertEqual(outcome, .softUpdate, "env \(env)")
        }
    }

    func testForceUpdateFixtureBlocksInEveryEnvironment() async throws {
        for env in APIEnvironment.allCases {
            APIConfiguration.shared.environment = env
            let outcome = try await checkOutcome(manager(fixture: "ForceUpdateForce"))
            XCTAssertEqual(outcome, .forceUpdate, "env \(env)")
        }
    }

    func testTheCheckingEnvironmentSelectsWhichThresholdsApply() async throws {
        let json = """
        {"ios":{"prod":{"min_required_version":"0.0.1","latest_version":"0.0.1"},
                "dev":{"min_required_version":"999.0.0","latest_version":"999.0.0"}}}
        """
        let m = ForceUpdateManager(networkHandler: FakeNetworkHandler(body: Data(json.utf8)))
        APIConfiguration.shared.environment = .production
        let production = try await checkOutcome(m)
        XCTAssertEqual(production, .noUpdate)
        APIConfiguration.shared.environment = .development
        let development = try await checkOutcome(m)
        XCTAssertEqual(development, .forceUpdate)
    }

    func testAnEnvironmentMissingFromTheResponseNeverForcesAnUpdate() async throws {
        let json = #"{"ios":{"prod":{"min_required_version":"999.0.0","latest_version":"999.0.0"}}}"#
        APIConfiguration.shared.environment = .staging
        let outcome = try await checkOutcome(ForceUpdateManager(networkHandler: FakeNetworkHandler(body: Data(json.utf8))))
        XCTAssertEqual(outcome, .noUpdate)
    }

    func testVersionsAreComparedNumericallyNotLexically() async throws {
        // "1.10" > "1.9" numerically; a lexical compare would get this backwards.
        let json = """
        {"ios":{"prod":{"min_required_version":"\(runningVersion)","latest_version":"\(runningVersion).1"}}}
        """
        APIConfiguration.shared.environment = .production
        let atMinimum = try await checkOutcome(ForceUpdateManager(networkHandler: FakeNetworkHandler(body: Data(json.utf8))))
        XCTAssertEqual(atMinimum, .softUpdate, "running == min is allowed, running < latest is a soft update")

        let aboveMinimum = """
        {"ios":{"prod":{"min_required_version":"\(runningVersion).1","latest_version":"\(runningVersion).1"}}}
        """
        let belowMinimum = try await checkOutcome(ForceUpdateManager(networkHandler: FakeNetworkHandler(body: Data(aboveMinimum.utf8))))
        XCTAssertEqual(belowMinimum, .forceUpdate)

        let numeric = #"{"ios":{"prod":{"min_required_version":"0.0.9","latest_version":"0.0.10"}}}"#
        let m = ForceUpdateManager(networkHandler: FakeNetworkHandler(body: Data(numeric.utf8)))
        let fine = try await checkOutcome(m)
        XCTAssertEqual(fine, .noUpdate, "this build is newer than both 0.0.9 and 0.0.10")
    }

    func testCompletionIsAnnouncedAfterEveryValidation() async throws {
        let m = manager(fixture: "ForceUpdateSoft")
        APIConfiguration.shared.environment = .production
        var completions = 0
        m.updateCheckCompleted.sink { completions += 1 }.store(in: &cancellables)
        try await m.checkForceUpdate()
        await waitMain()
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(m.validateForceUpdate(), .softUpdate)
        await waitMain()
        XCTAssertEqual(completions, 2)
    }

    func testNetworkFailuresAreRethrownAndLeaveTheStateUntouched() async {
        let m = ForceUpdateManager(networkHandler: FakeNetworkHandler(error: URLError(.notConnectedToInternet)))
        do {
            try await m.checkForceUpdate()
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertEqual(m.appUpdateInfo, .noUpdate)
        XCTAssertNil(m.forceUpdateInfo)
    }

    func testUndecodableResponsesAreRethrown() async {
        let m = ForceUpdateManager(networkHandler: FakeNetworkHandler(body: Data(#"{"android":{}}"#.utf8)))
        do {
            try await m.checkForceUpdate()
            XCTFail("expected a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTheEnvironmentIsUnknownUnderTest() async throws {
        // StoreKit's AppTransaction would raise a sign-in sheet inside a test run.
        let m = manager(fixture: "ForceUpdateNone")
        try await m.checkForceUpdate()
        XCTAssertEqual(m.appEnvironment, .unknown)
        let direct = await m.getAppEnvironment()
        XCTAssertEqual(direct, .unknown)
    }

    func testForceUpdateRequestPointsAtTheConfiguredURL() throws {
        let request = try XCTUnwrap(ForceUpdateRequest().urlRequest)
        XCTAssertEqual(request.url?.scheme, "https")
        XCTAssertEqual(request.url?.absoluteString, Bundle.main.infoDictionary?["APP_FORCE_UPDATE_URL"] as? String)
    }

    func testResponseModelDecodesArbitraryPlatformKeys() throws {
        let json = #"{"ios":{"qa":{"min_required_version":"1","latest_version":"2"},"prod":{"min_required_version":"3","latest_version":"4"}}}"#
        let decoded = try JSONDecoder().decode(ForceUpdateResponse.self, from: Data(json.utf8))
        XCTAssertEqual(Set(decoded.ios.platformInfo.keys), ["qa", "prod"])
        XCTAssertEqual(decoded.ios.platformInfo["qa"]?.latestVersion, "2")
        XCTAssertEqual(decoded.ios.platformInfo["prod"]?.minRequiredVersion, "3")
    }

    /// The real wiring: NetworkManager -> APIManager -> URLSession (stubbed) -> decode -> validate.
    func testEndToEndAgainstTheSharedFixtureThroughTheRealNetworkStack() async throws {
        MockHTTP.stub("GET", urlContains: "app-force-update", reply: .fixture("ForceUpdateForce"))
        MockHTTP.stubAll(.fixture("ForceUpdateForce"))
        APIConfiguration.shared.environment = .production
        let m = ForceUpdateManager(networkHandler: NetworkManager(networkMonitor: FakeMonitor(status: true)))
        let outcome = try await checkOutcome(m)
        XCTAssertEqual(outcome, .forceUpdate)
        XCTAssertEqual(MockHTTP.requests.first?.url.absoluteString, Bundle.main.infoDictionary?["APP_FORCE_UPDATE_URL"] as? String)
    }
}
