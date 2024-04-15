//
//  TDEILoginResponse.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 15/04/24.
//

import Foundation

// MARK: - TDEILogin
struct TDEILoginResponse: Codable {
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
