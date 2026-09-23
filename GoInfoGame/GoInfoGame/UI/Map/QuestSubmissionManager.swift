//
//  QuestSubmissionManager.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation
import osmparser

/// Submits quest answers (and any attached KartaView photo) outside the lifetime of
/// LongForm, so Submit can return immediately whether or not there's connectivity.
/// Every answer is persisted (photo on disk, tags/element info in Realm, via the same
/// `StoredChangeset` row `QuestProtocols.updateTags` already wrote before this queue
/// existed) *before* any network call, so an answer submitted offline — or one whose
/// photo upload gets interrupted — survives an app kill and stays queued until it's
/// retried, either automatically (submit, app foreground/launch) or manually via the
/// sync button. Mirrors `FeatureSubmissionManager`/`NotesSubmissionManager`.
enum QuestSubmissionManager {

    /// Persists the changeset (and saves the photo to disk, if any), then drains the
    /// whole pending queue (not just this answer), so any earlier answers that failed
    /// get swept up too.
    static func submit(id: Int64, questType: String, tags: [String: String], type: ElementType,
                        iconName: String, capturedImage: UIImage?, imageTagKey: String?) {
        let storedElementType: StoredElementEnum = type == .way ? .way : .node

        Task.detached(priority: .userInitiated) {
            let pendingImagePath: String? = capturedImage.flatMap { try? QuestImageStorage.shared.save($0) }
            let pendingImageTagKey = pendingImagePath != nil ? imageTagKey : nil

            switch storedElementType {
            case .way:
                guard let way = DatabaseConnector.shared.getWay(id: Int(id)) else { return }
                DatabaseConnector.shared.createChangeset(
                    id: Int(id), questType: questType, type: storedElementType,
                    originalTags: way.tags.toDictionary(), tags: tags, version: way.version, iconName: iconName,
                    nodes: way.nodes, pendingImagePath: pendingImagePath, pendingImageTagKey: pendingImageTagKey
                )
            case .node:
                guard let node = DatabaseConnector.shared.getNode(id: Int(id)) else { return }
                DatabaseConnector.shared.createChangeset(
                    id: Int(id), questType: questType, type: storedElementType,
                    originalTags: node.tags.toDictionary(), tags: tags, version: node.version, iconName: iconName,
                    point: CLLocationCoordinate2D(latitude: node.latitude, longitude: node.longitude),
                    pendingImagePath: pendingImagePath, pendingImageTagKey: pendingImageTagKey
                )
            case .unknown:
                print("Unknown Stored element type received")
                return
            }

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.syncBackground(Int(id)))
            }

