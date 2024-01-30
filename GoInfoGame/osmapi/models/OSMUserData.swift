//
//  OSMUserData.swift
//  osmapi
//
//  Created by Lakshmi Shweta Pochiraju on 29/01/24.
//
import Foundation

// MARK: - OSMUserData
struct OSMUserDataResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let user: OSMUserData
}

// MARK: - User
struct OSMUserData: Codable {
    let id: Int
    let displayName: String
    let accountCreated: Date
    let description: String
    let contributorTerms: ContributorTerms
    let roles: [String]
    let changesets, traces: Changesets
    let blocks: Blocks

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case accountCreated = "account_created"
        case description
        case contributorTerms = "contributor_terms"
        case roles, changesets, traces, blocks
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
struct Changesets: Codable {
    let count: Int
}

// MARK: - ContributorTerms
struct ContributorTerms: Codable {
    let agreed: Bool
}
