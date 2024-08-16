//
//  UserProfile.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let userProfileResponse = try? JSONDecoder().decode(UserProfileResponse.self, from: jsonData)

import Foundation

// MARK: - UserProfileResponse
struct TdeiUserProfile: Codable {
    let id, firstName, lastName, email: String?
    let phone, apiKey: String?
    let emailVerified: Bool?
    let username: String?
}


class UserProfileCache {
    static let shared = UserProfileCache()
    
    private init() {}
    
    var user: TdeiUserProfile?

    func cacheUserProfile(_ user: TdeiUserProfile) {
        self.user = user
    }
    
    func clearUserProfile() {
        self.user = nil
    }
}
