//
//  OSMChangeset.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation

struct OSMChangesetResponse: Codable {
    let version, generator, copyright: String
    let attribution, license: String
    let changesets: [OSMChangeset]
}

// MARK: - Changeset
struct OSMChangeset: Codable {
    let id: Int
    let createdAt: Date
    let changesetOpen: Bool
    let commentsCount, changesCount: Int
    let closedAt: Date?
    let minLat, minLon, maxLat, maxLon: Double?
    let uid: Int
    let user: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case changesetOpen = "open"
        case commentsCount = "comments_count"
        case changesCount = "changes_count"
        case closedAt = "closed_at"
        case minLat = "min_lat"
        case minLon = "min_lon"
        case maxLat = "max_lat"
        case maxLon = "max_lon"
        case uid, user
    }
}
