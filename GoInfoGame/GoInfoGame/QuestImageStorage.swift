//
//  QuestImageStorage.swift
//  GoInfoGame
//

import Foundation
import UIKit

/// Persists captured quest-answer photos to disk so they survive an app kill while
/// still queued for upload. Realm isn't suited to storing image blobs, so only the
/// file path is kept on `StoredChangeset.pendingImagePath`. Mirrors
/// `FeatureImageStorage`/`NoteImageStorage`, kept as a separate instance/folder so
/// the three queues can't interfere with each other's files.
final class QuestImageStorage {
    static let shared = QuestImageStorage()

    private let fileManager = FileManager.default
    private let directoryURL: URL

    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directoryURL = documents.appendingPathComponent("QuestImages", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    @discardableResult
    func save(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "QuestImageStorage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode photo"])
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
