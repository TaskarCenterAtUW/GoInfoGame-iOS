//
//  HelpersTests.swift
//  GoInfoGameTests
//
//  Small shared helpers: geometry/extension utilities, URLSession convenience, the legacy
//  sidewalk-width quest, the force-update request and the biometric opt-out on login.
//

import XCTest
import Combine
import CoreLocation
import SceneKit
import RealmSwift
@testable import GoInfoGame
@testable import osmparser

final class GeometryHelperTests: XCTestCase {

    func testBearingPointsTowardsTheTarget() {
        let origin = CLLocation(latitude: 17.4385, longitude: 78.361)
        XCTAssertEqual(origin.bearing(to: CLLocation(latitude: 17.44, longitude: 78.361)), 0, accuracy: 0.5)
        XCTAssertEqual(origin.bearing(to: CLLocation(latitude: 17.4385, longitude: 78.362)), 90, accuracy: 0.5)
        XCTAssertEqual(origin.bearing(to: CLLocation(latitude: 17.437, longitude: 78.361)), 180, accuracy: 0.5)
        XCTAssertEqual(origin.bearing(to: CLLocation(latitude: 17.4385, longitude: 78.360)), 270, accuracy: 0.5)
        let west = origin.bearing(to: CLLocation(latitude: 17.4385, longitude: 78.360))
        XCTAssertTrue((0..<360).contains(west), "bearings are normalised to 0..<360")
    }

    func testDegreesAndRadiansConvertBothWays() {
        XCTAssertEqual(180.0.degreesToRadians, .pi, accuracy: 1e-12)
        XCTAssertEqual(Double.pi.radiansToDegrees, 180, accuracy: 1e-12)
        XCTAssertEqual(37.5.degreesToRadians.radiansToDegrees, 37.5, accuracy: 1e-9)
    }

    func testCardinalDirectionsCoverTheCompass() {
        let expected: [(Double, String)] = [(0, "North"), (44, "North East"), (90, "East"), (135, "South East"),
                                            (180, "South"), (225, "South West"), (270, "West"), (359, "North")]
        for (degrees, name) in expected {
            XCTAssertEqual(Utilities.degreesToCardinalDirection(bearing: degrees), name, "\(degrees)°")
        }
    }

    func testTheBoundingBoxIsCentredOnTheLocation() {
        let centre = CLLocation(latitude: 17.4385, longitude: 78.361)
        let box = centre.boundingCoordinates(distance: 1000)
        XCTAssertEqual(box.left.coordinate.latitude, 17.4385)
        XCTAssertEqual(box.right.coordinate.latitude, 17.4385)
        XCTAssertEqual(box.top.coordinate.longitude, 78.361)
        XCTAssertEqual(box.bottom.coordinate.longitude, 78.361)
        XCTAssertEqual(centre.distance(from: box.top), 1000, accuracy: 5)
        XCTAssertEqual(centre.distance(from: box.bottom), 1000, accuracy: 5)
        XCTAssertEqual(centre.distance(from: box.left), 1000, accuracy: 5)
        XCTAssertEqual(centre.distance(from: box.right), 1000, accuracy: 5)
        XCTAssertGreaterThan(box.right.coordinate.longitude, box.left.coordinate.longitude)
    }

    func testCoordinatesAreComparedByValueAndPersistedAsALocation() {
        let a = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        XCTAssertTrue(a == CLLocationCoordinate2D(latitude: 1, longitude: 2))
        XCTAssertFalse(a == CLLocationCoordinate2D(latitude: 1, longitude: 3))

        let persisted = a.persistableValue
        XCTAssertEqual(persisted.latitude, 1)
        XCTAssertEqual(persisted.longitude, 2)
        XCTAssertTrue(CLLocationCoordinate2D(persistedValue: persisted) == a)
    }

    func testRemovingAnObjectOnlyRemovesTheFirstMatch() {
        var items = [1, 2, 3, 2]
        items.removeObject(element: 2)
        XCTAssertEqual(items, [1, 3, 2])
        items.removeObject(element: 99)
        XCTAssertEqual(items, [1, 3, 2])
    }

    func testVectorsMeasureDistanceAndCompareByValue() {
        let a = SCNVector3(0, 0, 0)
        let b = SCNVector3(3, 4, 12)
        XCTAssertEqual(a.distance(from: b), 13, accuracy: 1e-5)
        XCTAssertEqual(a, SCNVector3(0, 0, 0))
        XCTAssertNotEqual(a, b)

        let transform = matrix_float4x4(columns: (SIMD4(1, 0, 0, 0), SIMD4(0, 1, 0, 0), SIMD4(0, 0, 1, 0), SIMD4(7, 8, 9, 1)))
        XCTAssertEqual(SCNVector3.positionFromTransform(transform), SCNVector3(7, 8, 9))
    }

    func testTheKeyboardHeightFollowsTheKeyboardNotifications() {
        var heights: [CGFloat] = []
        let token = Publishers.keyboardHeight.sink { heights.append($0) }
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil,
                                        userInfo: [UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 291)])
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)
        XCTAssertEqual(heights, [291, 0, 0])
        token.cancel()
    }
}

// MARK: - Requests

final class RequestHelperTests: AppTestCase {

    func testSignedInRequestsCarryTheBearerToken() {
        signIn()
        var request = URLRequest(url: URL(string: "https://example.com/x")!)
        request.addAuthorizationHeader()
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(fixtureAccessToken)")
    }

