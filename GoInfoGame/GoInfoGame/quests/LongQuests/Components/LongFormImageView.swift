//
//  LongFormImageView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 01/03/25.
//

import SwiftUI
import Foundation
import ImageIO
import CryptoKit

struct LongFormImageView: View {
    let urlString: String
    let width: CGFloat
    let height: CGFloat
    
    @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false
    
    @State private var uiImage: UIImage?
    
    var label: String? = nil
    
    var body: some View {
        Group {
            ZStack(alignment: .bottom) {
                if lowBandwidthMode {
                    // Low bandwidth: show placeholder instead of downloading
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(width: width, height: height)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                        .accessibilityLabel(label ?? "Image hidden to save data")
                } else if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                } else {
                    ProgressView()
                        .frame(width: width, height: height)
                        .onAppear {
                            loadImage()
                        }
                }
                
                if let label = label {
                    let strokeOffsets: [(CGFloat, CGFloat)] = [
                        (-1, -1), (1, -1),
                        (-1, 1), (1, 1),
                        (0, -1), (0, 1),
                        (-1, 0), (1, 0)
                    ]
                    
                    ForEach(0..<strokeOffsets.count, id: \.self) { i in
                        let offset = strokeOffsets[i]
                        Text(label)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .offset(x: offset.0, y: offset.1)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel(label)
                    }
                    
                    Text(label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.7), radius: 4, x: 0, y: 2)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(label)
                    
                }
            }
            .frame(width: width, height: height)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label ?? "Image")
        }
        .frame(width: width, height: height)
        .clipped()
    }
    
    private func loadImage() {
        ImageCache.shared.loadImage(urlString: urlString) { image in
            self.uiImage = image
        }
    }
}

/// Loads remote images shown in the long form (answer choices, quest images, existing
/// photos) and Add Feature's custom icons. Each image is shrunk to the largest size it is
/// ever displayed at before being kept: forms link full-size originals (a single
/// Wikimedia photo decodes to ~47 MB) that are only shown as 100–300 pt thumbnails.
/// Small copies are kept in a size-capped memory cache and on disk, and concurrent
/// requests for the same URL share one download.
final class ImageCache {
    static let shared = ImageCache()

    /// Longest side, in pixels, an image is kept at: the largest display size
    /// (`LongFormImageView`'s expanded 300 pt) on a 3x screen.
    static let maxPixelSize: CGFloat = 900

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 40 * 1024 * 1024 // decoded bytes
        return cache
    }()
    private let diskDirectory: URL
    private let fileManager = FileManager.default
    private let lock = NSLock()
    private var inFlight: [String: [(UIImage?) -> Void]] = [:]
    private let workQueue = DispatchQueue(label: "ImageCache.work", qos: .userInitiated, attributes: .concurrent)

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDirectory = caches.appendingPathComponent("RemoteImages", isDirectory: true)
        try? fileManager.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: Self.decodedByteCount(of: image))
    }

    /// Drops the in-memory copies (the disk copies stay). Used by tests.
    func clearMemory() {
        cache.removeAllObjects()
    }

    /// Calls `completion` on the main queue with the (shrunk) image, or nil on failure.
    /// Checks memory, then disk, then downloads; a download already in flight for the
    /// same URL is joined rather than started again (rows re-appearing while scrolling).
    func loadImage(urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cached = image(forKey: urlString) {
            completion(cached)
            return
        }
        lock.lock()
        if inFlight[urlString] != nil {
            inFlight[urlString]?.append(completion)
            lock.unlock()
            return
        }
        inFlight[urlString] = [completion]
        lock.unlock()

        workQueue.async { [weak self] in
            guard let self else { return }
            if let data = self.fileManager.contents(atPath: self.diskPath(for: urlString)),
               let image = Self.downsample(data) {
                self.finish(urlString, image: image)
                return
            }
            guard let url = URL(string: urlString) else {
                self.finish(urlString, image: nil)
                return
            }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self else { return }
                let image = data.flatMap(Self.downsample)
                if let image, let encoded = Self.encodeForDisk(image) {
                    try? encoded.write(to: URL(fileURLWithPath: self.diskPath(for: urlString)), options: .atomic)
                }
                self.finish(urlString, image: image)
            }.resume()
        }
    }

    private func finish(_ urlString: String, image: UIImage?) {
        if let image { set(image: image, forKey: urlString) }
        lock.lock()
        let waiting = inFlight.removeValue(forKey: urlString) ?? []
        lock.unlock()
        DispatchQueue.main.async {
            waiting.forEach { $0(image) }
        }
    }

    private func diskPath(for urlString: String) -> String {
        let name = SHA256.hash(data: Data(urlString.utf8)).map { String(format: "%02x", $0) }.joined()
        return diskDirectory.appendingPathComponent(name).path
    }

    /// Decodes straight to a thumbnail no larger than `maxPixelSize`, without ever
    /// decoding the full-size image (ImageIO reads only what it needs).
    static func downsample(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// PNG when the image has transparency (icons), JPEG otherwise (photos).
    private static func encodeForDisk(_ image: UIImage) -> Data? {
        let alpha = image.cgImage?.alphaInfo ?? .none
        let hasAlpha = ![.none, .noneSkipFirst, .noneSkipLast].contains(alpha)
        return hasAlpha ? image.pngData() : image.jpegData(compressionQuality: 0.85)
    }

    private static func decodedByteCount(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

#Preview {
    LongFormImageView(urlString: "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/refs/heads/main/images/sidewalk/surface/asphalt_landscape.png", width: 100, height: 100, label: "Hello")
}
