//
//  FeatureSubmissionManager.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation
import osmapi

/// Everything needed to submit a feature. `id` ties it to its persisted
/// StoredFeatureDraft row so FeatureSubmissionManager can upsert/delete the right
/// queue entry. `tags` already includes the preset's tags plus `ext:notes` (if any) —
/// only `ext:image_urlN` for uploaded photos is added later, once each photo is
/// actually uploaded.
struct FeatureDraft {
    var id: String = UUID().uuidString
    var presetName: String
    var iconName: String
    var tags: [String: String]
    var images: [UIImage]
    var coordinates: CLLocationCoordinate2D
}

/// Creates features (and their Kartaview photo uploads) outside the lifetime of
/// FeatureSubmissionView, so the sheet can dismiss immediately after Submit is tapped —
/// mirrors NotesSubmissionManager's role for Create Note. Every draft is persisted
/// (photos on disk, metadata in Realm) *before* any network call, so a feature captured
/// offline — or one whose upload gets interrupted — survives an app kill and stays
/// queued until it's retried, either automatically (submit, app foreground/launch) or
/// manually via the sync button.
///
/// Whether the created element satisfies a LongForm `quest_query` is only known once
/// creation actually succeeds, which may happen well after the sheet closed — so unlike
/// the (removed) synchronous flow, this never auto-opens the quest sheet. It just adds
/// the pin quietly, the same way a synced note only ever shows a passive confirmation.
enum FeatureSubmissionManager {

    /// Persists the draft, then drains the whole pending queue (not just this
    /// draft), so any earlier features that failed get swept up too.
    static func submit(_ draft: FeatureDraft) {
        Task.detached(priority: .userInitiated) {
            let previousPaths = DatabaseConnector.shared.featureDraftImagePaths(id: draft.id)
            if !previousPaths.isEmpty {
                FeatureImageStorage.shared.delete(paths: previousPaths)
            }

            let imagePaths = draft.images.compactMap { try? FeatureImageStorage.shared.save($0) }
            DatabaseConnector.shared.upsertFeatureDraft(
                id: draft.id,
                presetName: draft.presetName,
                iconName: draft.iconName,
                tags: draft.tags,
                imagePaths: imagePaths,
                coordinates: draft.coordinates
            )

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.featuresQueueUpdated)
            }

            await FeatureQueueProcessor.shared.processPending()
        }
    }

    /// Resumes uploading whatever features are still queued. Called from the sync
    /// button and on app foreground/launch.
    static func resumePendingUploads() {
        Task.detached(priority: .userInitiated) {
            await FeatureQueueProcessor.shared.processPending()
        }
    }

    /// A failed attempt is never surfaced to the user — the feature stays queued
    /// (already reflected in the sync badge) and is retried by the next trigger.
    fileprivate static func attempt(_ record: StoredFeatureDraftSnapshot) async {
        do {
            var tags = record.tags
            let images = record.imagePaths.compactMap { FeatureImageStorage.shared.load(path: $0) }
            if !images.isEmpty {
                let photoURLs = try await uploadPhotos(images)
                for (index, url) in photoURLs.enumerated() {
                    tags["ext:image_url\(index + 1)"] = url
                }
            }

            let node = UserNodesHelper.getPowerPole(
                lat: record.coordinates.latitude,
                lon: record.coordinates.longitude,
                changeset: 1,
                tags: tags
            )
            let created = try await DatasyncManager.shared.createNode(node: node)

            // Persist locally under the server's real id/version (never returned any
            // other way — see DatasyncManager.uploadNode), so the element can be
            // matched against LongForm quest_query filters and correctly submitted as
            // a "modify" if the user later answers a quest for it.
            let persistedNode = OSMNode(
                type: "node", id: created.id, lat: record.coordinates.latitude, lon: record.coordinates.longitude,
                timestamp: Date(), version: created.version, changeset: 0, user: "", uid: 0, tags: tags
            )
            DatabaseConnector.shared.saveOSMElements([persistedNode])

            // Makes this creation undoable — shows up in the Undo sidebar right away,
            // and deletes the node (rather than reverting tags) if the user undoes it.
            _ = DatabaseConnector.shared.createChangesetForNewElement(
                id: created.id,
                questType: record.presetName,
                tags: tags,
                version: created.version,
                iconName: record.iconName,
                point: record.coordinates
            )

            let matchedQuestUnit = AppQuestManager.shared.getUpdatedQuest(elementId: "\(created.id)")

            DatabaseConnector.shared.deleteFeatureDraft(id: record.id)
            FeatureImageStorage.shared.delete(paths: record.imagePaths)

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.featureSubmitted(record.presetName, matchedQuestUnit))
            }
        } catch {
            DatabaseConnector.shared.markFeatureDraftFailed(id: record.id, error: error.localizedDescription)
        }
    }

    private static func uploadPhotos(_ images: [UIImage]) async throws -> [String] {
        var urls: [String] = []

        for (index, image) in images.enumerated() {
            do {
                // KartaviewViewModel creates a CLLocationManager on init and immediately
                // calls requestWhenInUseAuthorization()/startUpdating*() — CoreLocation
                // requires those to happen on a thread with an active run loop (main),
                // or the app-level authorization handshake stalls. Only construction
                // needs the hop; the network upload itself is fine off the main thread.
                let viewModel = await MainActor.run { KartaviewViewModel(capturedImage: image) }
                let url = try await viewModel.uploadAsync()
                urls.append(url)
            } catch {
                throw NSError(
                    domain: "KartaviewUpload",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to upload photo \(index + 1) to Kartaview: \(error.localizedDescription)"]
                )
            }
        }

        return urls
    }
}

/// Serializes queue drains so a manual sync-button tap and an automatic
/// foreground/launch resume can never process the same pending feature twice at once.
/// A single pass snapshots the queue and attempts each item once — a feature that's
/// still failing (e.g. no connectivity) is left pending for the next trigger rather
/// than retried in a tight loop.
private actor FeatureQueueProcessor {
    static let shared = FeatureQueueProcessor()

    private var isProcessing = false

    func processPending() async {
        guard !isProcessing else { return }

        let pending = DatabaseConnector.shared.pendingFeatureDrafts()
        guard !pending.isEmpty else { return }

        isProcessing = true
        defer { isProcessing = false }

        await MainActor.run {
            MapViewPublisher.shared.dismissSheet.send(.featuresSyncing)
        }

        for record in pending {
            await FeatureSubmissionManager.attempt(record)
        }

        await MainActor.run {
            MapViewPublisher.shared.dismissSheet.send(.featuresSyncFinished)
        }
    }
}
