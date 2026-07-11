//
//  NotesSubmissionManager.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation

/// Everything needed to (re)attempt a note submission, kept around so a failed
/// background submission can be handed back to CreateNoteView for a retry.
public struct NoteDraft {
    var noteText: String
    var images: [UIImage]
    var coordinates: CLLocationCoordinate2D
}

/// Submits notes (and their Kartaview photo uploads) outside the lifetime of
/// CreateNoteView, so the sheet can dismiss immediately after Submit is tapped.
/// Results are reported through MapViewPublisher.shared.dismissSheet, the same
/// channel quest submissions use for background sync notifications.
enum NotesSubmissionManager {
    static func submit(_ draft: NoteDraft) {
        Task.detached(priority: .userInitiated) {
            do {
                var finalNoteText = draft.noteText

                if !draft.images.isEmpty {
                    let photoURLs = try await uploadPhotos(draft.images)
                    finalNoteText += "\n\n" + photoURLs.joined(separator: "\n")
                }

                let result = try await NotesViewModel().createNote(
                    note: finalNoteText,
                    lat: draft.coordinates.latitude,
                    long: draft.coordinates.longitude
                )

                await MainActor.run {
                    if result {
                        MapViewPublisher.shared.dismissSheet.send(.noteSubmitted)
                    } else {
                        MapViewPublisher.shared.dismissSheet.send(.noteSubmissionFailed("Error submitting note", draft))
                    }
                }
            } catch {
                await MainActor.run {
                    MapViewPublisher.shared.dismissSheet.send(.noteSubmissionFailed("Error submitting note: \(error.localizedDescription)", draft))
                }
            }
        }
    }

    private static func uploadPhotos(_ images: [UIImage]) async throws -> [String] {
        var urls: [String] = []

        for (index, image) in images.enumerated() {
            do {
                let url = try await KartaviewViewModel(capturedImage: image).uploadAsync()
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
