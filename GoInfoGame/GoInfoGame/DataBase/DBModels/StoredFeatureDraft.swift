//
//  StoredFeatureDraft.swift
//  GoInfoGame
//

import Foundation
import RealmSwift
import CoreLocation

/// A feature (created via Add Feature, with any captured photos already saved to
/// disk) still waiting to be uploaded to Panoramax and created as an OSM node.
/// Presence of a row here means the feature is pending — the row is deleted once
/// creation succeeds, which is what lets a feature captured offline (or interrupted
/// mid-upload) survive an app kill and be retried later from the sync button or on
/// next app launch. Mirrors `StoredNoteDraft`'s role for the Create Note flow.
class StoredFeatureDraft: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var presetName: String = ""
    @Persisted var iconName: String = ""
    @Persisted var tags = Map<String, String>()
    @Persisted var imagePaths: List<String> = List<String>()
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var createdAt: Date = Date()
    @Persisted var lastError: String?
    @Persisted var retryCount: Int = 0
    /// Panoramax URL of each photo already uploaded, keyed by its index in `imagePaths`
    /// ("0", "1", …; Realm map keys can't hold the "." of a file path), so a retry only
    /// uploads the photos that haven't gone up yet.
    @Persisted var uploadedPhotoURLs = Map<String, String>()
}

/// Plain-value mirror of a StoredFeatureDraft. Realm objects are confined to the
/// thread/Realm instance that fetched them, so this is what crosses into async Task
/// and actor contexts while a queued feature is being retried.
struct StoredFeatureDraftSnapshot {
    let id: String
    let presetName: String
    let iconName: String
    let tags: [String: String]
    let imagePaths: [String]
    let coordinates: CLLocationCoordinate2D
    /// When the draft was saved, i.e. when its photos were taken.
    var createdAt: Date = Date()
    /// Photos already on Panoramax, keyed by their index in `imagePaths`.
    var uploadedPhotoURLs: [Int: String] = [:]
}
