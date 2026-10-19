//
//  MockHTTP.swift
//  GoInfoGameTests
//
//  A tiny URLProtocol-based HTTP stub for hosted unit tests. Unit tests are injected into
//  the app process (TEST_HOST), so registering a URLProtocol here intercepts the app's own
//  URLSession.shared traffic (ApiManager, APIManager, TokenRefresher ...) directly - no
//  third-party stubbing library needed in the test bundle.
//
//  Responses are served from the SAME JSON fixtures the UI tests use
//  (GoInfoGame/DebugSupport/MockResponses/*.json, bundled into the app) via `fixture(_:)`.
//

import Foundation
import XCTest

final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { MockHTTP.isInstalled }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = MockHTTP.readBody(of: request)
        let recorded = MockHTTP.Recorded(request: request, body: body)
        let reply = MockHTTP.reply(for: recorded)

        let respond = { [weak self] in
            guard let self else { return }
            switch reply.kind {
            case .failure(let error):
                self.client?.urlProtocol(self, didFailWithError: error)
            case .response(let status, let data, let headers):
                let http = HTTPURLResponse(url: self.request.url!, statusCode: status,
                                           httpVersion: "HTTP/1.1", headerFields: headers)!
                self.client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
                if !data.isEmpty { self.client?.urlProtocol(self, didLoad: data) }
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        if reply.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + reply.delay, execute: respond)
        } else {
            respond()
        }
    }

    override func stopLoading() {}
}

enum MockHTTP {

    struct Recorded {
        let request: URLRequest
        let body: Data?
        var url: URL { request.url! }
        /// The URL path as sent - unlike `URL.path`, this keeps a trailing slash ("/sequence/").
        var path: String { URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.path ?? request.url!.path }
        var method: String { request.httpMethod ?? "GET" }
        var bodyString: String { body.flatMap { String(data: $0, encoding: .utf8) } ?? "" }
        func header(_ name: String) -> String? { request.value(forHTTPHeaderField: name) }
    }

    struct Reply {
        enum Kind {
            case response(status: Int, data: Data, headers: [String: String])
            case failure(Error)
        }
        let kind: Kind
        var delay: TimeInterval = 0

        static func json(_ data: Data, status: Int = 200) -> Reply {
            Reply(kind: .response(status: status, data: data, headers: ["Content-Type": "application/json"]))
        }
        static func json(_ string: String, status: Int = 200) -> Reply { .json(Data(string.utf8), status: status) }
        /// Serves one of the shared UI-test fixtures (GoInfoGame/DebugSupport/MockResponses).
        static func fixture(_ name: String, status: Int = 200) -> Reply { .json(MockHTTP.fixture(name), status: status) }
        static func text(_ string: String, status: Int = 200, contentType: String = "text/xml") -> Reply {
            Reply(kind: .response(status: status, data: Data(string.utf8), headers: ["Content-Type": contentType]))
        }
        static func status(_ code: Int) -> Reply {
            Reply(kind: .response(status: code, data: Data(), headers: [:]))
        }
        static func statusWithBody(_ code: Int, _ body: String) -> Reply {
            Reply(kind: .response(status: code, data: Data(body.utf8), headers: [:]))
        }
        /// URLError.notConnectedToInternet (-1009) - what the app maps to `.noNetworkConnection`.
        static var offline: Reply { .failure(URLError(.notConnectedToInternet)) }
        static func failure(_ error: Error) -> Reply { Reply(kind: .failure(error)) }

        func delayed(_ seconds: TimeInterval) -> Reply { var copy = self; copy.delay = seconds; return copy }
    }

    private struct Stub {
        let id = UUID()
        let method: String?
        let matcher: (Recorded) -> Bool
        let handler: (Recorded) -> Reply
    }

    private static let lock = NSLock()
    private static var stubs: [Stub] = []
    private static var log: [Recorded] = []
    private(set) static var isInstalled = false

    // MARK: Lifecycle

    static func install() {
        lock.lock(); defer { lock.unlock() }
        if !isInstalled {
            URLProtocol.registerClass(MockURLProtocol.self)
            isInstalled = true
        }
        stubs.removeAll()
        log.removeAll()
    }

