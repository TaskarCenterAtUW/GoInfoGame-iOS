//
//  OSMConnectionTests.swift
//  osmapiTests
//
//  The OSM API client against an in-process stub server. These tests used to call live
//  OSM/POSM servers (and crashed on a nil access token); they now answer every request from a
//  URLProtocol, so they are fast, deterministic and need no network or credentials.
//

import XCTest
import CoreLocation
@testable import osmapi

// MARK: - Stub server

final class OSMStubProtocol: URLProtocol {

    struct Recorded {
        let request: URLRequest
        let body: String
        var path: String { request.url?.path ?? "" }
        var method: String { request.httpMethod ?? "GET" }
    }

    struct Reply {
        var status = 200
        var body = ""
        var failure: Error?
        static func json(_ body: String, status: Int = 200) -> Reply { Reply(status: status, body: body) }
        static func status(_ code: Int) -> Reply { Reply(status: code) }
        static let offline = Reply(failure: URLError(.notConnectedToInternet))
    }

    private static let lock = NSLock()
    private static var routes: [(method: String, path: String, reply: Reply)] = []
    private static var log: [Recorded] = []

    static func reset() { lock.lock(); routes = []; log = []; lock.unlock() }
    static func stub(_ method: String, _ path: String, _ reply: Reply) {
        lock.lock(); routes.insert((method, path, reply), at: 0); lock.unlock()
    }
    static var requests: [Recorded] { lock.lock(); defer { lock.unlock() }; return log }
    static func last(_ method: String, _ path: String) -> Recorded? { requests.last { $0.method == method && $0.path == path } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var body = ""
        if let data = request.httpBody ?? request.httpBodyStream.map(Self.read) { body = String(data: data, encoding: .utf8) ?? "" }
        let recorded = Recorded(request: request, body: body)
        Self.lock.lock()
        Self.log.append(recorded)
        let reply = Self.routes.first { $0.method == recorded.method && $0.path == recorded.path }?.reply
            ?? Reply(failure: URLError(.resourceUnavailable))
        Self.lock.unlock()

        if let failure = reply.failure {
            client?.urlProtocol(self, didFailWithError: failure)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if !reply.body.isEmpty { client?.urlProtocol(self, didLoad: Data(reply.body.utf8)) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream) -> Data {
        stream.open(); defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 2048)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

// MARK: - Canned bodies

enum OSMBodies {
    private static let envelope = """
    "version": "0.6", "generator": "stub", "copyright": "OpenStreetMap and contributors",
    "attribution": "http://www.openstreetmap.org/copyright", "license": "http://opendatacommons.org/licenses/odbl/1-0/"
    """

    static let node = """
    { \(envelope), "elements": [ { "type": "node", "id": 31419, "lat": 17.4385, "lon": 78.361, "timestamp": "2024-03-01T10:00:00Z",
      "version": 4, "changeset": 100, "user": "mapper", "uid": 7, "tags": { "kerb": "lowered" } } ] }
    """

    static let way = """
    { \(envelope), "elements": [ { "type": "way", "id": 4305301937, "timestamp": "2024-03-01T10:00:00Z", "version": 2, "changeset": 101,
      "user": "mapper", "uid": 7, "nodes": [1, 2, 3], "tags": { "footway": "sidewalk", "highway": "footway" } } ] }
    """

    static let changesets = """
    { \(envelope), "changesets": [ { "id": 146513063, "created_at": "2024-01-21T13:33:09Z", "open": true, "comments_count": 0,
      "changes_count": 1, "min_lat": 51.1, "min_lon": 7.4, "max_lat": 51.2, "max_lon": 7.5, "uid": 12999340, "user": "Otter Trey" } ] }
    """

    static let user = """
    { \(envelope), "user": { "id": 20018, "display_name": "Tester", "account_created": "2020-01-01T00:00:00Z", "description": "",
      "contributor_terms": { "agreed": true }, "roles": [], "changesets": { "count": 3 }, "traces": { "count": 0 },
      "blocks": { "received": { "count": 0, "active": 0 } }, "img": { "href": "https://example.com/me.png" } } }
    """
}

// MARK: - Tests

final class OSMConnectionTests: XCTestCase {

    private let base = "https://osm.stub.test/api/0.6/"
    private var connection: OSMConnection!

    override func setUp() {
        super.setUp()
        OSMStubProtocol.reset()
        URLProtocol.registerClass(OSMStubProtocol.self)
        connection = OSMConnection(config: OSMConfig(baseUrl: base), currentChangesetId: nil)
        connection.accessToken = "stub-token"
    }

    override func tearDown() {
        URLProtocol.unregisterClass(OSMStubProtocol.self)
        OSMStubProtocol.reset()
        super.tearDown()
    }

    /// Runs `body` with a completion that fulfils an expectation, and returns its result.
    private func run<T>(_ description: String, _ body: (@escaping (Result<T, Error>) -> Void) -> Void) -> Result<T, Error> {
        let done = expectation(description: description)
        var outcome: Result<T, Error>?
        body { outcome = $0; done.fulfill() }
        wait(for: [done], timeout: 5)
        return outcome ?? .failure(URLError(.timedOut))
    }

    // MARK: Configuration

    func testTheConfigurationsPointAtTheApi() {
        XCTAssertEqual(OSMConfig.productionOSM.baseUrl, "https://api.openstreetmap.org/api/0.6/")
        XCTAssertTrue(OSMConfig.testPOSM.baseUrl.hasSuffix("/api/0.6/"))
    }

    func testAConnectionKeepsItsChangesetAndPicksCredentialsByServer() {
        let existing = OSMConnection(config: OSMConfig(baseUrl: base), currentChangesetId: 12)
        XCTAssertEqual(existing.currentChangesetId, 12)
        XCTAssertEqual(connection.authorizationValue, "Bearer stub-token")
        // The credential set depends on whether the server is a workspaces server.
        _ = connection.userCreds
        _ = OSMConnection(config: OSMConfig(baseUrl: "https://osm.workspaces.test/api/0.6/")).userCreds
    }

    // MARK: Reading

    func testANodeIsFetchedWithTheBearerToken() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/node/31419.json", .json(OSMBodies.node))
        let node = try run("node") { connection.getNode(id: "31419", $0) }.get().elements.first
        XCTAssertEqual(node?.id, 31419)
        XCTAssertEqual(node?.tags["kerb"], "lowered")
        XCTAssertEqual(node?.version, 4)
        XCTAssertEqual(OSMStubProtocol.last("GET", "/api/0.6/node/31419.json")?.request.value(forHTTPHeaderField: "Authorization"), "Bearer stub-token")
    }

    func testAWayIsFetched() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/way/4305301937.json", .json(OSMBodies.way))
        let way = try run("way") { connection.getWay(id: "4305301937", $0) }.get().elements.first
        XCTAssertEqual(way?.nodes, [1, 2, 3])
        XCTAssertEqual(way?.tags["footway"], "sidewalk")
    }

    func testReadFailuresAreReportedAsErrors() {
        OSMStubProtocol.stub("GET", "/api/0.6/node/1.json", .status(404))
        OSMStubProtocol.stub("GET", "/api/0.6/node/2.json", .json("{ not json"))
        OSMStubProtocol.stub("GET", "/api/0.6/node/3.json", .offline)
        for id in ["1", "2", "3"] {
            let result: Result<OSMNodeResponse, Error> = run("node \(id)") { connection.getNode(id: id, $0) }
            if case .success = result { XCTFail("node \(id) should have failed") }
        }
    }

    func testOpenChangesetsAreListed() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/changesets.json", .json(OSMBodies.changesets))
        let response = try run("changesets") { connection.getChangesets2(completion: $0) }.get()
        XCTAssertEqual(response.changesets.map(\.id), [146513063])
        XCTAssertEqual(response.changesets.first?.changesetOpen, true)
        XCTAssertEqual(response.changesets.first?.minLat, 51.1)
        XCTAssertEqual(OSMStubProtocol.last("GET", "/api/0.6/changesets.json")?.request.url?.query, "open=true")
    }

