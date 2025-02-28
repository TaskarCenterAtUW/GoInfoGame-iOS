//
//  LongFormImageView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 01/03/25.
//

import SwiftUI

struct LongFormImageView: View {
    let url: String
    let width: CGFloat
    let height: CGFloat
    let id: UUID? // Optional ID for tracking updates

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: width, height: height)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
            @unknown default:
                EmptyView()
            }
        }
        .id(id) // Helps SwiftUI track changes when needed
    }
}
