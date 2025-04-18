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
    
    @State private var uiImage: UIImage?
    
    var label: String? = nil
    var isSelected: Bool = false
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                
                ZStack(alignment: .bottom) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                    
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
                          }

                          Text(label)
                              .font(.system(size: 15, weight: .bold))
                              .foregroundColor(.white)
                              .shadow(color: Color.black.opacity(0.7), radius: 4, x: 0, y: 2)
                            
                    }
                }
                .frame(width: width, height: height)

             
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
