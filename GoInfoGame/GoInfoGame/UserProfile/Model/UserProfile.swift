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
    
    func getFullName()-> String {
           var fullName: String = ""
           if let firstName = firstName {
               fullName += firstName
           }

           if let lastName = lastName {
               if !fullName.isEmpty {
                   fullName += " "
               }
               fullName += lastName
           }
           return fullName
       }
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
