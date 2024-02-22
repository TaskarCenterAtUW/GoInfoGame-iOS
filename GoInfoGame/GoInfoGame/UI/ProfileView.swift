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

    var body: some View {
        return NavigationView {
            VStack {
                HStack {
                    profileImage
                    VStack (alignment: .leading){
                        Text(viewModel.user?.displayName ?? "")
                            .font(.system(size: 20, weight: .semibold))
                        HStack {
                            Image(systemName: "star.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("0")
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
                Divider()
                    .padding()
                Spacer()
            }
            .padding(20)
            .navigationBarItems(leading: backButton)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("My Profile")
        }
        
    }
    
    private var profileImage: some View {
        AsyncImage(url: URL(string: "https://picsum.photos/200/300")) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 150, height: 150, alignment: .center)
        .cornerRadius(75)
    }
    
    private var profileButton: some View {
        Button {
            // move to profile webpage
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
