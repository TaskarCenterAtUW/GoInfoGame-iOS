//
//  LongFormImageView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 01/03/25.
//

import SwiftUI
import Foundation

struct LongFormImageView: View {
    let urlString: String
    let width: CGFloat
    let height: CGFloat
    let id: UUID? // Optional ID for tracking updates
    
    @State private var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .frame(width: width, height: height)
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
    
    private func loadImage() {
        guard let url = URL(string: urlString) else { return }

        if let cached = ImageCache.shared.image(forKey: urlString) {
            self.uiImage = cached
        } else {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let img = UIImage(data: data) else {
                    return
                }
                ImageCache.shared.set(image: img, forKey: urlString)
                DispatchQueue.main.async {
                    self.uiImage = img
                }
            }.resume()
        }
    }
}

class ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSString, UIImage>()

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
