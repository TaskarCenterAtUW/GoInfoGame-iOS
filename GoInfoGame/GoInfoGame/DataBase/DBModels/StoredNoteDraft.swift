//
//  StoredNoteDraft.swift
//  GoInfoGame
//

import Foundation
import RealmSwift
import CoreLocation

/// A note (with any captured photos already saved to disk) still waiting to be
/// uploaded to Panoramax and submitted to the notes API. Presence of a row here
/// means the note is pending — the row is deleted once submission succeeds, which
/// is what lets a note captured offline (or interrupted mid-upload) survive an app
/// kill and be retried later from the sync button or on next app launch.
class StoredNoteDraft: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var noteText: String = ""
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

/// Plain-value mirror of a StoredNoteDraft. Realm objects are confined to the thread/
/// Realm instance that fetched them, so this is what crosses into async Task and actor
/// contexts while a queued note is being retried.
struct StoredNoteDraftSnapshot {
    let id: String
    let noteText: String
    let imagePaths: [String]
    let coordinates: CLLocationCoordinate2D
    /// When the draft was saved, i.e. when its photos were taken.
    var createdAt: Date = Date()
    /// Photos already on Panoramax, keyed by their index in `imagePaths`.
    var uploadedPhotoURLs: [Int: String] = [:]
}
