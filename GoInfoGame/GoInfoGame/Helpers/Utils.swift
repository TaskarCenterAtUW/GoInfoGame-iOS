//
//  Utils.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 29/12/23.
//

import Foundation
import SwiftUI

struct Utilities {
    static func clearAllData() {
        @AppStorage("loggedIn") var loggedIn: Bool = false
        _ = KeychainManager.delete(key: "accessToken")
        _ = KeychainManager.delete(key: "refreshToken")
       // _ = KeychainManager.delete(key: "username")
        loggedIn = false
        UserProfileCache.shared.clearUserProfile()
        UserDefaults.standard.removeObject(forKey: "accessToken_Generate")
        UserDefaults.standard.removeObject(forKey: "accessToken_expire_in")
    }
}