            await QuestQueueProcessor.shared.processPending()
        }
    }

    /// Resumes uploading/syncing whatever quest answers are still queued. Called on
    /// app foreground/launch, where nothing needs to observe completion.
    static func resumePendingUploads() {
        Task.detached(priority: .userInitiated) {
            await QuestQueueProcessor.shared.processPending()
        }
    }

    /// Same drain as `resumePendingUploads()`, awaitable — used by the manual sync
    /// button, which needs to know when the pass finished to refresh the map/badges.
    static func resumePendingUploadsAsync() async {
        await QuestQueueProcessor.shared.processPending()
    }

    /// A failed attempt is never fatal to the batch — the answer stays queued (already
    /// reflected in the sync badge) and is retried by the next trigger. A photo-upload
    /// failure specifically is also surfaced to the user via `.questPhotoUploadFailed`,
    /// since silently retrying a photo upload forever with no feedback is more likely
    /// to hide a real, recurring problem (bad token, corrupt image) than a generic tag
    /// sync retry would.
    fileprivate static func attempt(_ record: StoredChangesetSnapshot) async {
        do {
            var tags = record.tags

            if let path = record.pendingImagePath, let tagKey = record.pendingImageTagKey {
                guard let image = QuestImageStorage.shared.load(path: path) else {
                    DatabaseConnector.shared.markChangesetFailed(id: record.id, error: "Saved photo could not be read")
                    return
                }
                do {
                    let url = try await uploadPhoto(image)
                    tags[tagKey] = url
                    DatabaseConnector.shared.attachUploadedPhotoURL(id: record.id, tagKey: tagKey, url: url)
                    QuestImageStorage.shared.delete(paths: [path])
                } catch {
                    DatabaseConnector.shared.markChangesetFailed(id: record.id, error: error.localizedDescription)
                    await MainActor.run {
                        MapViewPublisher.shared.dismissSheet.send(
                            .questPhotoUploadFailed(elementName: record.questType, message: error.localizedDescription)
                        )
                    }
                    return // don't attempt tag sync without the photo URL; stays queued for retry
                }
            }

            let result: (result: Bool, version: Int)
            switch record.elementType {
            case .node:
                result = try await DatasyncManager.shared.syncNode(
                    node: record.asOSMNode(tags: tags), exclude_gig_tags: false, editedTags: tags,
                    elementTypeName: record.questType, iconName: record.iconName
                )
            case .way:
                result = try await DatasyncManager.shared.syncWay(
                    way: record.asOSMWay(tags: tags), exclude_gig_tags: false, editedTags: tags,
                    elementTypeName: record.questType, iconName: record.iconName
                )
            case .unknown:
                return
            }

            guard result.result else {
                DatabaseConnector.shared.markChangesetFailed(id: record.id, error: "Submission failed. Please try again.")
                return
            }

            DatabaseConnector.shared.assignChangesetId(obj: record.id, changesetId: 0, updatedVersion: result.version)

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.answerSynced(record.elementId))
            }
        } catch {
            DatabaseConnector.shared.markChangesetFailed(id: record.id, error: error.localizedDescription)
        }
    }

    private static func uploadPhoto(_ image: UIImage) async throws -> String {
        // KartaviewViewModel creates a CLLocationManager on init and immediately calls
        // requestWhenInUseAuthorization()/startUpdating*() — CoreLocation requires
        // those to happen on a thread with an active run loop (main), or the app-level
        // authorization handshake stalls. Only construction needs the hop; the network
        // upload itself is fine off the main thread. Mirrors FeatureSubmissionManager/
        // NotesSubmissionManager's identical uploadPhotos helper.
        let viewModel = await MainActor.run { KartaviewViewModel(capturedImage: image) }
        return try await viewModel.uploadAsync()
    }
}

/// Serializes queue drains so a manual sync-button tap and an automatic foreground/
/// launch resume can never process the same pending quest answer twice at once. A
/// single pass snapshots the queue and attempts each item once — an answer that's
/// still failing (e.g. no connectivity) is left pending for the next trigger rather
/// than retried in a tight loop. Mirrors `FeatureQueueProcessor`/`NotesQueueProcessor`.
///
/// Answering a quest for a multi-select batch fires `QuestSubmissionManager.submit`
/// once per selected element in a tight loop — each call's `Task.detached` persists
/// its own `StoredChangeset` and then calls `processPending()` independently, so
/// several calls can land here concurrently. Only one of them wins `isProcessing` and
/// actually drains; without `needsAnotherPass`, the rest would just return, and any
/// element whose Realm write hadn't landed yet when the winner took its snapshot
/// would be silently skipped from this drain — left pending until some unrelated
/// future trigger (foreground, sync button, next submit) happened to sweep it up.
/// `needsAnotherPass` instead makes the winner loop again before releasing the lock,
/// so every element from the same batch is picked up in this same triggering event.
private actor QuestQueueProcessor {
    static let shared = QuestQueueProcessor()

    private var isProcessing = false
    private var needsAnotherPass = false

    func processPending() async {
        guard !isProcessing else {
            needsAnotherPass = true
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        repeat {
            needsAnotherPass = false

            let pending = DatabaseConnector.shared.pendingChangesets()
            guard !pending.isEmpty else { break }

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.syncing)
            }

            for record in pending {
                await QuestSubmissionManager.attempt(record)
            }

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.synced)
            }
        } while needsAnotherPass
    }
}
