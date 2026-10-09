//
//  AppDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 09/11/23.
//

import SwiftUI
import FirebaseCore
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var refreshTokenTime: Timer? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Absolute first thing, before anything else on this or any other thread has a
        // chance to run: force Realm's schema to be computed once, synchronously, here.
        // RLMSchema.sharedSchema (a process-wide singleton, cached for the rest of the
        // process once computed) discovers Realm's model classes by walking every
        // Objective-C class currently loaded via RLMRegisterClassLocalNames. If that walk
        // races with something else registering a class on another thread - which is
        // routine seconds later, once Firebase/StoreKit/etc. are initializing and
        // SceneDelegate.sceneDidBecomeActive fires NotesSubmissionManager and
        // FeatureSubmissionManager's resumePendingUploads(), each opening its own
        // Task.detached that can independently trigger this same first-ever Realm access -
        // class_getSuperclass can read a pointer the runtime is mutating out from under it
        // and crash with EXC_BAD_ACCESS (seen as a crash inside
        // RLMRegisterClassLocalNames/RLMIsObjectSubclass). Doing it here, alone, before any
        // of that concurrent activity starts, means every later access - including the ones
        // from those detached tasks - just reuses the cached schema and never repeats the
        // race. Intermittent, because it depends on how the OS scheduler happens to
        // interleave threads on a given launch; far more likely to surface under a UI test
        // suite, which launches a fresh process (and so re-triggers this one-time
        // computation) dozens of times in a row.
        _ = try? Realm(configuration: RealmConfig.configuration)

        // Before anything else: a UI test run needs its stubs registered ahead of the
        // first request, and ApiManager.shared is created lazily by whoever asks first.
        // Reset first: SceneDelegate picks its root view from `loggedIn`, so stale state
        // has to be gone before the scene connects.
        #if DEBUG
        UITestStubs.resetStateIfNeeded()
        UITestStubs.installIfNeeded()
        #endif

        //clear DB to avoid overlap of data after workspace selection
       // DatabaseConnector.shared.clearDB()
        validateAccessToken()
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func invalidateRefreshTokenTimer() {
        if let timer = refreshTokenTime {
            timer.invalidate()
            refreshTokenTime = nil
        }
    }
    
    func validateAccessToken() {
        invalidateRefreshTokenTimer()
        let tokenGeneratedAt = UserDefaults.standard.double(forKey: "accessToken_Generate")
        guard tokenGeneratedAt > 0 else {
            return
        }
        let expireIn = UserDefaults.standard.integer(forKey: "accessToken_expire_in")
        let sessionFireTime = Double(expireIn) * 0.8
        let timeIntervalFromSessionCreation = Date().timeIntervalSince1970 - tokenGeneratedAt
        if timeIntervalFromSessionCreation >= sessionFireTime {
            refreshToken()
        } else {
            refreshTokenTime = Timer.scheduledTimer(withTimeInterval: sessionFireTime - timeIntervalFromSessionCreation, repeats: false, block: { [weak self] _ in
                self?.refreshToken()
            })
        }
    }
    
    private func refreshToken() {
        TokenRefresher.shared.refreshToken { status, _ in
            print("Refresh status \(status)")
            if status == false {
                DispatchQueue.main.async {
                    Utilities.clearAllData()
                    if let window = UIApplication.window() {
                        window.rootViewController = UIHostingController(rootView: PosmLoginView(forceUpdateManager: ForceUpdateManager()))
                    }
                }
            }
        }
    }


}

extension AppDelegate {

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {

        print(url.absoluteString)
        return true
    }
}
