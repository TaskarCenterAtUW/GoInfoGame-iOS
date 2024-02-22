//
//  ProfileView.swift
//  GoInfoGame
//
//  Created by Sudula Murali Krishna on 2/21/24.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @ObservedObject private var viewModel = ProfileViewVM()
    
    var body: some View {
        return VStack {
            HStack {
                AsyncImage(url: URL(string: "https://picsum.photos/200/300")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 150, height: 150, alignment: .center)
                .cornerRadius(75)
                VStack {
                    Text(viewModel.user?.displayName ?? "testste")
                        .multilineTextAlignment(.leading)
                    HStack {
                        Image(systemName: "star.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                        Text("0")
                            .font(.title)
                        Spacer()
                    }
                    
                }
                Spacer()
            }
        Spacer()
        }
        .padding(20)
    }
}

#Preview {
    ProfileView()
}
