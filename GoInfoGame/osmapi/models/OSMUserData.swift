//
//  OSMUserData.swift
//  osmapi
//
//  Created by Lakshmi Shweta Pochiraju on 29/01/24.
//
import Foundation

// MARK: - OSMUserData
public struct OSMUserDataResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    public let user: OSMUserData
}

// MARK: - User
public struct OSMUserData: Codable {
    public let id: Int
    public let displayName: String
    let accountCreated: Date
    let description: String
    let contributorTerms: ContributorTerms
    let roles: [String]
    public let changesets, traces: Changesets
    let blocks: Blocks
    public let profileImage: profileImage?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case accountCreated = "account_created"
        case description
        case contributorTerms = "contributor_terms"
        case roles, changesets, traces, blocks
        case profileImage = "img"
    }
}

// MARK: - Blocks
struct Blocks: Codable {
    let received: Received
}

// MARK: - Received
struct Received: Codable {
    let count, active: Int
}

// MARK: - Changesets
public struct Changesets: Codable {
    public let count: Int
}

// MARK: - ContributorTerms
struct ContributorTerms: Codable {
    let agreed: Bool
}

public struct profileImage: Codable {
    public let href: String
}
