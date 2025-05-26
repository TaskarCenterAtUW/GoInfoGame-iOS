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
    
    private var refreshTokenTimer: Timer?

    private init() {
        accessToken = KeychainManager.load(key: "accessToken")
        username = KeychainManager.load(key: "username")
        worksapaceId = KeychainManager.load(key: "workspaceID")
    }

    // MARK: - Token & User Info
    
    func updateToken(_ token: String) {
        accessToken = token
        _ = KeychainManager.save(key: "accessToken", data: token)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
    }
    
    func setUser(_ user: String) {
        username = user
        _ = KeychainManager.save(key: "username", data: user)
    }
    
    func setWorkspaceId(_ workspaceId: String) {
        worksapaceId = workspaceId
        _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
    }

    // MARK: - Refresh Token Logic

    func validateAccessToken() {
        invalidateRefreshTokenTimer()
        
        let tokenGeneratedAt = UserDefaults.standard.double(forKey: "accessToken_Generate")
        guard tokenGeneratedAt > 0 else { return }

        let expireIn = UserDefaults.standard.integer(forKey: "accessToken_expire_in")
        let fireTime = Double(expireIn) * 0.8
        let interval = Date().timeIntervalSince1970 - tokenGeneratedAt

        if interval >= fireTime {
            refreshToken()
        } else {
            refreshTokenTimer = Timer.scheduledTimer(withTimeInterval: fireTime - interval, repeats: false) { [weak self] _ in
                self?.refreshToken()
            }
        }
    }

    func invalidateRefreshTokenTimer() {
        refreshTokenTimer?.invalidate()
        refreshTokenTimer = nil
    }

    private func refreshToken() {
        TokenRefresher.shared.refreshToken { success in
            if !success {
                DispatchQueue.main.async {
                    Utilities.clearAllData()
                    NotificationCenter.default.post(name: .init("SessionExpired"), object: nil)
                }
            }
        }
    }
}