    static func uninstall() {
        lock.lock(); defer { lock.unlock() }
        if isInstalled {
            URLProtocol.unregisterClass(MockURLProtocol.self)
            isInstalled = false
        }
        stubs.removeAll()
    }

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        stubs.removeAll()
        log.removeAll()
    }

    // MARK: Registering stubs (newest registration wins, like OHHTTPStubs)

    /// Matches on method (optional) and an exact URL path.
    static func stub(_ method: String? = nil, path: String, _ handler: @escaping (Recorded) -> Reply) {
        add(Stub(method: method, matcher: { $0.path == path }, handler: handler))
    }

    static func stub(_ method: String? = nil, path: String, reply: Reply) {
        stub(method, path: path) { _ in reply }
    }

    /// Matches on method (optional) and a regular expression applied to the URL path.
    static func stub(_ method: String? = nil, pathRegex: String, _ handler: @escaping (Recorded) -> Reply) {
        add(Stub(method: method, matcher: { $0.path.range(of: pathRegex, options: .regularExpression) != nil }, handler: handler))
    }

    static func stub(_ method: String? = nil, pathRegex: String, reply: Reply) {
        stub(method, pathRegex: pathRegex) { _ in reply }
    }

    /// Matches on method (optional) and the full absolute URL string.
    static func stub(_ method: String? = nil, urlContains fragment: String, reply: Reply) {
        add(Stub(method: method, matcher: { $0.url.absoluteString.contains(fragment) }, handler: { _ in reply }))
    }

    /// Answers EVERY request with `reply` - useful for "the network is down" tests.
    static func stubAll(_ reply: Reply) {
        add(Stub(method: nil, matcher: { _ in true }, handler: { _ in reply }))
    }

    private static func add(_ stub: Stub) {
        lock.lock(); defer { lock.unlock() }
        stubs.insert(stub, at: 0)
    }

    // MARK: Inspecting traffic

    static var requests: [Recorded] {
        lock.lock(); defer { lock.unlock() }
        return log
    }

    static func requests(path: String, method: String? = nil) -> [Recorded] {
        requests.filter { $0.path == path && (method == nil || $0.method == method) }
    }

    static func requests(pathRegex: String, method: String? = nil) -> [Recorded] {
        requests.filter { $0.path.range(of: pathRegex, options: .regularExpression) != nil && (method == nil || $0.method == method) }
    }

    // MARK: Internals

    fileprivate static func reply(for recorded: Recorded) -> Reply {
        lock.lock()
        log.append(recorded)
        let match = stubs.first { stub in
            (stub.method == nil || stub.method == recorded.method) && stub.matcher(recorded)
        }
        lock.unlock()
        guard let match else {
            return .failure(NSError(domain: "MockHTTP", code: NSURLErrorResourceUnavailable,
                                    userInfo: [NSLocalizedDescriptionKey: "Unstubbed request: \(recorded.method) \(recorded.url.absoluteString)"]))
        }
        return match.handler(recorded)
    }

    fileprivate static func readBody(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    // MARK: Fixtures

    /// Loads a JSON fixture. The UI tests' shared fixtures (GoInfoGame/DebugSupport/MockResponses)
    /// ship inside the host app bundle; fixtures only unit tests need (e.g. Kartaview uploads) live
    /// in this test bundle (GoInfoGameTests/Fixtures) and are looked up as a fallback.
    static func fixture(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Data {
        for bundle in [Bundle.main, Bundle(for: FixtureBundleAnchor.self)] {
            if let url = bundle.url(forResource: name, withExtension: "json"), let data = try? Data(contentsOf: url) {
                return data
            }
        }
        XCTFail("Missing fixture \(name).json in the app or test bundle", file: file, line: line)
        return Data()
    }

    static func fixtureJSON(_ name: String) -> Any {
        (try? JSONSerialization.jsonObject(with: fixture(name))) ?? [:]
    }
}

private final class FixtureBundleAnchor {}
