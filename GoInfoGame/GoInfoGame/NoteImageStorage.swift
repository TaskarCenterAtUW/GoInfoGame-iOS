//
//  NoteImageStorage.swift
//  GoInfoGame
//

import Foundation
import UIKit

/// Persists captured note photos to disk so they survive an app kill while a note is
/// still queued for upload. Realm isn't suited to storing image blobs, so only the
/// file path is kept in StoredNoteDraft.
final class NoteImageStorage {
    static let shared = NoteImageStorage()

    private let fileManager = FileManager.default
    private let directoryURL: URL

    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directoryURL = documents.appendingPathComponent("NoteImages", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    @discardableResult
    func save(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "NoteImageStorage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode photo"])
        }
        let fileURL = directoryURL.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    func load(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    func delete(paths: [String]) {
        for path in paths {
            try? fileManager.removeItem(atPath: path)
        }
    }
}
