//
//  PosmLoginModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let posmLoginModel = try? JSONDecoder().decode(PosmLoginModel.self, from: jsonData)

import Foundation

// MARK: - PosmLoginModel
struct PosmLoginModel: Codable {
    let accessToken: String
    let expiresIn, refreshExpiresIn: Int
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
        case refreshToken = "refresh_token"
    }
}
