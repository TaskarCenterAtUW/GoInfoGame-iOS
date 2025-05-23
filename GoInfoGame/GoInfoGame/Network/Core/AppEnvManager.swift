//
//  AppEnvManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 23/05/25.
//

import Foundation

enum AppEnv: String, CaseIterable {
    case dev = "Development"
    case staging = "Staging"
    case production = "Production"
}

final class AppEnvManager {
    static let shared = AppEnvManager()
    private let key = "AppEnv"

    var current: AppEnv {
        get {
            if let raw = UserDefaults.standard.string(forKey: key),
               let env = AppEnv(rawValue: raw) {
                return env
            }
            return .staging
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}
