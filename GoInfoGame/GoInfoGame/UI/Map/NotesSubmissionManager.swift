//
//  NotesSubmissionManager.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation

/// Everything needed to submit a note. `id` ties it to its persisted StoredNoteDraft
/// row so NotesSubmissionManager can upsert/delete the right queue entry.
public struct NoteDraft {
    public var id: String = UUID().uuidString
    var noteText: String
    var images: [UIImage]
    var coordinates: CLLocationCoordinate2D
}

/// Submits notes (and their Kartaview photo uploads) outside the lifetime of
/// CreateNoteView, so the sheet can dismiss immediately after Submit is tapped.
/// Every draft is persisted (text + photos on disk, metadata in Realm) *before* any
/// network call, so a note captured offline — or one whose upload gets interrupted —
/// survives an app kill and stays queued until it's retried, either automatically
/// (submit, app foreground/launch) or manually via the sync button.
/// Results are reported through MapViewPublisher.shared.dismissSheet, the same
/// channel quest submissions use for background sync notifications.
enum NotesSubmissionManager {

    /// Persists the draft, then drains the whole pending queue (not just this
    /// draft), so any earlier notes that failed get swept up too.
    static func submit(_ draft: NoteDraft) {
        Task.detached(priority: .userInitiated) {
            let previousPaths = DatabaseConnector.shared.noteDraftImagePaths(id: draft.id)
            if !previousPaths.isEmpty {
                NoteImageStorage.shared.delete(paths: previousPaths)
            }

            let imagePaths = draft.images.compactMap { try? NoteImageStorage.shared.save($0) }
            DatabaseConnector.shared.upsertNoteDraft(
                id: draft.id,
                noteText: draft.noteText,
                imagePaths: imagePaths,
                coordinates: draft.coordinates
            )

            await MainActor.run {
                MapViewPublisher.shared.dismissSheet.send(.notesQueueUpdated)
            }

            await NotesQueueProcessor.shared.processPending()
        }
    }

    /// Resumes uploading whatever notes are still queued. Called from the sync
    /// button and on app foreground/launch.
    static func resumePendingUploads() {
        Task.detached(priority: .userInitiated) {
            await NotesQueueProcessor.shared.processPending()
        }
    }

    /// A failed attempt is never surfaced to the user — the note stays queued
    /// (already reflected in the sync badge) and is retried by the next trigger.
    fileprivate static func attempt(_ record: StoredNoteDraftSnapshot) async {
        do {
            let images = record.imagePaths.compactMap { NoteImageStorage.shared.load(path: $0) }
            var finalNoteText = record.noteText

            if !images.isEmpty {
                let photoURLs = try await uploadPhotos(images)
                finalNoteText += "\n\n" + photoURLs.joined(separator: "\n")
            }

            let result = try await NotesViewModel().createNote(
                note: finalNoteText,
                lat: record.coordinates.latitude,
                long: record.coordinates.longitude
            )

            if result {
                DatabaseConnector.shared.deleteNoteDraft(id: record.id)
                NoteImageStorage.shared.delete(paths: record.imagePaths)
                await MainActor.run {
                    MapViewPublisher.shared.dismissSheet.send(.noteSubmitted)
                }
            } else {
                DatabaseConnector.shared.markNoteDraftFailed(id: record.id, error: "Error submitting note")
            }
        } catch {
            DatabaseConnector.shared.markNoteDraftFailed(id: record.id, error: error.localizedDescription)
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
/// foreground/launch resume can never process the same pending note twice at once.
/// A single pass snapshots the queue and attempts each item once — a note that's
/// still failing (e.g. no connectivity) is left pending for the next trigger rather
/// than retried in a tight loop.
private actor NotesQueueProcessor {
    static let shared = NotesQueueProcessor()

    private var isProcessing = false

    func processPending() async {
        guard !isProcessing else { return }

        let pending = DatabaseConnector.shared.pendingNoteDrafts()
        guard !pending.isEmpty else { return }

        isProcessing = true
        defer { isProcessing = false }

        await MainActor.run {
            MapViewPublisher.shared.dismissSheet.send(.notesSyncing)
        }

        for record in pending {
            await NotesSubmissionManager.attempt(record)
        }

        await MainActor.run {
            MapViewPublisher.shared.dismissSheet.send(.notesSyncFinished)
        }
    }
}