    func testTheLegacyChangesetListCompletesWhateverTheOutcome() {
        OSMStubProtocol.stub("GET", "/api/0.6/changesets.json", .json(OSMBodies.changesets))
        let done = expectation(description: "legacy")
        connection.getChangesets { done.fulfill() }
        wait(for: [done], timeout: 5)

        OSMStubProtocol.stub("GET", "/api/0.6/changesets.json", .offline)
        let failed = expectation(description: "legacy failure")
        connection.getChangesets { failed.fulfill() }
        wait(for: [failed], timeout: 5)
    }

    func testUserDetailsCanBeReadThreeWays() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/user/20018.json", .json(OSMBodies.user))
        OSMStubProtocol.stub("GET", "/api/0.6/user/details.json", .json(OSMBodies.user))

        let byId = try run("by id") { connection.getUserDetailsWithId(id: "20018", $0) }.get()
        XCTAssertEqual(byId.user.id, 20018)
        XCTAssertEqual(byId.user.displayName, "Tester")
        XCTAssertEqual(byId.user.changesets.count, 3)
        XCTAssertEqual(byId.user.profileImage?.href, "https://example.com/me.png")

        let current = try run("current") { connection.getUserDetails($0) }.get()
        XCTAssertEqual(current.user.id, 20018)

