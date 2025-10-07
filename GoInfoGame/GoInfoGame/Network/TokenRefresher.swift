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
    private var refreshCompletionHandlers: [(Bool, Error?) -> Void] = []
    private let refreshQueue = DispatchQueue(label: "TokenRefreshQueue", attributes: .concurrent)
    

    func refreshToken(refreshToken: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
        refreshQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if self.isRefreshing {
                self.refreshCompletionHandlers.append(completion)
                return
            }

            self.isRefreshing = true
        }
        let refreshToken = refreshToken ?? KeychainManager.load(key: "refreshToken")
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.invalidateRefreshTokenTimer()
            }
        }

        ApiManager.shared.performRequest(to: .refreshToken(refreshToken ?? ""), setupType: .login, modelType: PosmLoginSuccessResponse.self) { [weak self] result in
            
            guard let self = self else { return }
            
            var success = false
            var error: Error? = nil
            switch result {
            case .failure(let e):
                print(e)
                success = false
                error = e
                break
            case .success(let resp):
                _ = KeychainManager.save(key: "refreshToken", data: resp.refreshToken)
                _ = KeychainManager.save(key: "accessToken", data: resp.accessToken)
                UserDefaults.standard.setValue(resp.expiresIn, forKey: "accessToken_expire_in")
                UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
                DispatchQueue.main.async {
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.validateAccessToken()
                    }
                }
                success = true
                break
                
            }

            self.refreshQueue.async(flags: .barrier) {
                self.isRefreshing = false
                self.refreshCompletionHandlers.forEach { $0(success, error) }
                self.refreshCompletionHandlers.removeAll()
            }
            
            completion(success, error)
        }
    }
}


extension TokenRefresher {
    func refreshTokenAsync() async -> Bool {
        await withCheckedContinuation { continuation in
            self.refreshToken { success, error in
                continuation.resume(returning: success)
            }
        }
    }
}
