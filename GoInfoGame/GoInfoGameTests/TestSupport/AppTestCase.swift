//
//  AppTestCase.swift
//  GoInfoGameTests
//
//  Base class for hosted unit tests: resets every piece of process-wide app state a test
//  can touch (UserDefaults, the Keychain stand-in, the Realm database, the quest
//  repository, hidden quests, the profile cache) and installs MockHTTP, so tests are
//  order-independent and never reach the real network.
//

import XCTest
import Combine
import CoreLocation
@testable import GoInfoGame

class AppTestCase: XCTestCase {

    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        // MapUndoManager keeps one Realm for its whole life, and a Realm may only be used on the thread
        // that created it - so make sure the singleton is first touched here, on the main thread.
        _ = MapUndoManager.shared
        MockHTTP.install()
        resetAppState()
    }

    override func tearDown() {
        cancellables.removeAll()
        MockHTTP.uninstall()
        resetAppState()
        super.tearDown()
    }

    /// Everything below is process-global in the host app, so it has to be wiped between tests.
    func resetAppState() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        DatabaseConnector.shared.clearDB()
        UserProfileCache.shared.clearUserProfile()
        HiddenQuestManager.shared.hiddenQuests = []
        let repo = QuestsRepository.shared
        repo.allQuests = []
        repo.longQuestModels = []
        repo.featurePresets = []
        repo.customIcons = []
        repo.recencyPeriodDays = nil
        SessionManager.shared.lastLoginPassword = nil
    }

    // MARK: Session helpers

    /// A signed-in user, exactly as a successful login would leave the Keychain: the same
    /// JWTs the UI tests' LoginSuccess.json fixture serves (sub "uitest-user-0001").
    func signIn(workspaceID: String? = "222", environment: APIEnvironment = .production, username: String = "test@email.com") {
        let login = MockHTTP.fixtureJSON("LoginSuccess") as? [String: Any] ?? [:]
        _ = KeychainManager.save(key: "accessToken", data: login["access_token"] as? String ?? "access")
        _ = KeychainManager.save(key: "refreshToken", data: login["refresh_token"] as? String ?? "refresh")
        if let workspaceID { _ = KeychainManager.save(key: "workspaceID", data: workspaceID) }
        APIConfiguration.shared.environment = environment
        _ = KeychainManager.save(.username, value: username, for: environment)
    }

    var fixtureAccessToken: String {
        (MockHTTP.fixtureJSON("LoginSuccess") as? [String: Any])?["access_token"] as? String ?? ""
    }

    // MARK: Waiting

    /// Polls `condition` on the main run loop until it holds or `timeout` elapses.
    @discardableResult
    func waitUntil(timeout: TimeInterval = 5, _ message: @autoclosure () -> String = "condition not met",
                   file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
        let ok = condition()
        if !ok { XCTFail("Timed out: \(message())", file: file, line: line) }
        return ok
    }

    /// Records everything sent on MapViewPublisher.shared.dismissSheet.
    final class SheetEvents {
        private let lock = NSLock()
        private var stored: [SheetDismissalScenario] = []
        var events: [SheetDismissalScenario] { lock.lock(); defer { lock.unlock() }; return stored }
        var names: [String] { events.map { Self.name($0) } }
        fileprivate var token: AnyCancellable?

        static func name(_ e: SheetDismissalScenario) -> String {
            switch e {
            case .dismissed: return "dismissed"
            case .syncing: return "syncing"
            case .synced: return "synced"
            case .failed: return "failed"
            case .hideElement: return "hideElement"
            case .undoDone: return "undoDone"
            case .syncBackground: return "syncBackground"
            case .elementRemoved: return "elementRemoved"
            case .answerSynced: return "answerSynced"
            case .noteSubmitted: return "noteSubmitted"
            case .notesQueueUpdated: return "notesQueueUpdated"
            case .notesSyncing: return "notesSyncing"
            case .notesSyncFinished: return "notesSyncFinished"
            case .featureSubmitted: return "featureSubmitted"
            case .featuresQueueUpdated: return "featuresQueueUpdated"
            case .featuresSyncing: return "featuresSyncing"
            case .featuresSyncFinished: return "featuresSyncFinished"
            case .questPhotoUploadFailed: return "questPhotoUploadFailed"
            }
        }
        fileprivate func append(_ e: SheetDismissalScenario) { lock.lock(); stored.append(e); lock.unlock() }
        func contains(_ name: String) -> Bool { names.contains(name) }
    }

    /// A tiny solid-colour image, enough to be encoded to JPEG and uploaded.
    func makeImage(_ color: UIColor = .red, side: CGFloat = 8) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // 1px per point, so a saved-then-loaded JPEG has the size it was made with
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    func recordSheetEvents() -> SheetEvents {
        let recorder = SheetEvents()
        recorder.token = MapViewPublisher.shared.dismissSheet.sink { recorder.append($0) }
        return recorder
    }
}