    func testSignedOutRequestsAreLeftAlone() {
        var request = URLRequest(url: URL(string: "https://example.com/x")!)
        request.addAuthorizationHeader()
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func testTheSessionConvenienceReturnsTheBody() {
        MockHTTP.stub("GET", path: "/hello", reply: .text("hi"))
        let done = expectation(description: "response")
        var result: Result<Data, Error>?
        URLSession.shared.performRequest(url: URL(string: "https://example.com/hello")!) { result = $0; done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual((try? result?.get()).flatMap { String(data: $0, encoding: .utf8) }, "hi")
    }

    func testTheSessionConvenienceReportsTransportErrors() {
        MockHTTP.stub("GET", path: "/hello", reply: .offline)
        let done = expectation(description: "response")
        var failed = false
        URLSession.shared.performRequest(url: URL(string: "https://example.com/hello")!) { if case .failure = $0 { failed = true }; done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(failed)
    }

    func testAnEmptyBodyIsStillASuccess() {
        MockHTTP.stub("GET", path: "/hello", reply: .status(204))
        let done = expectation(description: "response")
        var data: Data?
        URLSession.shared.performRequest(url: URL(string: "https://example.com/hello")!) { data = try? $0.get(); done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(data?.count, 0)
    }

    func testTheForceUpdateRequestPointsAtTheConfiguredURL() {
        let configured = Bundle.main.infoDictionary?["APP_FORCE_UPDATE_URL"] as? String
        XCTAssertEqual(ForceUpdateRequest().urlRequest?.url?.absoluteString, configured.flatMap { URL(string: $0)?.absoluteString })
    }
}

// MARK: - Legacy sidewalk-width quest

final class SideWalkWidthQuestTests: AppTestCase {

    func testTheQuestDescribesItself() {
        let quest = SideWalkWidth()
        XCTAssertEqual(quest.questId, "3")
        XCTAssertEqual(quest.displayUnit.id, "0 - 3")
        XCTAssertEqual(quest.displayUnit.sheetSize, .MEDIUM)
        XCTAssertNotNil(quest.filterExpression)
        XCTAssertNotNil(quest.filterExpression, "the parsed filter is cached")
        XCTAssertNotNil(quest.internalForm)
    }

    func testCopyingBindsTheElement() {
        let way = TestQuestUtils.way(id: 77, nodes: [1, 2], tags: ["highway": "footway"])
        let copy = SideWalkWidth().copyWithElement(element: way) as? SideWalkWidth
        XCTAssertEqual(copy?.relationData?.id, 77)
        XCTAssertEqual(copy?.displayUnit.id, "77 - 3")
    }

    func testAnAnswerWithoutAnElementIsIgnored() {
        SideWalkWidth().onAnswer(answer: WidthAnswer(width: "1.5", units: "m", isARMeasurement: false))
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(MockHTTP.requests.isEmpty)
    }

    func testAnAnswerIsSubmittedAsAWidthTag() {
        signIn()
        seedMap("LongFormOSMElements")
        MockServer.installChangesets()
        MockServer.installLatestElements()
        let events = recordSheetEvents()

        let way = TestQuestUtils.way(id: 121949)
        let quest = SideWalkWidth().copyWithElement(element: way) as! SideWalkWidth
        quest.onAnswer(answer: WidthAnswer(width: "1.5", units: "m", isARMeasurement: true))
        waitUntil(timeout: 10, "the width never synced") { events.contains("synced") }
        XCTAssertEqual(DatabaseConnector.shared.getWay(id: 121949)?.tags["width"], "1.5")
    }
}

// MARK: - Login: opting out of biometrics

final class LoginBiometricOptOutTests: AppTestCase {

    private func signedInModel() -> PosmLoginViewModel {
        SessionManager.shared.setDeclinedBiometric(true, for: .production)
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        let model = PosmLoginViewModel()
        model.username = "tester@example.com"
        model.password = "pw"
        model.performLogin(for: .production)
        waitUntil("login did not finish") { model.isLoginSuccess }
        return model
    }

    func testBiometricsCannotBeEnabledBeforeLoggingIn() {
        let model = PosmLoginViewModel()
        model.enableBiometrics(enable: true)
        XCTAssertFalse(model.isLoginSuccess)
        XCTAssertFalse(SessionManager.shared.isBiometricEnabled(for: .production))
    }

    func testDecliningBiometricsFinishesTheLoginAndRemembersTheChoice() {
        SessionManager.shared.setDeclinedBiometric(false, for: .production)
        MockHTTP.stub("POST", path: "/api/v1/authenticate", reply: .fixture("LoginSuccess"))
        let model = PosmLoginViewModel()
        model.username = "tester@example.com"
        model.password = "pw"
        model.performLogin(for: .production)
        // On a machine with biometrics the opt-in prompt is shown first; either way the user can say no.
        waitUntil("login did not settle") { model.isLoginSuccess || model.showBiometricPrompt }

        model.enableBiometrics(enable: false)
        XCTAssertTrue(model.isLoginSuccess)
        XCTAssertTrue(SessionManager.shared.hasDeclinedBiometric(for: .production))
        XCTAssertFalse(SessionManager.shared.isBiometricEnabled(for: .production))
    }

    func testAskingForBiometricsWhereNoneAreAvailableFallsBackToDeclining() throws {
        try XCTSkipIf(BiometricAuthManager.canEvaluateBiometrics(), "this machine has biometrics enrolled")
        let model = signedInModel()
        model.enableBiometrics(enable: true)
        XCTAssertTrue(model.isLoginSuccess)
        XCTAssertTrue(SessionManager.shared.hasDeclinedBiometric(for: .production))
    }
}
