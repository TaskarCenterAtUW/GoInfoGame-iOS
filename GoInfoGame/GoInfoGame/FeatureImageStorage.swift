//
//  FeatureImageStorage.swift
//  GoInfoGame
//

import Foundation
import UIKit

/// Persists captured feature photos to disk so they survive an app kill while a
/// feature is still queued for creation. Realm isn't suited to storing image blobs,
/// so only the file path is kept in StoredFeatureDraft. Mirrors NoteImageStorage,
/// kept as a separate instance/folder so the two queues can't interfere with each
/// other's files.
final class FeatureImageStorage {
    static let shared = FeatureImageStorage()

    private let fileManager = FileManager.default
    private let directoryURL: URL

    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directoryURL = documents.appendingPathComponent("FeatureImages", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    @discardableResult
    func save(_ image: UIImage) throws -> String {
        guard let data = image.uploadJPEGData() else {
            throw NSError(domain: "FeatureImageStorage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode photo"])
        }
        let fileURL = directoryURL.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    func load(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    /// The saved JPEG bytes, uploaded as-is — decoding to a `UIImage` and re-encoding
    /// would cost tens of MB of memory per photo for no benefit.
    func loadData(path: String) -> Data? {
        fileManager.contents(atPath: path)
    }

    func delete(paths: [String]) {
        for path in paths {
            try? fileManager.removeItem(atPath: path)
        }
    }
}
