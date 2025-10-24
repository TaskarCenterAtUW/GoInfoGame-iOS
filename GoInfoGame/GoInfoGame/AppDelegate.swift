//
//  AppDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 09/11/23.
//

import SwiftUI
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var refreshTokenTime: Timer? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
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
