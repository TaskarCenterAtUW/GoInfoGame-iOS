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
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        return NavigationView {
            VStack {
                HStack {
                    profileImage
                    VStack (alignment: .leading,spacing: 0){
                        Text(viewModel.user?.displayName ?? "")
                            .font(.system(size: 20, weight: .semibold))
                        HStack {
                            Image(systemName: "star.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("\(viewModel.user?.changesets.count ?? 0)")
                                .font(.title)
                        }
                    }
                    Spacer()
                }
                HStack {
                    profileButton
                    Spacer()
                    logOutButton
                }
                Divider().padding()
                Spacer()
            }
            .padding(20)
            .navigationBarItems(leading: backButton)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("My Profile")
        }
        
    }
    
    @ViewBuilder
    private var profileImage: some View {
        if self.viewModel.imageUrl == nil {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 120, height: 120, alignment: .center)
                .cornerRadius(60)
        }else {
            AsyncImage(url: self.viewModel.imageUrl) { phase in
                if let image = phase.image {
                    image.resizable()
                } else if phase.error != nil {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .frame(width: 120, height: 120, alignment: .center)
            .cornerRadius(60)
        }
    }
    
    private var profileButton: some View {
        Button {
            if let url = viewModel.profileUrl {
                openURL(url)
            }
        } label: {
            HStack {
                Image(systemName: "tray.and.arrow.up.fill")
                Text("OSM Profile")
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 180, height: 50)
            .background(.black)
            .cornerRadius(5)
        }
    }
    
    private var logOutButton: some View {
        Button {
            //LOGOUT
        } label: {
            Text("LOGOUT")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 50)
                .cornerRadius(15)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black)
                }
        }
    }
    
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.black)
                .cornerRadius(15)
        }
    }
}

#Preview {
    ProfileView()
}
