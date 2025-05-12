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
        }
        let refreshToken = KeychainManager.load(key: "refreshToken")
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.invalidateRefreshTokenTimer()
            }
        }

        ApiManager.shared.performRequest(to: .refreshToken(refreshToken ?? ""), setupType: .login, modelType: PosmLoginSuccessResponse.self) { [weak self] result in
            
            guard let self = self else { return }
            
            var success = false
            switch result {
            case .failure(let error):
                print(error)
                success = false
                break
            case .success(let resp):
                let env = APIConfiguration.shared.environment
                _ = KeychainManager.save(key: "refreshToken", data: resp.refreshToken)
                _ = KeychainManager.save(.accessToken, value: resp.accessToken, for: env)
//                _ = KeychainManager.save(key: "accessToken", data: resp.accessToken)
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
                self.refreshCompletionHandlers.forEach { $0(success) }
                self.refreshCompletionHandlers.removeAll()
            }
            
            completion(success)
        }
    }
}
