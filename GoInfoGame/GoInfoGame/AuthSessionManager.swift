//
//  AuthSessionManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 23/05/25.
//

import Foundation


final class AuthSessionManager {
    static let shared = AuthSessionManager()

    var accessToken: String?
    var username: String?
    var worksapaceId: String?

    var refreshTokenTimer: Timer?

    private init() {
        accessToken = KeychainManager.load(key: "accessToken")
        username = KeychainManager.load(key: "username")
        worksapaceId = KeychainManager.load(key: "workspaceID")
    }

    func updateToken(_ token: String) {
        accessToken = token
        _ = KeychainManager.save(key: "accessToken", data: token)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
        TokenRefresher.shared.scheduleRefresh()
    }

    func setUser(_ user: String) {
        username = user
        _ = KeychainManager.save(key: "username", data: user)
    }

    func setWorkspaceId(_ workspaceId: String) {
        worksapaceId = workspaceId
        _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
    }

    func invalidateRefreshTokenTimer() {
        refreshTokenTimer?.invalidate()
        refreshTokenTimer = nil
    }

    func validateAccessToken() {
        TokenRefresher.shared.scheduleRefresh()
    }
}