        let byToken = try run("by token") { connection.getUserDetailsWithToken(accessToken: "stub-token", $0) }.get()
        XCTAssertEqual(byToken.user.id, 20018)
    }

    func testAnUnreachableServerFailsTheUserLookup() {
        OSMStubProtocol.stub("GET", "/api/0.6/user/details.json", .offline)
        let result: Result<OSMUserDataResponse, Error> = run("user") { connection.getUserDetails($0) }
        if case .success = result { XCTFail("should have failed") }
    }

    // MARK: Changesets

    func testOpeningAChangesetReturnsAndRemembersItsId() throws {
        OSMStubProtocol.stub("PUT", "/api/0.6/changeset/create", .json("4242"))
        let id = try run("open") { connection.openChangeSet(createdByTag: "unit-test", $0) }.get()
        XCTAssertEqual(id, 4242)
        XCTAssertEqual(connection.currentChangesetId, 4242)

        let sent = try XCTUnwrap(OSMStubProtocol.last("PUT", "/api/0.6/changeset/create"))
        XCTAssertEqual(sent.request.value(forHTTPHeaderField: "Authorization"), "Bearer stub-token")
        XCTAssertTrue(sent.body.contains(#"<tag k="created_by" v="GIG unit-test"/>"#), sent.body)
        XCTAssertTrue(sent.body.contains("<changeset>"))
    }

    func testAFailedChangesetOpenKeepsTheOldId() {
        connection.currentChangesetId = 7
        OSMStubProtocol.stub("PUT", "/api/0.6/changeset/create", .status(500))
        let result: Result<Int, Error> = run("open") { connection.openChangeSet(createdByTag: "x", $0) }
        if case .success = result { XCTFail("should have failed") }
        XCTAssertEqual(connection.currentChangesetId, 7)
    }

    func testClosingAChangesetAcceptsAnEmptyAnswer() throws {
        OSMStubProtocol.stub("PUT", "/api/0.6/changeset/67/close", .status(200))
        XCTAssertTrue(try run("close") { connection.closeChangeSet(id: "67", completion: $0) }.get())
        XCTAssertEqual(OSMStubProtocol.last("PUT", "/api/0.6/changeset/67/close")?.request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testAFailedCloseIsReported() {
        OSMStubProtocol.stub("PUT", "/api/0.6/changeset/67/close", .status(409))
        let result: Result<Bool, Error> = run("close") { connection.closeChangeSet(id: "67", completion: $0) }
        if case .success = result { XCTFail("should have failed") }
    }

    // MARK: Updating

    func testUpdatingANodeMergesTheTagsAndReturnsTheNewVersion() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/node/31419.json", .json(OSMBodies.node))
        OSMStubProtocol.stub("PUT", "/api/0.6/node/31419", .json("5"))
        var node = try XCTUnwrap(run("node") { connection.getNode(id: "31419", $0) }.get().elements.first)
        node.changeset = 59

        let version = try run("update") { connection.updateNode(node: &node, tags: ["highway": "footway", "kerb": "raised"], completion: $0) }.get()
        XCTAssertEqual(version, 5)
        XCTAssertEqual(node.tags["kerb"], "raised", "the new value replaces the old one")
        XCTAssertEqual(node.tags["highway"], "footway")
        let sent = try XCTUnwrap(OSMStubProtocol.last("PUT", "/api/0.6/node/31419"))
        XCTAssertTrue(sent.body.contains("31419"), "the node itself is the request body")
    }

    func testUpdatingAWayMergesTheTagsAndReturnsTheNewVersion() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/way/4305301937.json", .json(OSMBodies.way))
        OSMStubProtocol.stub("PUT", "/api/0.6/way/4305301937", .json("3"))
        var way = try XCTUnwrap(run("way") { connection.getWay(id: "4305301937", $0) }.get().elements.first)

        let version = try run("update") { connection.updateWay(way: &way, tags: ["name": "Test street"], completion: $0) }.get()
        XCTAssertEqual(version, 3)
        XCTAssertEqual(way.tags["name"], "Test street")
        XCTAssertEqual(way.tags["footway"], "sidewalk", "existing tags are kept")
    }

    func testAFailedUpdateIsReported() throws {
        OSMStubProtocol.stub("GET", "/api/0.6/node/31419.json", .json(OSMBodies.node))
        OSMStubProtocol.stub("PUT", "/api/0.6/node/31419", .status(409))
        var node = try XCTUnwrap(run("node") { connection.getNode(id: "31419", $0) }.get().elements.first)
        let result: Result<Int, Error> = run("update") { connection.updateNode(node: &node, tags: ["a": "b"], completion: $0) }
        if case .success = result { XCTFail("a version conflict should fail") }
    }
}

// MARK: - XML payloads

final class OSMPayloadTests: XCTestCase {

    func testABuilderWithoutChildrenSelfCloses() {
        let builder = OSMXMLBuilder(rootName: "osm")
        builder.addAttribute(name: "version", value: "1")
        builder.addAttribute(name: "changeset", value: "188021")
        let xml = builder.buildXML(exclude_gig_tags: false)
        // Attributes come from a dictionary, so their order is not part of the contract.
        XCTAssertTrue(xml.hasPrefix("<osm "), xml)
        XCTAssertTrue(xml.contains(#"version = "1""#), xml)
        XCTAssertTrue(xml.contains(#"changeset = "188021""#), xml)
        XCTAssertTrue(xml.hasSuffix("/>"), xml)
    }

    func testABuilderWithChildrenNestsThem() {
        let builder = OSMXMLBuilder(rootName: "way")
        builder.addAttribute(name: "id", value: "9")
        builder.addChild(element: TagPayload(key: "highway", value: "footway"))
        builder.addChild(element: WayNodePayload(nodeId: 5))
        let xml = builder.buildXML(exclude_gig_tags: false)
        XCTAssertTrue(xml.contains(#"<tag k="highway" v="footway"/>"#))
        XCTAssertTrue(xml.contains(#"<nd ref="5" />"#))
        XCTAssertTrue(xml.hasSuffix("</way>"))
    }

    func testTagValuesAreEscaped() {
        let xml = TagPayload(key: "name", value: "Fish & <Chips>").toPayload(exclude_gig_tags: false)
        // The entity style (named or numeric) is up to the HTML-entities library; the raw characters must be gone.
        XCTAssertFalse(xml.contains("Fish & "), xml)
        XCTAssertFalse(xml.contains("<Chips>"), xml)
        XCTAssertTrue(xml.hasPrefix(#"<tag k="name" v="Fish &"#), xml)
        XCTAssertTrue(xml.hasSuffix(#"Chips&#x3E;"/>"#) || xml.hasSuffix(#"Chips&gt;"/>"#), xml)
    }

    private func decodeNode() throws -> OSMNode {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try XCTUnwrap(try decoder.decode(OSMNodeResponse.self, from: Data(OSMBodies.node.utf8)).elements.first)
    }

    func testNodePayloadsForEveryOperation() throws {
        var node = try decodeNode()
        node.tags["empty"] = ""

        let modify = node.toPayload(exclude_gig_tags: false)
        XCTAssertTrue(modify.hasPrefix("<modify><node "), modify)
        XCTAssertTrue(modify.contains(#"<tag k="kerb" v="lowered"/>"#))
        XCTAssertFalse(modify.contains("empty"), "a cleared tag is left out so OSM removes it")
        XCTAssertTrue(modify.hasSuffix("</modify>"))

        let create = node.toCreatePayload(exclude_gig_tags: false)
        XCTAssertTrue(create.hasPrefix("<create>"), create)
        XCTAssertTrue(create.hasSuffix("</create>"))

        let delete = node.toDeletePayload()
        XCTAssertTrue(delete.hasPrefix("<delete><node "), delete)
        XCTAssertTrue(delete.contains(#"id = "31419""#))
        XCTAssertTrue(delete.hasSuffix("</delete>"))
    }

    func testWayPayloadListsTagsAndNodes() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var way = try XCTUnwrap(try decoder.decode(OSMWayResponse.self, from: Data(OSMBodies.way.utf8)).elements.first)
        way.tags["gone"] = ""
        let xml = way.toPayload(exclude_gig_tags: false)
        XCTAssertTrue(xml.hasPrefix("<modify><way "), xml)
        XCTAssertTrue(xml.contains(#"<nd ref="1" />"#))
        XCTAssertTrue(xml.contains(#"<nd ref="3" />"#))
        XCTAssertTrue(xml.contains(#"<tag k="footway" v="sidewalk"/>"#))
        XCTAssertFalse(xml.contains("gone"))
    }

    func testTheChangesetPayloadCarriesTheCreatorTag() {
        let xml = OSMChangesetPayload(createdByTag: "abc").toPayload(exclude_gig_tags: false)
        XCTAssertTrue(xml.contains(#"v="GIG abc""#))
        XCTAssertTrue(xml.contains(#"<tag k="comment" v="iOS OSM client"/>"#))
    }
}
