//
//  TokenRefresher.swift
//  GoInfoGame
//
//  Created by Prashamsa on 27/02/25.
//

import Foundation
import SwiftUI

class TokenRefresher {
    static let shared = TokenRefresher()
    private var isRefreshing = false
    private var refreshCompletionHandlers: [(Bool) -> Void] = []
    private let refreshQueue = DispatchQueue(label: "TokenRefreshQueue", attributes: .concurrent)

    func refreshToken(completion: @escaping (Bool) -> Void) {
        refreshQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if self.isRefreshing {
                self.refreshCompletionHandlers.append(completion)
                return
            }

            self.isRefreshing = true
            self.refreshCompletionHandlers.append(completion)

            let refreshToken = KeychainManager.load(key: "refreshToken") ?? ""
            TDEIAPIManager.shared.refreshToken(refreshToken: refreshToken) { [weak self] result in
                guard let self = self else { return }

                var success = false
                switch result {
                case .failure(let error):
                    print("Token refresh failed: \(error)")
                    success = false
                case .success(let resp):
                    _ = KeychainManager.save(key: "refreshToken", data: resp.refreshToken)
                    _ = KeychainManager.save(key: "accessToken", data: resp.accessToken)
                    UserDefaults.standard.set(resp.expiresIn, forKey: "accessToken_expire_in")
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
                    AuthSessionManager.shared.updateToken(resp.accessToken)
                    success = true
                }

                self.refreshQueue.async(flags: .barrier) {
                    self.isRefreshing = false
                    self.refreshCompletionHandlers.forEach { $0(success) }
                    self.refreshCompletionHandlers.removeAll()
                }
            }
        }
    }

    func scheduleRefresh() {
        DispatchQueue.main.async {
            AuthSessionManager.shared.invalidateRefreshTokenTimer()

            let tokenGeneratedAt = UserDefaults.standard.double(forKey: "accessToken_Generate")
            guard tokenGeneratedAt > 0 else { return }

            let expireIn = UserDefaults.standard.integer(forKey: "accessToken_expire_in")
            let fireTime = Double(expireIn) * 0.8
            let interval = Date().timeIntervalSince1970 - tokenGeneratedAt

            if interval >= fireTime {
                self.refreshToken { _ in }
            } else {
                AuthSessionManager.shared.refreshTokenTimer = Timer.scheduledTimer(withTimeInterval: fireTime - interval, repeats: false) { _ in
                    self.refreshToken { _ in }
                }
            }
        }
    }
}

